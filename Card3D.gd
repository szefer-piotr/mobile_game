extends Node3D

@export var value: int = 0
@export var target_position: Vector3 = Vector3()

var label_assigned := false

func _ready():
	set_process(true)
	update_label()

func _process(delta):
	global_position = global_position.lerp(target_position, delta * 5.0)
	if not label_assigned:
		update_label()

func update_label():
	if has_node("ValueLabel"):
		var label = $ValueLabel
		if label:
			label.text = str(value)
			label_assigned = true
