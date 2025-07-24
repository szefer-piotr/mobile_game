extends CharacterBody3D

@export var speed: float = 2.0
@export var area_size: float = 8.0

@onready var anim_player: AnimationPlayer = $Knight/AnimationPlayer

var target_pos: Vector3

func _ready():
	randomize()
	pick_new_target()
	if anim_player:
		anim_player.play("Walking_A")
		
func _physics_process(delta: float) -> void:
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
	move_and_slide()
	if velocity.length() > 0.1:
		look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
		
func pick_new_target():
	var x = randf_range(-area_size, area_size)
	var z = randf_range(-area_size, area_size)
	target_pos = Vector3(x, global_position.y, z)
