extends CharacterBody2D

class_name Boat
var speed :float = 300.0
var rotation_speed = 2.5
var acceleration = 100
var friction = 0.99

var life = 20
var atk :int = 5
var player_id : int = -1

@export var is_player:bool
@export var projectile_scene: PackedScene


# INPUTS (pilotés par controller)
var throttle := 0.0   # -1 → 1
var steering := 0.0   # -1 → 1
var want_to_shoot := false
var controller = null
		
func _ready():
	if is_player:
		set_as_player(true)
	GameManager.register_boat(self)
		
func set_as_player(is_player: bool) -> void:
	if is_player:
		player_id=0
		controller=PlayerController.new()
		controller.boat = self
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
