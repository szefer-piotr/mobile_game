extends Node3D

@export var value: int = 0
@export var target_position: Vector3

func _ready():
	set_process(true)
	print("Card ready. Value:", value, " Start pos:", global_position, " Target:", target_position)

func _process(delta):
	global_position = global_position.lerp(target_position, delta * 5.0)
