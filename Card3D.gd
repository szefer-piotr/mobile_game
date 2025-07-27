extends RigidBody3D

@export var value: int = 0

var label_assigned := false

func set_target_position(pos: Vector3):
	var dir = pos - global_position
	dir.y = 0
	var impulse = dir * 2.0
	apply_impulse(Vector3.ZERO, impulse)

func _ready():
	update_label()

func update_label():
	if has_node("ValueLabel"):
		var label = $ValueLabel
		if label:
			label.text = str(value)
			label_assigned = true
