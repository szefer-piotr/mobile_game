extends Node3D

@export var value: int = 0
@export var target_position: Vector3

func _ready():
	# Optional: show number with Label3D if needed
	pass

func _process(delta):
	global_position = global_position.lerp(target_position, delta * 5.0)
