extends Node2D
class_name Island

# === Propriété de l'île ===
var island_owner: int = -1  # -1 = neutre
var island_id: int
var dock_orientation: float
var shore_tile_direction := Vector2i.ZERO
var alreay_spawn_boat = false

@export var boat_scene: PackedScene

@onready var castle_player: Sprite2D = $castle_player
@onready var castle_ai: Sprite2D = $castle_ai
@onready var dock: Node2D = $Dock
@onready var dock_area: Area2D = $Dock/Area2D
@onready var capture_bar: ProgressBar = $Dock/CaptureBar

# === Nodes de Groupement ===
@onready var sprite_node_cyan: Node2D = $Dock/Cyan
@onready var sprite_node_red: Node2D = $Dock/Red
@onready var upgrade_label: Label = $Dock/UpgradeLabel
@onready var heal_label: Label = $Dock/HealLabel


# On met à jour les références pour pointer vers les sprites à l'intérieur d'un des dossiers
# (On les ré-assignera dynamiquement dans _orient_dock)
var sprite_right: Sprite2D
var sprite_left: Sprite2D
var sprite_down: Sprite2D
var sprite_up: Sprite2D

# === Capture ===
const CAPTURE_TIME: float = 3.0
var capture_progress: float = 0.0
var boats_in_zone: Array = []
signal new_owner(int)
# === Références externes ===
var tilemap: TileMapLayer = null
var tile_terrain_map: Dictionary = {}  # Vector2i → 0 (terre) ou 1 (eau)

const SCAN_RADIUS: int = 60

# === Paramètres de la Forteresse ===
const CAPTURE_TIME_NORMAL: float = 3.0
const CAPTURE_TIME_FORTRESS: float = 8.0  # Plus long à capturer
var is_fortress: bool = false

# On remplace la constante CAPTURE_TIME par une variable dynamique
var current_capture_time: float = CAPTURE_TIME_NORMAL

# === Paramètres Économiques ===
const GOLD_GEN_NORMAL: int = 1    # Or par cycle
const GOLD_GEN_FORTRESS: int = 2 # Plus d'or pour une forteresse
const UPGRADE_COST: int = 20      # Coût de l'amélioration

var gold_timer: float = 0.0
const GOLD_TICK_TIME: float = 5.0 # Génère de l'or toutes les 5 secondes

# === Paramètres de Soin ===
const HEAL_COST: int = 5       # Coût en or
const HEAL_AMOUNT: int = 1     # PV rendus par pression de touche

func _ready() -> void:
	GameManager.register_island(self)
	
	# INITIALISATION CRITIQUE : On définit d'abord quel dossier utiliser
	# Cela va remplir les variables sprite_right, sprite_left, etc.
	_update_dock_appearance() 
	
	update_visual()
	dock_area.body_entered.connect(_on_dock_body_entered)
	dock_area.body_exited.connect(_on_dock_body_exited)
	
	# Maintenant on peut les cacher sans erreur
	_hide_all_dock_sprites()

# Appelé par world_map.gd après le spawn de l'île
func setup(tilemap_ref: TileMapLayer, terrain_map: Dictionary) -> void:
	tilemap = tilemap_ref
	tile_terrain_map = terrain_map
	_place_dock_on_shore()

# =============================================
# === Placement dynamique du quai ===
# =============================================
func _place_dock_on_shore() -> void:
	if tilemap == null:
		push_error("Island: tilemap non assignée, impossible de placer le quai.")
		return

	var island_tile: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var best_tile: Vector2i = Vector2i.ZERO
	var best_score: float = -1.0

	for radius in range(1, SCAN_RADIUS + 1):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if abs(dx) != radius and abs(dy) != radius:
					continue
				var tile: Vector2i = island_tile + Vector2i(dx, dy)
				if _is_shore_tile(tile):
					var dist: float = Vector2(dx, dy).length()
					var score: float = 1.0 / dist
					if score > best_score:
						best_score = score
						best_tile = tile
		if best_score > 0.0:
			break

	if best_score > 0.0:
		var world_pos: Vector2 = tilemap.to_global(tilemap.map_to_local(best_tile))
		# Décale le dock vers le bord de la tuile côté eau (demi-tuile = 8px)
		dock.global_position = world_pos
		_orient_dock(best_tile)
	else:
		push_warning("Island: aucun bord de tuile trouvé, le quai reste au centre.")

# Affiche uniquement le sprite correspondant à la direction de l'eau
func _orient_dock(shore_tile: Vector2i) -> void:
	_hide_all_dock_sprites()

	if tile_terrain_map.get(shore_tile + Vector2i(1, 0), 1) == 1:
		sprite_right.visible = true
		dock_orientation = 0
		shore_tile_direction =  Vector2i(1, 0)
	elif tile_terrain_map.get(shore_tile + Vector2i(-1, 0), 1) == 1:
		sprite_left.visible = true
		dock_orientation = 180
		shore_tile_direction =  Vector2i(-1, 0)
	elif tile_terrain_map.get(shore_tile + Vector2i(0, 1), 1) == 1:
		sprite_down.visible = true
		dock_orientation = 90
		shore_tile_direction =  Vector2i(0, 1)
	elif tile_terrain_map.get(shore_tile + Vector2i(0, -1), 1) == 1:
		sprite_up.visible = true
		dock_orientation = 270
		shore_tile_direction =  Vector2i(0, -1)
		
	# Ajoute ceci pour que la tour s'affiche sur le bon nouveau sprite si déjà amélioré
	_update_fortress_visual()
	
	if !alreay_spawn_boat:
		_spawn_boat()
	
func _spawn_boat() -> void :
	alreay_spawn_boat = true
	var boat = boat_scene.instantiate()
	if boat is Node2D:
		boat.set_as_player_and_id(island_id, self)
		get_parent().call_deferred("add_child", boat)

func _hide_all_dock_sprites() -> void:
	# Ajout d'une sécurité "if" pour éviter le crash si les sprites sont nuls
	if sprite_right: sprite_right.visible = false
	if sprite_left: sprite_left.visible = false
	if sprite_down: sprite_down.visible = false
	if sprite_up: sprite_up.visible = false

# =============================================
# === Détection de bord ===
# =============================================
func _is_shore_tile(tile: Vector2i) -> bool:
	if not tile_terrain_map.has(tile):
		return false
	
	# Selon WorldGen.cs : 1 est l'eau, 0 est l'île (terre)
	# On cherche si la tuile actuelle est de l'eau
	if tile_terrain_map[tile] != 1: 
		return false

	var neighbors: Array[Vector2i] = [
		tile + Vector2i(1, 0),
		tile + Vector2i(-1, 0),
		tile + Vector2i(0, 1),
		tile + Vector2i(0, -1),
	]
	
	for neighbor in neighbors:
		# Si un voisin est de la terre (0), on est sur un rivage !
		if tile_terrain_map.get(neighbor, 1) == 0:
			return true

	return false

# =============================================
# === Logique de capture ===
# =============================================
func _handle_capture(delta: float) -> void:
	var friendly_boats: Array = []
	var enemy_boats: Array = []

	for boat in boats_in_zone:
		if boat.player_id == island_owner:
			friendly_boats.append(boat)
		else:
			enemy_boats.append(boat)

	var attacker = _get_sole_attacker(enemy_boats, friendly_boats)

	if attacker != null:
		capture_progress += delta
		if capture_progress >= current_capture_time: # Utilise la variable
			capture_progress = current_capture_time
			change_owner(attacker.player_id, false)
			# Si l'île est capturée, elle perd son statut de forteresse
			reset_fortress()
	else:
		capture_progress = max(0.0, capture_progress - delta)

	_update_capture_bar()

func _get_sole_attacker(enemy_boats: Array, friendly_boats: Array):
	if enemy_boats.size() > 0 and friendly_boats.size() == 0:
		return enemy_boats[0]
	return null

func _update_capture_bar() -> void:
	if capture_bar and island_owner != 0: # N'affiche la barre que pour l'ennemi/neutre
		capture_bar.value = (capture_progress / current_capture_time) * 100.0

# =============================================
# === Signaux du quai ===
# =============================================
func _on_dock_body_entered(body: Node2D) -> void:
	if body is Boat and not boats_in_zone.has(body):
		boats_in_zone.append(body)

func _on_dock_body_exited(body: Node2D) -> void:
	boats_in_zone.erase(body)
	if boats_in_zone.size() == 0:
		capture_progress = 0.0

# =============================================
# === Changement de propriétaire ===
# =============================================
func change_owner(new_owner: int, is_needed_to_await_ready: bool) -> void:
	island_owner = new_owner
	capture_progress = 0.0
	
	if is_needed_to_await_ready:
		await ready
	update_visual()
	var team_color: Color
	print(new_owner)
	if new_owner == 0:
		team_color = Color.DARK_GREEN
		emit_signal("new_owner")
	elif new_owner == -1:
		team_color = Color.SLATE_GRAY
	else:
		team_color = Color.DARK_RED
	if not is_needed_to_await_ready:
		_update_minimap_color(team_color)
	
	_update_dock_appearance()
	GameManager.check_victory(new_owner)

func _update_minimap_color(color: Color) -> void:
	var uis = get_tree().get_nodes_in_group("minimap_ui")
	if not uis.is_empty():
		uis[0].change_island_color(island_id, color)

func update_visual() -> void:
	if island_owner == 0:
		castle_player.visible = true
		castle_ai.visible = false
	else:
		castle_player.visible = false
		castle_ai.visible = true
		
func _get_water_direction(shore_tile: Vector2i) -> Vector2:
	if tile_terrain_map.get(shore_tile + Vector2i(1, 0), 1) == 1:
		return Vector2.RIGHT
	elif tile_terrain_map.get(shore_tile + Vector2i(-1, 0), 1) == 1:
		return Vector2.LEFT
	elif tile_terrain_map.get(shore_tile + Vector2i(0, 1), 1) == 1:
		return Vector2.DOWN
	elif tile_terrain_map.get(shore_tile + Vector2i(0, -1), 1) == 1:
		return Vector2.UP
	return Vector2.ZERO
	
func _process(delta: float) -> void:
	_handle_capture(delta)
	_handle_upgrade_input()
	_handle_heal_input()
	_generate_passive_gold(delta)

func _handle_upgrade_input() -> void:
	if Input.is_action_just_pressed("upgrade"):
		if not is_fortress and island_owner == 0:
			# On vérifie si le joueur a assez d'argent
			if GameManager.player_gold >= UPGRADE_COST:
				for boat in boats_in_zone:
					if is_instance_valid(boat) and boat.player_id == 0:
						GameManager.player_gold -= UPGRADE_COST
						upgrade_to_fortress()
						return
			else:
				print("Pas assez d'or ! (Requis: ", UPGRADE_COST, ")")

func upgrade_to_fortress() -> void:
	is_fortress = true
	current_capture_time = CAPTURE_TIME_FORTRESS
	upgrade_label.visible = false
	_update_fortress_visual()

func reset_fortress() -> void:
	is_fortress = false
	current_capture_time = CAPTURE_TIME_NORMAL
	_hide_all_towers() # Cache toutes les tours
	
func _hide_all_towers() -> void:
	sprite_right.get_node("SpriteTower").visible = false
	sprite_left.get_node("SpriteTower").visible = false
	sprite_down.get_node("SpriteTower").visible = false
	sprite_up.get_node("SpriteTower").visible = false

func _update_fortress_visual() -> void:
	_hide_all_towers()
	if not is_fortress: return
	
	# On cherche la tour dans le sprite actuellement visible
	if sprite_right.visible: sprite_right.get_node("SpriteTower").visible = true
	elif sprite_left.visible: sprite_left.get_node("SpriteTower").visible = true
	elif sprite_down.visible: sprite_down.get_node("SpriteTower").visible = true
	elif sprite_up.visible: sprite_up.get_node("SpriteTower").visible = true
	
func _update_dock_appearance() -> void:
	# 1. Sélection du dossier de sprites 
	var active_node: Node2D = sprite_node_cyan if island_owner == 0 else sprite_node_red
	var inactive_node: Node2D = sprite_node_red if island_owner == 0 else sprite_node_cyan
	
	active_node.visible = true
	inactive_node.visible = false
	
	# 2. Mise à jour des références (Assignation avant toute utilisation) 
	sprite_right = active_node.get_node("SpriteRight")
	sprite_left = active_node.get_node("SpriteLeft")
	sprite_down = active_node.get_node("SpriteDown")
	sprite_up = active_node.get_node("SpriteUp")
	
	# 3. Gestion de l'UI 
	if island_owner == 0:
		if capture_bar: capture_bar.visible = false
		if upgrade_label:
			upgrade_label.visible = !is_fortress
			upgrade_label.text = "[U] Upgrade (" + str(UPGRADE_COST) + " gold)"
		if heal_label:
			heal_label.visible = !is_fortress
			heal_label.text = "[H] Heal (" + str(HEAL_COST) + " gold)"
	else:
		if capture_bar: capture_bar.visible = true
		if upgrade_label: upgrade_label.visible = false
		if heal_label: heal_label.visible = false
	
	# 4. On replace le dock (ce qui appellera _orient_dock)
	if tilemap != null:
		_place_dock_on_shore()

func _generate_passive_gold(delta: float) -> void:
	# Seules les îles du joueur (ID 0) génèrent de l'or pour lui
	if island_owner == 0:
		gold_timer += delta
		if gold_timer >= GOLD_TICK_TIME:
			gold_timer = 0.0
			var amount = GOLD_GEN_FORTRESS if is_fortress else GOLD_GEN_NORMAL
			GameManager.player_gold += amount
			print("Or généré : +", amount, " (Total: ", GameManager.player_gold, ")")
			
func _handle_heal_input() -> void:
	# Vérifie si le joueur appuie sur 'H'
	if Input.is_action_just_pressed("heal"): # Assure-toi de créer l'action "heal" pour la touche H
		# Le soin n'est possible que si c'est une forteresse possédée par le joueur
		if island_owner == 0:
			if GameManager.player_gold >= HEAL_COST:
				for boat in boats_in_zone:
					if is_instance_valid(boat) and boat.player_id == 0:
						# On vérifie si le bateau a besoin de soin
						if boat.life < boat.original_life:
							GameManager.player_gold -= HEAL_COST
							boat.repair(HEAL_AMOUNT)
							print("Bateau soigné ! Or restant : ", GameManager.player_gold)
							return
						else:
							print("Vie déjà au maximum.")
			else:
				print("Pas assez d'or pour soigner (Requis : 5).")
