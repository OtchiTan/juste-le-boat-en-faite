extends Area2D

@export var explosion_scene: PackedScene

var vitesse = 500
var direction = Vector2.ZERO
var degats : int = 20
var tireur
var duree_vie :float = 1

func _ready() -> void:
	await get_tree().create_timer(duree_vie).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * vitesse * delta
	
func _on_body_entered(body):
	_handle_impact(body)

func _on_area_entered(area):
	_handle_impact(area)

func _handle_impact(hit_node):
	if hit_node == tireur:
		return
		
	if hit_node.has_method("get_damage"):
		hit_node.get_damage(degats, tireur)
		
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
		
	queue_free()
