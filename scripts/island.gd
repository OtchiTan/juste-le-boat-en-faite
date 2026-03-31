extends Node2D

# === Propriété de l'île ===
var island_owner: int = -1  # -1 = neutre
var island_id: int

@onready var castle_player: Sprite2D = $castle_player
@onready var castle_ai: Sprite2D = $castle_ai
@onready var dock: Node2D = $Dock
@onready var dock_area: Area2D = $Dock/Area2D
@onready var sprite_right: Sprite2D = $Dock/SpriteRight
@onready var sprite_left: Sprite2D = $Dock/SpriteLeft
@onready var sprite_down: Sprite2D = $Dock/SpriteDown
@onready var sprite_up: Sprite2D = $Dock/SpriteUp
@onready var capture_bar: ProgressBar = $Dock/CaptureBar  # Supprime si pas de ProgressBar

# === Capture ===
const CAPTURE_TIME: float = 3.0
var capture_progress: float = 0.0
var boats_in_zone: Array = []

# === Références externes ===
var tilemap: TileMapLayer = null
var tile_terrain_map: Dictionary = {}  # Vector2i → 0 (terre) ou 1 (eau)

const SCAN_RADIUS: int = 60

func _ready() -> void:
	GameManager.register_island(self)
	update_visual()
	dock_area.body_entered.connect(_on_dock_body_entered)
	dock_area.body_exited.connect(_on_dock_body_exited)
	# Cache tous les sprites par défaut
	_hide_all_dock_sprites()

# Appelé par world_map.gd après le spawn de l'île
func setup(tilemap_ref: TileMapLayer, terrain_map: Dictionary) -> void:
	tilemap = tilemap_ref
	tile_terrain_map = terrain_map
	_place_dock_on_shore()

func _process(delta: float) -> void:
	_handle_capture(delta)

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
		var water_dir: Vector2 = _get_water_direction(best_tile)
		dock.global_position = world_pos - water_dir * 150.0
		_orient_dock(best_tile)
	else:
		push_warning("Island: aucun bord de tuile trouvé, le quai reste au centre.")

# Affiche uniquement le sprite correspondant à la direction de l'eau
func _orient_dock(shore_tile: Vector2i) -> void:
	_hide_all_dock_sprites()

	if tile_terrain_map.get(shore_tile + Vector2i(1, 0), 1) == 1:
		sprite_right.visible = true
	elif tile_terrain_map.get(shore_tile + Vector2i(-1, 0), 1) == 1:
		sprite_left.visible = true
	elif tile_terrain_map.get(shore_tile + Vector2i(0, 1), 1) == 1:
		sprite_down.visible = true
	elif tile_terrain_map.get(shore_tile + Vector2i(0, -1), 1) == 1:
		sprite_up.visible = true

func _hide_all_dock_sprites() -> void:
	sprite_right.visible = false
	sprite_left.visible = false
	sprite_down.visible = false
	sprite_up.visible = false

# =============================================
# === Détection de bord ===
# =============================================
func _is_shore_tile(tile: Vector2i) -> bool:
	if not tile_terrain_map.has(tile):
		return false
	if tile_terrain_map[tile] != 1:
		return false

	var neighbors: Array[Vector2i] = [
		tile + Vector2i(1, 0),
		tile + Vector2i(-1, 0),
		tile + Vector2i(0, 1),
		tile + Vector2i(0, -1),
	]
	for neighbor in neighbors:
		if tile_terrain_map.get(neighbor, 1) == 2:
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
		if capture_progress >= CAPTURE_TIME:
			capture_progress = CAPTURE_TIME
			change_owner(attacker.player_id, false)
	else:
		capture_progress = max(0.0, capture_progress - delta)

	_update_capture_bar()

func _get_sole_attacker(enemy_boats: Array, friendly_boats: Array):
	if enemy_boats.size() > 0 and friendly_boats.size() == 0:
		return enemy_boats[0]
	return null

func _update_capture_bar() -> void:
	if capture_bar:
		capture_bar.value = (capture_progress / CAPTURE_TIME) * 100.0

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
	boats_in_zone.clear()
	if is_needed_to_await_ready:
		await ready
	update_visual()
	var team_color: Color
	print(new_owner)
	if new_owner == 0:
		team_color = Color.DARK_GREEN
	else:
		team_color = Color.DARK_RED
	if not is_needed_to_await_ready:
		_update_minimap_color(team_color)

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
