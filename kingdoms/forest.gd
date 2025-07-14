extends Node3D

@export var tree_scene: PackedScene
@export var num_trees: int = 50
@export var area_size: float = 40.0

func _ready():
	randomize()
	for i in num_trees:
		var tree = tree_scene.instantiate()
		var x = randf_range(-area_size, area_size)
		var z = randf_range(-area_size, area_size)
		tree.position = Vector3(x, 0, z)  # Place on XZ plane, adjust Y as needed

		# Random scale
		var scale = randf_range(0.8, 1.2)
		tree.scale = Vector3.ONE * scale

		# Random rotation
		tree.rotation.y = randf_range(0, TAU)  # TAU is 2*PI in Godot 4

		add_child(tree)
