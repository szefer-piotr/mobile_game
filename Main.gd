extends Node3D

@onready var card_scene = preload("res://Card3D.tscn")
@onready var card_table_scene = preload("res://card_table.tscn")

var card_table_root: Node3D
var card_row: Node3D
var card_spawn: Node3D
var draw_button: Button
var hold_button: Button
var score_label: Label
var total_label: Label
var result_label: Label
var restart_timer: Timer
var score_bar
var score_bar_label: Label
var reward_popup
@onready var cam = $Camera3D
@onready var building_entry_scene = preload("res://BuildingEntry.tscn")
var auto_draw_timer: Timer
@onready var knight_scene = preload("res://Knight.tscn")
var deck_spawn: Node3D

# Resources
var current_score = 0
var total_score = 0

# Reward paths
var current_path_name:String = ""
var reward_path: Array = []
var current_reward_index: int = 0
var progress_towards_current: int = 0

var displayed_score_value: float = 0.0
var target_score_bar_value: float = 0.0
var fill_speed = 6.0

var icon_textures = {
	"attack": preload("res://item_icons/attack_256_256.png"),
	"shield": preload("res://item_icons/shield_256_256.png"),
	"gold": preload("res://item_icons/gold_256_256.png"),
	"pillage": preload("res://item_icons/pillage_256_256.png"),
	"special_item": preload("res://item_icons/special_item_256_256.png")
}

var cards = []
var icon_counts: Dictionary = {}
var available_icons := ["attack", "shield", "gold", "pillage", "special_item"]

var default_cam_pos = Vector3()
var default_cam_rot = Vector3()

const KingdomData = preload("res://KingdomData.gd")

var kingdoms: Array = []
var current_kingdom_idx: int = 0
var buildings: Dictionary = {}

var auto_draw_enabled = false
var force_draw_until_15 = false


func show_card_table():
	card_table_root = card_table_scene.instantiate()
	add_child(card_table_root)

	card_row = card_table_root.get_node("CardRow")
	card_spawn = card_table_root.get_node("CardSpawn")
	draw_button = card_table_root.get_node("CanvasLayer/DrawButton")
	hold_button = card_table_root.get_node("CanvasLayer/HoldButton")
	score_label = card_table_root.get_node("CanvasLayer/ScoreLabel")
	total_label = card_table_root.get_node("CanvasLayer/TotalScoreLabel")
	result_label = card_table_root.get_node("CanvasLayer/ResultLabel")
	restart_timer = card_table_root.get_node("CanvasLayer/RestartTimer")
	score_bar = card_table_root.get_node("CanvasLayer/ScoreProgressBar")
	score_bar_label = card_table_root.get_node("CanvasLayer/ScoreProgressLabel")
	reward_popup = card_table_root.get_node("CanvasLayer/RewardReadyPopup")
	auto_draw_timer = card_table_root.get_node("CanvasLayer/AutoDrawTimer")
	deck_spawn = card_table_root.get_node("DeckSpawn")

	if draw_button and not draw_button.pressed.is_connected(card_table_root._on_DrawButton_pressed):
			draw_button.pressed.connect(card_table_root._on_DrawButton_pressed)
	if hold_button and not hold_button.pressed.is_connected(card_table_root._on_HoldButton_pressed):
			hold_button.pressed.connect(card_table_root._on_HoldButton_pressed)

func update_score_bar():
	if current_reward_index >= reward_path.size():
		target_score_bar_value = score_bar.max_value
		score_bar_label.text = "Path Complete!"
		return

	var reward = reward_path[current_reward_index]
	var current_goal = reward["points_needed"]
	var ratio = float(progress_towards_current) / current_goal
	target_score_bar_value = ratio * score_bar.max_value
	
	var reward_type = reward.get("reward_type", "")
	var reward_amount = reward.get("amount", 0)
	score_bar_label.text = "%d / %d -> %s %d" % [
		progress_towards_current,
		current_goal,
		reward_type,
		reward_amount
	]

func load_reward_path(path_name: String):
	var file_path = "res://reward_paths/%s.json" % path_name
	if not FileAccess.file_exists(file_path):
		push_error("Reward path not found: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = file.get_as_text()
	var result = JSON.parse_string(data)

	if typeof(result) == TYPE_ARRAY:
		reward_path = result
		current_path_name = path_name
		current_reward_index = 0
		progress_towards_current = 0
		update_score_bar()
		print("Loaded reward path: ", path_name)
	else:
		push_error("Failed to parse JSON reward path.")


func setup_kingdoms():
	kingdoms.clear()
	var k1 = KingdomData.new()
	k1.name = "Kingdom 1"
	k1.scene_path = "res://kingdoms/Kingdom01.tscn"
	k1.buildings = KingdomData.kingdom1_buildings()
	kingdoms.append(k1)
	
	var k2 = KingdomData.new()
	k2.name = "Kingdom 2"
	k2.scene_path = "res://kingdoms/Kingdom02.tscn"
	k2.buildings = KingdomData.kingdom2_buildings()
	kingdoms.append(k2)
	
	var k3 = KingdomData.new()
	k3.name = "Kingdom 3"
	k3.scene_path = "res://kingdoms/Kingdom03.tscn"
	k3.buildings = KingdomData.kingdom3_buildings()
	kingdoms.append(k3)


func load_kingdom(index: int):
	if index >= kingdoms.size():
		return
	current_kingdom_idx = index
	var data: KingdomData = kingdoms[index]
	buildings.clear()
	for key in data.buildings.keys():
		var entry = data.buildings[key]
		buildings[key] = {
			"level": entry.get("level", 0),
			"costs": entry.get("costs", []).duplicate()
		}
	var old_root = get_node_or_null("KingdomRoot")
	if old_root:
		old_root.queue_free()
	var new_root: Node3D = null
	if data.scene_path != "":
		var scene = load(data.scene_path)
		print(data.scene_path)
		if scene:
			new_root = scene.instantiate()
	if new_root == null:
		new_root = Node3D.new()
	new_root.name = "KingdomRoot"
	

	
	add_child(new_root)
	for key in buildings.keys():
		var label = get_building_label(key)
		if label:
			label.text = "%s (Lv. %d)" % [key, buildings[key]["level"]]
	var buildings_node = new_root.get_node_or_null("Buildings")
	if buildings_node:
		for building in buildings_node.get_children():
			building.visible = false
			var key = building.name.replace("_", " ")
			if buildings.has(key) and buildings[key]["level"] > 0:
				building.visible = true

	connect_building_buttons()
	update_all_building_buttons()

func check_kingdom_complete():
	for key in buildings.keys():
		var data = buildings[key]
		if data["level"] < data["costs"].size():
			return false
	load_kingdom(current_kingdom_idx + 1)
	return true

func _ready():
	show_card_table()
	load_reward_path("starter_path")
	randomize()
	restart_timer.timeout.connect(_on_restart_timer_timeout)
	auto_draw_timer.timeout.connect(_on_AutoDrawTimer_timeout)

	default_cam_pos = cam.global_position
	default_cam_rot = cam.rotation_degrees

	score_bar.min_value = 0
	score_bar.max_value = 100
	score_bar.value = 0
	displayed_score_value = 0.0
	target_score_bar_value = 0.0
	reward_popup.visible = false

	setup_kingdoms()
	print("Loading kingdoms...")
	load_kingdom(0)
	reset_game()
	$CanvasLayer/AutoToggleButton.text = "Auto: OFF"

func _process(delta):
	if abs(displayed_score_value - target_score_bar_value) > 0.1:
		displayed_score_value = lerp(
			displayed_score_value,
			target_score_bar_value,
			delta * fill_speed
		)
		score_bar.value = round(displayed_score_value)
	else:
		displayed_score_value = target_score_bar_value
		score_bar.value = round(target_score_bar_value)

func reset_game():
	current_score = 0
	icon_counts.clear()
	for icon in available_icons:
		icon_counts[icon] = 0
	cards.clear()
	score_label.text = "Score: 0"
	result_label.text = ""
	draw_button.disabled = false
	hold_button.disabled = true
	force_draw_until_15 = false
	auto_draw_timer.stop()
	
	for c in card_row.get_children():
		c.queue_free()

func add_score(amount: int):
	#current_score += amount
	progress_towards_current += amount
	
	while current_reward_index < reward_path.size():
		var reward = reward_path[current_reward_index]
		var required = reward["points_needed"]
		if progress_towards_current < required:
			break
		progress_towards_current -= required
		give_reward(reward)
		current_reward_index += 1
		
	update_score_bar()
	
	if current_reward_index >= reward_path.size():
		load_reward_path("kingdom_path")


func give_reward(reward: Dictionary):
	CurrencyManager.add_currency(reward["reward_type"], reward["amount"])
	var text = "Recieved %d %s!" % [reward["amount"], reward["reward_type"]]
	show_reward_popup(text)


#func _position_new_card(card):
	#var target_x = float(cards.size() - 1) * 0.25
	#var target_y = float(cards.size() - 1) * 0.025
	#var target_z = randf_range(-0.025, 0.025)
	#var pos = card_row.global_transform.origin + Vector3(target_x, target_y, target_z)
	#card.set_target_position(pos)

func start_auto_draw():
	if current_score < 15:
		draw_button.disabled = true
		hold_button.disabled = true
		auto_draw_timer.start()
	else:
		auto_draw_timer.stop()
		draw_button.disabled = false
		hold_button.disabled = current_score < 18
	

func _on_KingdomButton_pressed():
	show_kingdom_mode()

func show_kingdom_mode():
	var tween = get_tree().create_tween()
	tween.tween_property(cam, "global_position", Vector3(0, 10, 10), 0.5)
	tween.tween_property(cam, "rotation_degrees", Vector3(-40, 0, 0), 0.15)
	show_building_ui()
	if card_table_root:
		card_table_root.hide()
	if auto_draw_timer:
		auto_draw_timer.stop()

func show_building_ui():
	$CanvasLayer/KingdomPanel.visible = true
	draw_button.visible = false
	hold_button.visible = false
	$CanvasLayer/KingdomButton.visible = false
	var kroot = get_node_or_null("KingdomRoot")
	if kroot:
		kroot.visible = true
	var list = $CanvasLayer/KingdomPanel/ScrollContainer/BuildingList
	
	for child in list.get_children():
		child.queue_free()

	for key in buildings.keys():
		var entry = building_entry_scene.instantiate()
		var base = key.replace(" ", "")
		entry.name = base
		list.add_child(entry)

		var label: Label = entry.get_node("Label")
		label.text = "%s (Lv. %d)" % [key, buildings[key]["level"]]

		var btn: Button = entry.get_node("Button")
		btn.pressed.connect(_on_BuildingButton_pressed.bind(key))
	
	update_all_building_buttons()

func get_building_button(key: String) -> Button:
	var base = key.replace(" ", "")
	return $CanvasLayer/KingdomPanel/ScrollContainer/BuildingList.get_node_or_null("%s/Button" % base)

func get_building_label(key: String) -> Label:
	var base = key.replace(" ", "")
	return $CanvasLayer/KingdomPanel/ScrollContainer/BuildingList.get_node_or_null("%s/Label" % base)

func connect_building_buttons():
	for key in buildings.keys():
		var btn = get_building_button(key)
		if btn:
			if btn.pressed.get_connections():
				for c in btn.pressed.get_connections():
					btn.pressed.disconnect(c.callable)
			btn.pressed.connect(_on_BuildingButton_pressed.bind(key))

func end_game(msg: String, gave_reward: bool):
	result_label.text = msg
	total_label.text = "Total: " + str(total_score)

	var reward = 0
	if current_score == 21:
		reward = 50
	elif current_score >= 18 and current_score < 21:
		reward = current_score
	else:
		reward = 0
		
	add_score(reward)

	draw_button.disabled = true
	hold_button.disabled = true
	force_draw_until_15 = false
	auto_draw_timer.stop()
	restart_timer.start()

func show_reward_popup(text: String = ""):
	if text != "":
		reward_popup.text = text
	reward_popup.visible = true
	reward_popup.modulate.a = 0

	var tween = get_tree().create_tween()
	tween.tween_property(reward_popup, "modulate:a", 1.0, 0.4).as_relative()
	tween.tween_interval(1.2)
	tween.tween_property(reward_popup, "modulate:a", -1.0, 0.5).as_relative()
	tween.tween_callback(reward_popup.hide)

func _on_restart_timer_timeout():
	reset_game()
	if auto_draw_enabled:
		start_auto_draw()

func _on_BuildingButton_pressed(key: String):
	if not buildings.has(key):
		return

	var data = buildings[key]
	var lvl = data["level"]
	if lvl < data["costs"].size():
		var cost = data["costs"][lvl]
		if CurrencyManager.spend_coins(cost):
			data["level"] += 1
			buildings[key] = data

			var label = get_building_label(key)
			if label:
				label.text = "%s (Lv. %d)" % [key, data["level"]]

			var node_name = key.replace(" ", "")
			var buildings_node = $KingdomRoot.get_node_or_null("Buildings")
			if buildings_node:
				var build_node = buildings_node.get_node_or_null(node_name)
				if build_node:
					build_node.visible = true
					if key == "Castle" and data["level"] == 1:
						var npc = knight_scene.instantiate()
						npc.global_position = build_node.global_position + Vector3(2, 0, 0)
						npc.follow_center_node = build_node   # new property described below
						npc.area_size = 5                     # keep the knight near the castle
						$KingdomRoot.add_child(npc)
					
		update_building_button(key, data)
		check_kingdom_complete()
		

func update_building_button(key: String, data: Dictionary):
	var btn = get_building_button(key)
	if btn == null:
		return

	var lvl = data["level"]
	if lvl < data["costs"].size():
		var cost = data["costs"][lvl]
		if lvl == 0:
			btn.text = "Build (%d)" % cost
		else:
			btn.text = "Upgrade (%d)" % cost
	else:
		btn.text = "MAXED"
		btn.disabled = true

func update_all_building_buttons():
	for key in buildings.keys():
		update_building_button(key, buildings[key])

func hide_building_ui():
	$CanvasLayer/KingdomPanel.visible = false
	draw_button.visible = true
	hold_button.visible = true

func hide_kingdom_mode():
	hide_building_ui()
	#var kroot = get_node_or_null("KingdomRoot")
	#if kroot:
			#kroot.visible = false
	var tween = get_tree().create_tween()
	tween.tween_property(cam, "global_position", default_cam_pos, 0.05)
	tween.tween_property(cam, "rotation_degrees", default_cam_rot, 0.25)
	$CanvasLayer/KingdomButton.visible = true
	if card_table_root:
		card_table_root.show()
		if auto_draw_enabled and restart_timer.is_stopped():
			start_auto_draw()
	else:
		show_card_table()
		reset_game()

func _unhandled_input(event):
	if $CanvasLayer/KingdomPanel.visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var rect = $CanvasLayer/KingdomPanel.get_global_rect()
			if not rect.has_point(event.position):
				hide_kingdom_mode()


func _on_AutoDrawTimer_timeout():
	if not auto_draw_enabled:
		auto_draw_timer.stop()
		return

	draw_card()
	hold_button.disabled = current_score < 18
	if current_score >= 21:
		return
	
	if current_score >= 18:
		if randi() % 2 == 0:
			_on_HoldButton_pressed()
		else:
			auto_draw_timer.start()
	else:
		auto_draw_timer.start()


func _on_AutoToggleButton_pressed():
	auto_draw_enabled = !auto_draw_enabled
	if auto_draw_enabled:
			$CanvasLayer/AutoToggleButton.text = "Auto: ON"
	else:
			auto_draw_timer.stop()
			draw_button.disabled = false
			hold_button.disabled = current_score < 18
			$CanvasLayer/AutoToggleButton.text = "Auto: OFF"
