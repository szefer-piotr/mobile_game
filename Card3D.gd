extends RigidBody3D

@export var value: int = 0
@export var icon_texture: Texture2D
@export var icon_type: String = ""
@export var launch_force: float = 2.0
@export var reveal_delay: float = 0.5
@export var arc_height: float = 1.0
@export var slide_friction: float = 0.85
@export var slide_threshold: float = 0.1

var label_assigned := false
var spawn_pos: Vector3
var target_pos: Vector3
var is_flying := false
var is_sliding := false
var slide_start_time: float = 0.0
var max_slide_time: float = 3.0  # Prevent infinite sliding

func _ready():
	# Start with frozen physics
	freeze = true
	lock_rotation = true
	
	# Set initial rotation - since your 3D model is naturally face up, 
	# rotate 180° to make it face down
	rotation_degrees = Vector3(0, 0, 180)
	
	# Set physics properties for realistic flight and sliding
	gravity_scale = 1.0  # Enable gravity for cards to fall on table
	linear_damp = 0.2    # Very low air resistance for ballistic flight
	angular_damp = 0.6   # Low angular resistance for rotation
	
	# Set physics material properties
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = 0.08     # Very low friction for smooth sliding
	physics_material.rough = false       # Smooth surface
	physics_material.bounce = 0.02       # Very slight bounce for table contact
	physics_material.absorbent = false   # Not absorbent
	physics_material_override = physics_material
	
	# Set collision properties
	collision_layer = 2  # Set to layer 2 for cards
	collision_mask = 1   # Only collide with layer 1 (table)
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Debug info
	print("Card ", value, " ready with collision layer ", collision_layer, " and mask ", collision_mask)
	
	update_label()
	update_icon()

func set_spawn_position(position: Vector3) -> void:
	spawn_pos = position
	print("Card ", value, " spawn position set to: ", position)

func fly_to(target_position: Vector3) -> void:
	# Safety check
	if not is_inside_tree():
		await get_tree().process_frame
	
	# Ensure we have valid positions
	if spawn_pos == Vector3.ZERO:
		spawn_pos = global_position
		print("Warning: Card ", value, " had no spawn position, using current position")
	
	# Debug info
	print("Card ", value, " launching from ", spawn_pos, " to: ", target_position)
	
	# Set initial position
	global_position = spawn_pos
	target_pos = target_position
	is_flying = true
	
	# Unfreeze for physics-based flight
	freeze = false
	lock_rotation = false
	
	# Calculate ballistic launch velocity for natural arc
	var direction = (target_pos - spawn_pos).normalized()
	var distance = spawn_pos.distance_to(target_pos)
	
	# Calculate horizontal and vertical components
	var horizontal_distance = Vector2(target_pos.x - spawn_pos.x, target_pos.z - spawn_pos.z).length()
	var height_difference = target_pos.y - spawn_pos.y
	
	# Calculate time to target based on launch force
	var time_to_target = distance / launch_force
	
	# Calculate velocities for natural arc trajectory
	var horizontal_velocity = horizontal_distance / time_to_target
	var vertical_velocity = (arc_height - height_difference) / time_to_target
	
	# Create launch velocity vector
	var launch_velocity = Vector3(
		direction.x * horizontal_velocity,
		vertical_velocity,
		direction.z * horizontal_velocity
	)
	
	# Add slight randomness for natural feel (reduced for more controlled flight)
	launch_velocity += Vector3(
		randf_range(-0.3, 0.3),
		randf_range(-0.2, 0.2),
		randf_range(-0.3, 0.3)
	)
	
	# Apply launch velocity
	linear_velocity = launch_velocity
	
	# Add realistic angular velocity for card rotation during flight
	angular_velocity = Vector3(
		randf_range(-2.0, 2.0),  # Roll
		randf_range(-3.0, 3.0),  # Pitch (forward/backward tilt)
		randf_range(-1.0, 1.0)   # Yaw (side-to-side rotation)
	)
	
	# Start monitoring flight
	set_physics_process(true)
	
	# Start a timer to transition to sliding after flight
	var flight_timer = get_tree().create_timer(time_to_target * 0.9)
	flight_timer.timeout.connect(_transition_to_sliding)

func _transition_to_sliding() -> void:
	if is_flying:
		is_flying = false
		_start_sliding()

func _physics_process(delta: float) -> void:
	if not is_flying and not is_sliding:
		return
	
	if is_flying:
		# During flight, gradually reduce velocity for smooth landing
		linear_velocity *= 0.99
		angular_velocity *= 0.97
		
		# Check if card has landed on table (y position close to table surface)
		if global_position.y <= 1.1:  # Table is at y=0.5, so 1.1 is just above it
			is_flying = false
			_start_sliding()
		
		# Also check if we're close enough to target to start sliding
		var distance_to_target = global_position.distance_to(target_pos)
		if distance_to_target < 0.8:
			is_flying = false
			_start_sliding()
	
	elif is_sliding:
		# Apply friction to slow down sliding
		linear_velocity *= slide_friction
		angular_velocity *= slide_friction
		
		# Keep card on table surface
		if global_position.y < 1.0:
			global_position.y = 1.0
			linear_velocity.y = 0
		
		# Check if sliding should stop
		if linear_velocity.length() < slide_threshold and angular_velocity.length() < slide_threshold:
			_stop_sliding()
			return
		
		# Check if sliding has been going on too long
		var current_time = Time.get_time_dict_from_system()["second"]
		if current_time - slide_start_time > max_slide_time:
			print("Card ", value, " sliding timeout")
			_stop_sliding()
		
		# Prevent cards from sliding too far from target
		var distance_to_target = global_position.distance_to(target_pos)
		if distance_to_target > 2.0:  # If card slides too far, stop it
			print("Card ", value, " sliding too far, stopping")
			_stop_sliding()

func _start_sliding() -> void:
	is_sliding = true
	slide_start_time = Time.get_time_dict_from_system()["second"]
	
	# Debug info
	print("Card ", value, " started sliding")
	
	# Reduce velocity for controlled sliding
	linear_velocity *= 0.5
	angular_velocity *= 0.6
	
	# Ensure card is on table surface
	global_position.y = 1.0
	linear_velocity.y = 0

func _on_body_entered(body: Node3D) -> void:
	if body != self:
		print("Card ", value, " hit body: ", body.name)
		
		# If we hit the table while flying, start sliding
		if is_flying and body.name == "Table":
			is_flying = false
			_start_sliding()
		
		# If we hit something while sliding, stop sliding
		elif is_sliding:
			_stop_sliding()

func _stop_sliding() -> void:
	is_sliding = false
	set_physics_process(false)
	
	# Debug info
	print("Card ", value, " stopped sliding")
	
	# Freeze physics and snap to final position
	freeze = true
	lock_rotation = true
	global_position = target_pos
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# Start flip animation
	_start_flip()

func _start_flip() -> void:
	# Debug info
	print("Card ", value, " starting flip")
	
	# Wait a bit before flipping
	await get_tree().create_timer(reveal_delay).timeout
	
	# Flip the card to reveal
	var flip_tween = get_tree().create_tween()
	flip_tween.set_parallel(true)
	
	# Flip rotation - flip from face down (180) to face up (0) since your model is naturally face up
	flip_tween.tween_property(self, "rotation_degrees:z", 0.0, 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Jump and bounce effect for more natural feel
	flip_tween.tween_property(self, "global_position:y", global_position.y + 0.4, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flip_tween.tween_property(self, "global_position:y", global_position.y, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Add slight rotation during flip for realism
	flip_tween.tween_property(self, "rotation_degrees:x", randf_range(-5, 5), 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	flip_tween.tween_callback(_show_front)

func _show_front():
	# Debug info
	print("Card ", value, " revealed")
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

func set_random_properties():
	# Set random card properties for variety
	value = randi() % 10 + 1  # Random value 1-10
	
	# Random icon type
	var icon_types = ["attack", "shield", "gold", "pillage", "special_item"]
	icon_type = icon_types[randi() % icon_types.size()]
	
	# Set icon texture based on type
	match icon_type:
		"attack":
			icon_texture = preload("res://item_icons/attack_256_256.png")
		"shield":
			icon_texture = preload("res://item_icons/shield_256_256.png")
		"gold":
			icon_texture = preload("res://item_icons/gold_256_256.png")
		"pillage":
			icon_texture = preload("res://item_icons/pillage_256_256.png")
		"special_item":
			icon_texture = preload("res://item_icons/special_item_256_256.png")
	
	# Update visual elements
	update_label()
	update_icon()
