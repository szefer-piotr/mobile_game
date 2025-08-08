extends RigidBody3D

@export var value: int = 0
@export var icon_texture: Texture2D
@export var icon_type: String = ""

var label_assigned := false
var front_shown := false
var landed := false
var slide_damp := 0.1


func set_target_position(pos: Vector3):
	var dir = pos - global_position
	dir.y = 0
	var impulse = dir.normalized() * 5.0
	apply_impulse(Vector3.ZERO, impulse)


func _ready():
	var mat := PhysicsMaterial.new()
	mat.friction = 0.1
	physics_material_override = mat
	linear_damp = 0.5
	
	
func throw_to(target_pos: Vector3):
	var launch = target_pos - global_position
	launch.y += 1.0
	var dir = launch.normalized()
	linear_velocity = dir * 0.5
	apply_impulse(Vector3.ZERO, dir*2.0)
	rotation_degrees.z = 180.0
	angular_velocity = Vector3(0.0, 0.0, -3.0)
	front_shown = false
	landed = false
	linear_damp = 0.5
	

func _physics_process(_delta):
	if not front_shown and rotation_degrees.z < 90.0:
		front_shown = true
		_show_front()
	if not landed and get_contact_count() > 0:
		landed = true
		linear_damp = slide_damp


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
