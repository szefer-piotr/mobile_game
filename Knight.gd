extends CharacterBody3D

@export var speed: float = 3.0
@export var area_size: float = 8.0
@export var idle_time_range: Vector2 = Vector2(1.5, 3.0)
@export var move_time_range: Vector2 = Vector2(3.0, 7.0)

@onready var anim_player: AnimationPlayer = $Knight/AnimationPlayer
@onready var knight_model: Node3D = $Knight
@onready var timer: Timer = $Timer

var target_pos: Vector3
var is_idle := false

func _ready():
	knight_model.rotation_degrees.y = 180
	randomize()
	timer.one_shot = true
	timer.connect("timeout", _on_Timer_timeout)
	enter_move_state()
		
func _physics_process(delta: float) -> void:
	if is_idle:
		return
		
	var to_target = target_pos - global_position
	to_target.y = 0
	
	if to_target.length() < 0.2:
		pick_new_target()
		to_target = target_pos - global_position
		to_target.y = 0
	
	var dir = to_target.normalized()
	
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y -= 9.8 * delta
	
	look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
	
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		velocity = Vector3.ZERO
	else:
		move_and_slide()
	#
	#if velocity.length() > 0.1:
		#look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
		
func pick_new_target():
	var x = randf_range(-area_size, area_size)
	var z = randf_range(-area_size, area_size)
	target_pos = Vector3(x, global_position.y, z)

func enter_move_state():
	is_idle = false
	pick_new_target()
	if anim_player:
		anim_player.play("Walking_B")
	timer.start(randf_range(move_time_range.x, move_time_range.y))
	
func enter_idle_state():
	is_idle = true
	velocity = Vector3.ZERO
	if anim_player:
		anim_player.play("Idle")
	timer.start(randf_range(idle_time_range.x, idle_time_range.y))
	
func _on_Timer_timeout():
	if is_idle:
		enter_move_state()
	else:
		enter_idle_state()
