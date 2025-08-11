extends RigidBody3D

@export var value: int = 0
@export var icon_texture: Texture2D
@export var icon_type: String = ""
@export var angular_slide_damp: float = 10.0
@export var rotation_speed_z: float = -0.25
@export var throw_linear_velocity: float = 0.5
@export var throw_impulse_magnitude: float = 2.0

var label_assigned := false
var front_shown := false
var landed := false
var slide_damp := 0.5


func set_target_position(pos: Vector3):
	var dir = pos - global_position
	dir.y = 0
	var impulse = dir.normalized() * 5.0
	apply_impulse(Vector3.ZERO, impulse)


func _ready():
	linear_damp = slide_damp
	angular_damp = 0.1


func throw_to(target_pos: Vector3):
	var launch = target_pos - global_position
	launch.y += 1.0
	var dir = launch.normalized()
	linear_velocity = dir * throw_linear_velocity
	apply_impulse(Vector3.ZERO, dir * throw_impulse_magnitude)
	rotation_degrees.z = 180.0
	angular_velocity = Vector3(0.0, 0.0, rotation_speed_z)
	front_shown = false
	landed = false
	linear_damp = slide_damp
	angular_damp = 0.1


func throw_with_physics(target_pos: Vector3):
	var launch = target_pos - global_position
	launch.y += 1.0
	var dir = launch.normalized()
	linear_velocity = dir * throw_linear_velocity
	apply_impulse(Vector3.ZERO, dir * throw_impulse_magnitude)
	apply_torque_impulse(Vector3(0.0, 0.0, rotation_speed_z))
	front_shown = false
	landed = false
	linear_damp = 0.1
	angular_damp = 0.1

func _physics_process(_delta):
	if not front_shown and rotation_degrees.z < 90.0:
		front_shown = true
		_show_front()
	if not landed and get_contact_count() > 0:
		landed = true
		linear_damp = 2.0
		angular_damp = angular_slide_damp
		angular_velocity = Vector3.ZERO


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
