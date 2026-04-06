extends Area2D

var vitesse = 1000
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
	if body == tireur:
		return
	if body.has_method("get_damage"):
		body.get_damage(degats, tireur)
	queue_free()
