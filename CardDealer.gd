extends Node3D

@export var card_scene: PackedScene
@export var deal_speed: float = 0.15  # Time between card deals
@export var launch_force: float = 8.0
@export var arc_height: float = 1.5
@export var slide_friction: float = 0.92
@export var slide_threshold: float = 0.05

var card_positions: Array[Marker3D] = []
var spawned_cards: Array[Node3D] = []
var is_dealing = false

func _ready():
	print("CardDealer ready - card_scene: ", card_scene)
	
	# If card_scene is not set, try to load it
	if not card_scene:
		card_scene = preload("res://Card3D.tscn")
		print("Loaded card_scene: ", card_scene)
	
	_collect_card_positions()

func _collect_card_positions():
	# Collect all card position markers
	card_positions.clear()
	
	# Get all rows - CardPositions is a sibling of CardDeck, not a child
	var card_positions_node = get_parent().get_node("CardPositions")
	if not card_positions_node:
		print("ERROR: Could not find CardPositions node")
		print("Parent node: ", get_parent())
		print("Parent children: ", get_parent().get_children())
		return
		
	print("Found CardPositions node: ", card_positions_node)
	var rows = card_positions_node.get_children()
	print("Rows found: ", rows.size())
	
	for row in rows:
		if row.name.begins_with("Row"):
			print("Processing row: ", row.name)
			var positions = row.get_children()
			print("Positions in ", row.name, ": ", positions.size())
			for pos in positions:
				if pos is Marker3D:
					card_positions.append(pos)
					print("Added position: ", pos.name, " at ", pos.global_position)
	
	print("Found ", card_positions.size(), " card positions total")

func deal_cards():
	if is_dealing:
		return
	
	is_dealing = true
	print("Starting to deal ", card_positions.size(), " cards")
	
	# Deal cards one by one with realistic timing
	for i in range(card_positions.size()):
		var card = _spawn_card()
		if not card:
			print("ERROR: Failed to spawn card ", i, ", skipping...")
			continue
			
		var target_pos = card_positions[i].global_position
		
		print("Dealing card ", i, " to position: ", target_pos)
		
		# Set card properties - spawn cards higher above the table
		var spawn_pos = global_position
		spawn_pos.y = 3.0  # Spawn cards higher up
		card.set_spawn_position(spawn_pos)
		card.launch_force = launch_force
		card.arc_height = arc_height
		card.slide_friction = slide_friction
		card.slide_threshold = slide_threshold
		
		# Launch card to target position
		card.fly_to(target_pos)
		
		# Wait before dealing next card
		await get_tree().create_timer(deal_speed).timeout
	
	is_dealing = false
	print("Finished dealing cards")

func _spawn_card() -> Node3D:
	if not card_scene:
		print("ERROR: Card scene is null!")
		return null
		
	var card = card_scene.instantiate()
	if not card:
		print("ERROR: Failed to instantiate card!")
		return null
		
	add_child(card)
	spawned_cards.append(card)
	
	# Set random card properties for variety
	var card_script = card.get_script()
	if card_script and card_script.has_method("set_random_properties"):
		card.set_random_properties()
	
	print("Spawned card successfully")
	return card

func reset_cards():
	# Remove all spawned cards
	for card in spawned_cards:
		if is_instance_valid(card):
			card.queue_free()
	
	spawned_cards.clear()
	print("Reset all cards")
