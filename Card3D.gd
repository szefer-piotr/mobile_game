extends RigidBody3D

@export var value: int = 0
@export var icon_texture: Texture2D
@export var icon_type: String = ""

# Flight/landing tuning
@export var forward_speed: float = 8.0         # big impact on Z travel
@export var up_speed: float = 6.0              # arc height
@export var throw_impulse_magnitude: float = 4 # optional extra push along XZ
@export var rotation_speed_z: float = -0.25
@export var airborne_linear_damp: float = 0.0  # no damping in air
@export var landed_linear_damp: float = 2.0    # heavy damping on landing
@export var angular_slide_damp: float = 10.0
@export var flight_time: float = 0.35
@export var reveal_delay: float = 0.15

var label_assigned := false
var front_shown := false
var landed := false

func _ready():
	# Keep damping low initially; we’ll set exact values on throw/land.
	linear_damp = 0.0
	angular_damp = 0.1

# Put this anywhere in the script (top-level is fine)
func _ballistic_velocity_to(target_pos: Vector3, flight_time: float) -> Vector3:
	var g_mag: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	var g: Vector3 = Vector3(0.0, -g_mag, 0.0)

	var to: Vector3 = target_pos - global_position
	var t: float = max(0.2, flight_time)

	var v0: Vector3 = (to - 0.5 * g * t * t) / t
	return v0

func throw_to(target_pos: Vector3) -> void:
	var v0: Vector3 = _ballistic_velocity_to(target_pos, flight_time)
	linear_velocity = v0
	angular_velocity = Vector3(0.0, 0.0, rotation_speed_z)
	rotation_degrees.z = 180.0

	front_shown = false
	landed = false
	linear_damp = 0.0
	angular_damp = 0.0

func throw_with_physics(target_pos: Vector3) -> void:
	var v0: Vector3 = _ballistic_velocity_to(target_pos, flight_time)
	linear_velocity = v0
	apply_torque_impulse(Vector3(0.0, 0.0, rotation_speed_z))

	front_shown = false
	landed = false
	linear_damp = 0.0
	angular_damp = 0.0


func throw_ballistic(target_pos: Vector3, t: float = flight_time) -> void:
	var g_mag: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	var g: Vector3 = Vector3(0.0, -g_mag, 0.0)
	var to: Vector3 = target_pos - global_position
	t = max(0.2, t)

	# p + v0*t + 0.5*g*t^2 = target  ->  v0 = (to - 0.5*g*t^2)/t
	var v0: Vector3 = (to - 0.5 * g * t * t) / t

	# Set initial state
	linear_velocity = v0
	rotation_degrees.z = 180.0            # start upside-down
	angular_velocity = Vector3(0.0, 0.0, deg_to_rad(-180.0) / t)  # one flip to 0°
	linear_damp = 0.0                     # no damping in air
	angular_damp = 0.0

	front_shown = false
	landed = false


func _physics_process(_delta: float) -> void:
	# Don’t reveal in the air; we’ll flip after landing
	if not landed and get_contact_count() > 0:
		landed = true
		linear_damp = 2.0
		angular_damp = angular_slide_damp
		angular_velocity = Vector3.ZERO
		rotation_degrees.z = 180.0  # ensure face-down

		# Flip to show face after a short delay
		var t := get_tree().create_tween()
		t.tween_interval(reveal_delay)
		t.tween_property(self, "rotation_degrees:z", 0.0, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_callback(Callable(self, "_show_front"))


func _show_front():
	update_label()
	update_icon()


func deal_physics(target_pos: Vector3, t: float = flight_time) -> void:
	# Ballistic initial velocity to reach target exactly in time t
	var g_mag: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	var g: Vector3 = Vector3(0.0, -g_mag, 0.0)
	var to: Vector3 = target_pos - global_position
	t = max(0.2, t)

	var v0: Vector3 = (to - 0.5 * g * t * t) / t

	# Start face-down in the air (we'll keep it face-down until landing)
	rotation_degrees.z = 180.0
	linear_velocity = v0
	angular_velocity = Vector3.ZERO
	linear_damp = 0.0
	angular_damp = 0.0

	front_shown = false
	landed = false



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
			
#extends RigidBody3D
#
#@export var value: int = 0
#@export var icon_texture: Texture2D
#@export var icon_type: String = ""
#@export var angular_slide_damp: float = 10.0
#@export var rotation_speed_z: float = -0.25
#@export var throw_linear_velocity: float = 0.5
#@export var throw_impulse_magnitude: float = 10
#
#var label_assigned := false
#var front_shown := false
#var landed := false
#var slide_damp := 0.5
#
#
#func set_target_position(pos: Vector3):
	#var dir = pos - global_position
	#dir.y = 0
	#var impulse = dir.normalized() * 5.0
	#apply_impulse(Vector3.ZERO, impulse)
#
#
#func _ready():
	#linear_damp = slide_damp
	#angular_damp = 0.1
#
#
#func throw_to(target_pos: Vector3):
	#var launch = target_pos - global_position
	#launch.y += 1.0
	#launch.z -= 20.0
	#launch = launch.normalized()
	#linear_velocity = launch * throw_linear_velocity
	#apply_impulse(Vector3.ZERO, launch * throw_impulse_magnitude)
	#rotation_degrees.z = 180.0
	#angular_velocity = Vector3(0.0, 0.0, rotation_speed_z)
	#front_shown = false
	#landed = false
	#linear_damp = slide_damp
	#angular_damp = 0.1
#
#
#func throw_with_physics(target_pos: Vector3):
	#var launch = target_pos - global_position
	#launch.y += 1.0
	#launch.z -= 20.0
	#launch = launch.normalized()
	#linear_velocity = launch * throw_linear_velocity
	#apply_impulse(Vector3.ZERO, launch * throw_impulse_magnitude)
	#apply_torque_impulse(Vector3(0.0, 0.0, rotation_speed_z))
	#front_shown = false
	#landed = false
	#linear_damp = 0.1
	#angular_damp = 0.1
#
#func _physics_process(_delta):
	#if not front_shown and rotation_degrees.z < 90.0:
		#front_shown = true
		#_show_front()
	#if not landed and get_contact_count() > 0:
		#landed = true
		#linear_damp = 2.0
		#angular_damp = angular_slide_damp
		#angular_velocity = Vector3.ZERO
#
#
#func _show_front():
	## change material/texture so the front is visible
	#update_label()
	#update_icon()
#
#
#func update_label():
	#if has_node("ValueLabel"):
		#var label = $ValueLabel
		#if label:
			#label.text = str(value)
			#label_assigned = true
#
#
#func update_icon():
	#if has_node("IconSprite"):
		#var sprite = $IconSprite
		#if sprite:
			#sprite.texture = icon_texture
