extends CharacterBody3D

@export var speed: float = 1.0
@export var area_size: float = 8.0
@export var idle_time_range: Vector2 = Vector2(1.5, 3.0)
@export var move_time_range: Vector2 = Vector2(3.0, 7.0)

@onready var anim_player: AnimationPlayer = $Knight/AnimationPlayer
@onready var knight_model: Node3D = $Knight
@onready var timer: Timer = $Timer

@export var follow_center_node: Node3D
var target_pos: Vector3
var center_pos: Vector3
var is_idle := false

func _ready():
	knight_model.rotation_degrees.y = 180
	randomize()
	timer.one_shot = true
	timer.timeout.connect(_on_Timer_timeout)
	# Knight.gd
	center_pos = follow_center_node.global_position if follow_center_node else global_position
	#center_pos = follow_center_node != null ? follow_center_node.global_position : global_position
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
	
	move_and_slide()
	if is_on_wall():
		enter_idle_state()
		
#func pick_new_target():
	#var x = randf_range(-area_size, area_size)
	#var z = randf_range(-area_size, area_size)
	#target_pos = Vector3(x, global_position.y, z)

func pick_new_target():
	if follow_center_node:
		center_pos = follow_center_node.global_position
	var x = randf_range(-area_size, area_size)
	var z = randf_range(-area_size, area_size)
	target_pos = center_pos + Vector3(x, 0, z)

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
