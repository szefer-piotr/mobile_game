extends RigidBody3D

@export var value: int = 0
@export var icon_texture: Texture2D
@export var icon_type: String = ""
@export var launch_force: float = 2.0
@export var reveal_delay: float = 0.5
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
	
        # Set physics properties for straight-line flight and sliding
        gravity_scale = 0.0  # Disable gravity so cards travel in a straight line
        linear_damp = 0.2    # Low air resistance for smooth motion
        angular_damp = 0.6   # Low angular resistance for slight rotation
	
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
	
        # Calculate straight-line velocity toward target
        var direction = target_pos - spawn_pos
        var distance = direction.length()
        if distance == 0:
                _transition_to_sliding()
                return
        direction = direction.normalized()

        # Apply constant velocity toward the target
        linear_velocity = direction * launch_force

        # Maintain height during flight
        global_position.y = spawn_pos.y

        # Add slight angular motion for natural feel
        angular_velocity = Vector3(
                randf_range(-1.0, 1.0),
                randf_range(-1.0, 1.0),
                randf_range(-0.5, 0.5)
        )

        # Start monitoring flight and schedule transition to sliding
        set_physics_process(true)
        var travel_time = distance / launch_force
        var flight_timer = get_tree().create_timer(travel_time)
        flight_timer.timeout.connect(_transition_to_sliding)

func _transition_to_sliding() -> void:
	if is_flying:
		is_flying = false
		_start_sliding()

func _physics_process(delta: float) -> void:
	if not is_flying and not is_sliding:
		return
	
        if is_flying:
                # During flight, gradually reduce velocity for smoother motion
                linear_velocity *= 0.99
                angular_velocity *= 0.97

                # Start sliding when we're very close to the target
                var distance_to_target = global_position.distance_to(target_pos)
                if distance_to_target < 0.1:
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
