extends Area2D

@onready var world: Area2D = $"../World"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_pos()

func reset_pos() :
	if (world) :
		var worldpos = world.global_position
		# Calculate random X and Y within the shape's rectangle
		var x = worldpos.x + randf_range( -700, 700)
		var y = worldpos.y + randf_range( -400, 400 )
		# Convert local area point to global position
		global_position.x = x
		global_position.y = y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
