extends RigidBody3D

@export var value: int = 0
@export var icon_texture: Texture2D
@export var icon_type: String = ""

var label_assigned := false

func set_target_position(pos: Vector3):
	var dir = pos - global_position
	dir.y = 0
	var impulse = dir.normalized() * 5.0
	apply_impulse(Vector3.ZERO, impulse)

func _ready():
	pass
	#update_label()
	#update_icon()

func throw_to(target_pos: Vector3):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_pos, 0.4)
	tween.parallel().tween_property(self, "rotation_degrees:x", 0.0, 0.4)
	tween.parallel().tween_callback(_show_front).set_delay(0.2)
	
func _show_front():
	# change material/texture so the front is visible
	update_label()
	update_icon()

func update_label():
	if has_node("ValueLabel"):
		var label = $ValueLabel
		if label:
			label.text = str(value)
			label_assigned = true
			
func update_icon():
	if has_node("IconSprite"):
		var sprite = $IconSprite
		if sprite:
			sprite.texture = icon_texture
