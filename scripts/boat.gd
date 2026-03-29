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
var time_since_last_fire = 0
@export var camera_scene: PackedScene
signal getDamage(int)


# INPUTS (pilotés par controller)
var throttle := 0.0   # -1 → 1
var steering := 0.0   # -1 → 1
var want_to_shoot := false
var controller = null

var dont_die_on_life_equal_0:bool = false
var useRayCastController:bool = true

func _ready():
	GameManager.register_boat(self)
	original_life = life

func set_as_player_and_id(id_player: int) -> void:
	player_id = id_player
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
		
func setAITrainingController(id_player: int, new_controller):
	player_id = id_player
	controller = new_controller
	add_child(controller)
	
func _physics_process(delta: float) -> void:
	if controller:
		controller.update(delta)
	
	### Tir
	time_since_last_fire += delta
	if want_to_shoot:
		attack()
		want_to_shoot = false
	
	### Deplacement
	var forward_dir = global_transform.x # L'avant du bateau (équivalent à Vector2.RIGHT.rotated(rotation))
	
	if throttle != 0:
		var force = forward_dir * throttle * acceleration
		if throttle < 0 and linear_velocity.dot(forward_dir) < 0:
			force /= 4
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
	label.text = "linear_velocity = " + str(linear_velocity) + "\n"
	label.text += "angular_velocity = " + str(angular_velocity)

func _integrate_forces(state):
	if(tpRandomNextFrame):
		var target_pos = Vector2(randi_range(-500, 500), randi_range(-500, 500))
		state.transform.origin = get_parent().to_global(target_pos)
		tpRandomNextFrame = false



func attack() -> void :
	
	
	if time_since_last_fire < fire_cool_down :
		return 
	time_since_last_fire = 0
	var projectile = projectile_scene.instantiate()

	var direction = Vector2.RIGHT.rotated(rotation)
	projectile.position = position + direction * 50
	
	projectile.direction = direction
	projectile.degats = atk
	projectile.tireur = self
	
	get_parent().add_child(projectile)
	
func get_damage(damage: float, tireur) -> void :
	
	life -= damage
	if player_id == 0:
		emit_signal("getDamage", life)
	on_health_changed.emit(life)
	var bot_atk := tireur as Boat
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



	
