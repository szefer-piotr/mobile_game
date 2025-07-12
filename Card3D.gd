extends Node3D

@export var value: int = 0
@export var target_position: Vector3

var label_assigned := false

func set_target_position(pos: Vector3):
	target_position = pos
	if is_inside_tree():
		animate_to_position()
	else:
		await ready
		animate_to_position()

func animate_to_position():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", target_position, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

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
