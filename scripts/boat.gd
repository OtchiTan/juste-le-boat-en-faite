extends RigidBody2D

class_name Boat

@export var label: Label

var friction = 0.995
var lateral_friction = 0.975
var acceleration = 80
var rotation_acceleration = 2000
var front_redistribute_power = 0.3 # suppr le 0.3 et met 2 si t'es un zhomme qui aime le drift !

#used by the AI controller for rewards (and important stuff I guess)
signal on_health_changed(new_health: float)
signal on_dealt_damages(dmg_amount:float, dmg_boat:Boat)
@export var life = 20
var original_life:int
var atk :int = 5
var player_id : int = -1

var target : Boat = null
var targ : Vector2
var tpRandomNextFrame = false

@export var projectile_scene: PackedScene
@export var fire_cool_down : int = 1
var time_since_last_fire_left = 0
var time_since_last_fire_right = 0
@export var camera_scene: PackedScene
signal getDamage(int)

#@onready var boat_sprite_2d: Sprite2D = $BoatSprite2D
@onready var boat_cyan: AnimatedSprite2D = $CyanBoat
@onready var boat_red: AnimatedSprite2D = $RedBoat

# INPUTS (pilotés par controller)
var throttle := 0.0   # -1 → 1
var steering := 0.0   # -1 → 1
var want_to_shoot_r := false
var want_to_shoot_l := false
var controller = null

var dont_die_on_life_equal_0:bool = false
var useRayCastController:bool = true

@onready var minimap_marker: MinimapMarker = $MinimapMarker
@onready var collision: CollisionShape2D = $CollisionShape2D

var wind_angle = 0
#if the angle is between windangle +/- wind_acceptance_angle take the wind, else not. 
var wind_acceptance_angle = 30 * PI / 180
var wind_strenght = 50

func _ready():
	GameManager.register_boat(self)
	original_life = life
	var shape_resource = collision.shape
	minimap_marker.marker_size = Vector2(shape_resource.height, shape_resource.radius * 2)
	minimap_marker.is_rect = true
	if player_id == 0:
		minimap_marker.marker_color = Color.GREEN
	else :
		minimap_marker.marker_color = Color.CRIMSON

func set_as_player_and_id(id_player: int) -> void:
	player_id = id_player
	label.text = str(player_id)
	
	if id_player == 0:
		controller=PlayerController.new()
		controller.boat = self
		if camera_scene:
			var camera_instance = camera_scene.instantiate()
			# Sécurité : On vérifie que c'est bien une Camera2D
			if camera_instance is Camera2D:
				# On s'assure qu'elle est active
				camera_instance.enabled = true 
				# On l'attache au bateau
				add_child(camera_instance)
				print("Caméra configurée attachée au bateau du joueur : ", player_id)
			else:
				print("Erreur: camera_scene n'est pas une Camera2D !")
				camera_instance.queue_free() # On nettoie si c'est le mauvais type
		else:
			print("Avertissement: camera_scene n'est pas assignée pour le joueur ", player_id)
		await _ready()
		boat_cyan.visible = true
		boat_red.visible = false
		print("Bateau initialisé pour le joueur : ", player_id)
	else:
		if (useRayCastController) :
			controller = AIControllerWithRaycast.new()
			controller.boat = self
			controller.raycast_sensor_2d = $RaycastSensor2D_extended
			add_child(controller)
		else :
			controller = AIControllerBoat.new()
			controller.boat = self
			add_child(controller)
		await _ready()
		boat_cyan.visible = false
		boat_red.visible = true

func setAITrainingController(id_player: int, new_controller):
	player_id = id_player
	controller = new_controller
	add_child(controller)

func _physics_process(delta: float) -> void:
	if controller:
		controller.update(delta)
	
	### Tir
	time_since_last_fire_left += delta
	time_since_last_fire_right += delta
	
	
	if want_to_shoot_l or want_to_shoot_r:
		attack()
		want_to_shoot_l = false
		want_to_shoot_r = false
	
	### Deplacement
	var forward_dir = global_transform.x # L'avant du bateau (équivalent à Vector2.RIGHT.rotated(rotation))
	
	if throttle != 0:
		var force  = forward_dir * throttle * acceleration 
		var relative_wind_angle = fmod(abs(forward_dir.angle() - wind_angle),  PI)
		#print(forward_dir.angle()," / ",wind_angle," : ",  relative_wind_angle, relative_wind_angle < wind_acceptance_angle)
		if throttle < 0 and linear_velocity.dot(forward_dir) < 0:
			force /= 4
		elif ( relative_wind_angle < wind_acceptance_angle) :
			force += force.normalized()* wind_strenght
		apply_central_force(force)
	
	### rotation
	if steering != 0:
		var speed_ratio = linear_velocity.length() / 250 
		var dot_direction = linear_velocity.normalized().dot(forward_dir)
		var torque = steering * rotation_acceleration * speed_ratio * dot_direction
		apply_torque(torque)
	
	### Friction
	var side_dir = global_transform.y
	var forward_v = side_dir.orthogonal() * linear_velocity.dot(side_dir.orthogonal())
	var side_v = side_dir * linear_velocity.dot(side_dir)

	var new_forward_vel = forward_v * friction
	var new_side_vel = side_v * lateral_friction
	
	var transfere_v = (side_v - new_side_vel).length() * front_redistribute_power
	var transfere_vel = transfere_v * side_dir.orthogonal()
	
	linear_velocity = new_forward_vel + new_side_vel + transfere_vel
	
	### DEBUG
	#label.text = "linear_velocity = " + str(linear_velocity) + "\n"
	#label.text += "angular_velocity = " + str(angular_velocity)


@export var spawn_rectancgle:Vector4 = Vector4(-500,500,-500,500)

func _integrate_forces(state):
	if(tpRandomNextFrame):
		var target_pos = Vector2(randi_range(spawn_rectancgle.x, spawn_rectancgle.y), randi_range(spawn_rectancgle.z, spawn_rectancgle.w))
		state.transform.origin = get_parent().to_global(target_pos)
		tpRandomNextFrame = false



func attack() -> void :
	

	
	var nb_Bullet = 1
	var dispertion_Angle = 0
	
	var angle_btw = 0
	if nb_Bullet > 1:
		angle_btw = dispertion_Angle/(nb_Bullet-1)
	
	if ( want_to_shoot_l and time_since_last_fire_left >= fire_cool_down ) :
		time_since_last_fire_left = 0
		var direction = global_transform.y.rotated(-dispertion_Angle/2)
		for fire_angle:int in nb_Bullet:
			var projectile1 = projectile_scene.instantiate()
			projectile1.position = position + direction * 50
			projectile1.direction = (direction + linear_velocity *0.5 / projectile1.vitesse)
			projectile1.degats = atk
			projectile1.tireur = self
			get_parent().add_child(projectile1)
			direction = direction.rotated(angle_btw)
	if (want_to_shoot_r and time_since_last_fire_right >= fire_cool_down) :
		time_since_last_fire_right = 0
		var direction = global_transform.y.rotated(-dispertion_Angle/2)
		for fire_angle:int in nb_Bullet:
			direction = direction.rotated(PI)
			var projectile1 = projectile_scene.instantiate()
			projectile1.position = position + direction * 50
			projectile1.direction = (direction  + linear_velocity * 0.5 / projectile1.vitesse)
			projectile1.degats = atk
			projectile1.tireur = self
			get_parent().add_child(projectile1)
			direction = direction.rotated(angle_btw)


func get_damage(damage: float, tireur) -> void :
	
	life -= damage
	if player_id == 0:
		emit_signal("getDamage", life)
	on_health_changed.emit(life)
	
	var bot_atk := tireur as Boat if tireur else null
	if (bot_atk) :
		bot_atk.on_dealt_damages.emit(damage, self)
		
	if life <= 0:
		if not dont_die_on_life_equal_0 : 
			GameManager.on_boat_destroyed(self, tireur)
			queue_free()

func set_target(targ_boat : Boat) -> void :
	target = targ_boat
	
func reset() :
	tpRandomNextFrame = true
	life = original_life
	
func repair(amount: int) -> void:
	life = min(original_life, life + amount)
	# On émet le signal pour que le HUD se mette à jour immédiatement
	if player_id == 0:
		emit_signal("getDamage", life) # On réutilise ce signal pour rafraîchir l'affichage
	on_health_changed.emit(life)
