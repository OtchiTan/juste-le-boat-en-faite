extends RigidBody2D

class_name Boat

@export var label: Label

var max_speed = 250.0
var current_velocity = Vector2.ZERO
var friction = 0.995
var lateral_friction = 0.975
var max_rotation_speed = 200
var rotation_friction = 0.95
var current_rotation_speed = 0

var acceleration = 100

var min_rotation_speed = 0.05
var rotation_acceleration = 2000


var life = 20
var atk :int = 5
var player_id : int = -1

var target : Boat = null
var targ : Vector2

@export var projectile_scene: PackedScene
@export var camera_scene: PackedScene


# INPUTS (pilotés par controller)
var throttle := 0.0   # -1 → 1
var steering := 0.0   # -1 → 1
var want_to_shoot := false
var controller = null
		
func _ready():
	GameManager.register_boat(self)
		
func set_as_player_and_id(id_player: int) -> void:
	player_id= id_player
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
	
	var transfere_v = (side_v - new_side_vel).length() * 0.4 # suppr le 0.4 et met 2 si t'es un zhomme
	var transfere_vel = transfere_v * side_dir.orthogonal()
	
	linear_velocity = new_forward_vel + new_side_vel + transfere_vel
	
	
	### DEBUG
	label.text = "Debug Print"
	
	
	
	
	#var direction = Vector2.RIGHT.rotated(rotation)
	#
	## Applique les input
	#if(throttle != 0):
		#if(throttle < 0 and current_velocity.normalized().dot(direction.normalized()) < 0):
			#current_velocity += direction * throttle * acceleration * delta / 4
		#else :
			#current_velocity += direction * throttle * acceleration * delta
	#
	#if(steering != 0):
		#current_rotation_speed += steering * delta 														\
									#* (rotation_acceleration * current_velocity.length() / max_speed) 	\
									#* current_velocity.normalized().dot(direction.normalized()) 
	#
	## Limiter les vitesses max
	#if current_velocity.length() > max_speed:
		#current_velocity = current_velocity.normalized() * max_speed
		#
	#if(current_rotation_speed > max_rotation_speed):
		#current_rotation_speed = max_rotation_speed
		#
	#if(current_rotation_speed < -max_rotation_speed):
		#current_rotation_speed = -max_rotation_speed
	#
	#
	## Applique la rotation
	#
	#if(abs(current_rotation_speed) > min_rotation_speed):
		#rotation += current_rotation_speed * delta
	#
	## Friction
	#var forward_v = current_velocity.dot(direction)
	#var side_v = current_velocity.dot(direction.orthogonal())
	#
	#var new_forward_vel = direction * forward_v * friction
	#var new_side_vel = direction.orthogonal() * side_v * lateral_friction
	#
	#current_velocity = new_forward_vel + new_side_vel
	#
	#current_rotation_speed *= rotation_friction
	
	### DEBUG
	#if (current_velocity.length() != 0):
		#print_debug(current_velocity.length())

	#velocity = current_velocity
	#move_and_slide()


func attack() -> void :
	var projectile = projectile_scene.instantiate()

	var direction = Vector2.RIGHT.rotated(rotation)
	projectile.position = position + direction * 50
	
	projectile.direction = direction
	projectile.degats = atk
	projectile.tireur = self
	
	get_parent().add_child(projectile)
	
func get_damage(damage: float, tireur) -> void :
	life -= damage
	if life <= 0:
		GameManager.on_boat_destroyed(self, tireur)
		queue_free()

func set_target(targ_boat : Boat) -> void :
	target = targ_boat
