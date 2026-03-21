extends CharacterBody2D

class_name Boat
var speed :float = 500.0
var rotation_speed = 2.5
var acceleration = 100
var friction = 0.99

var life = 20
var atk :int = 5
var player_id : int = -1

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
		pass # si c'est une AI
		
		
func _physics_process(delta: float) -> void:
	if controller:
		controller.update(delta)
	
	# Tir
	if want_to_shoot:
		attack()
		want_to_shoot = false
	#deplacement
	rotation += steering  * rotation_speed * delta
	var direction = Vector2.RIGHT.rotated(rotation)
	velocity += direction * throttle * acceleration * delta

	# 4. Limiter la vitesse max
	if velocity.length() > speed:
		velocity = velocity.normalized() * speed

	# 5. Friction (effet eau)
	velocity *= friction

	move_and_slide()


func attack() -> void :
	var projectile = projectile_scene.instantiate()

	var direction = Vector2.RIGHT.rotated(rotation)
	projectile.position = position + direction * 50
	
	projectile.direction = direction
	projectile.degats = atk
	projectile.tireur = self  
	get_parent().add_child(projectile)
	
func get_damage(damage: float, tireur) -> void :
	life-= damage
	if life <= 0:
		GameManager.on_boat_destroyed(self, tireur)
		queue_free()
