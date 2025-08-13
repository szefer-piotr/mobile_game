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
@export var slide_time: float = 1

var label_assigned := false
var front_shown := false
var landed := false
var slide_timer := 0.0


func _ready():
	contact_monitor = true
	max_contacts_reported = 4
	linear_damp = 1.5
	angular_damp = 4.0


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
	if not landed and get_contact_count() > 0:
		landed = true

		# Stop all motion
		linear_damp = landed_linear_damp
		angular_damp = angular_slide_damp
		angular_velocity = Vector3.ZERO
		rotation_degrees.z = 180.0  # make sure we’re face-down on contact
		
		slide_timer = slide_time
		
	elif landed and not freeze:
		if slide_timer > 0.0:
			slide_timer -= _delta
		if slide_timer <= 0.0 or linear_velocity.length() < 0.05:
			freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			freeze = true
			var t := get_tree().create_tween()
			t.tween_interval(reveal_delay)
			t.tween_property(self, "rotation_degrees:z", 0.0, 0.18)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			t.tween_callback(func ():
				_show_front()
				)


func _show_front():
	update_label()
	update_icon()


@export var min_throw_speed: float = 3.0    # bump these up
@export var max_throw_speed: float = 8.0
@export var extra_slide_damp_delay: float = 0.35

func deal_physics(target: Vector3, strength: float = 0.5) -> void:
	var start: Vector3 = global_transform.origin
	var to_vec: Vector3 = target - start
	var dist: float = to_vec.length()

	# Map distance to speed (tune 'dist_for_max' to your table size)
	var dist_for_max: float = 4.0  # meters at which we use max speed
	var t: float = clamp(dist / dist_for_max, 0.0, 1.0)
	var base: float = lerpf(min_throw_speed, max_throw_speed, max(t, strength))

	var v: Vector3 = to_vec.normalized() * base
	# Nudge downward so it lands (keeps arc subtle)
	v.y = v.y - 1.0

	linear_velocity = v
	angular_velocity = Vector3(0.0, randf_range(-1.0, 1.0), 0.0)
	sleeping = false

	await get_tree().create_timer(extra_slide_damp_delay).timeout
	self.linear_damp = 6.0
	self.angular_damp = 8.0




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
