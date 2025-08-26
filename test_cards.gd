extends Node3D

@onready var card_scene = preload("res://Card3D.tscn")
@onready var card_spawn = $CardSpawn
@onready var card_target = $CardTarget
@onready var test_button = $TestButton

func _ready():
	test_button.pressed.connect(_on_test_button_pressed)

func _on_test_button_pressed():
	# Create a test card
	var card = card_scene.instantiate()
	add_child(card)
	
	# Set card properties
	card.value = randi() % 6 + 1
	card.icon_texture = preload("res://item_icons/attack_256_256.png")
	card.icon_type = "attack"
	
	# Position card at spawn
	card.global_position = card_spawn.global_position
	card.spawn_pos = card_spawn.global_position
	
	# Start the flight
	card.fly_to(card_target.global_position)
