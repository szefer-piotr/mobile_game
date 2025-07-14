extends Node3D

@onready var card_scene = preload("res://Card3D.tscn")
@onready var card_row = $CardRow
@onready var card_spawn = $CardSpawn
@onready var draw_button = $CanvasLayer/DrawButton
@onready var hold_button = $CanvasLayer/HoldButton
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var total_label = $CanvasLayer/TotalScoreLabel
@onready var result_label = $CanvasLayer/ResultLabel
@onready var restart_timer = $CanvasLayer/RestartTimer
@onready var score_bar = $CanvasLayer/ScoreProgressBar
@onready var score_bar_label = $CanvasLayer/ScoreProgressLabel
@onready var reward_popup = $CanvasLayer/RewardReadyPopup
@onready var cam = $Camera3D
@onready var building_entry_scene = preload("res://BuildingEntry.tscn")

var current_score = 0
var total_score = 0
var cards = []

var displayed_score_value: float = 0.0
var target_score_bar_value: float = 0.0
var fill_speed = 6.0

var default_cam_pos = Vector3()
var default_cam_rot = Vector3()

const KingdomData = preload("res://KingdomData.gd")

var kingdoms: Array = []
var current_kingdom_idx: int = 0
var buildings: Dictionary = {}

func setup_kingdoms():
	kingdoms.clear()
	var k1 = KingdomData.new()
	k1.name = "Kingdom 1"
	k1.scene_path = "res://Kingdom1.tscn"
	k1.buildings = KingdomData.default_buildings()
	kingdoms.append(k1)

	var k2 = KingdomData.new()
	k2.name = "Kingdom 2"
	k2.scene_path = "res://Kingdom2.tscn"
	k2.buildings = KingdomData.default_buildings()
	kingdoms.append(k2)

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

	for building in new_root.get_children():
		building.visible = false

	for building in new_root.get_children():
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
	randomize()
	restart_timer.timeout.connect(_on_restart_timer_timeout)

	default_cam_pos = cam.global_position
	default_cam_rot = cam.rotation_degrees

	score_bar.min_value = 0
	score_bar.max_value = 100
	score_bar.value = 0
	displayed_score_value = 0.0
	target_score_bar_value = 0.0
	reward_popup.visible = false

	setup_kingdoms()
	load_kingdom(0)

	reset_game()

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
	cards.clear()
	score_label.text = "Score: 0"
	result_label.text = ""
	draw_button.disabled = false
	hold_button.disabled = false

	for c in card_row.get_children():
		c.queue_free()

func _position_new_card(card):
	var target_x = float(cards.size() - 1) * 0.25
	var target_y = float(cards.size() - 1) * 0.025
	var target_z = randf_range(-0.025, 0.025)
	card.target_position = card_row.global_transform.origin + Vector3(target_x, target_y, target_z)

func _on_DrawButton_pressed():
	var value = randi() % 6 + 1
	current_score += value
	score_label.text = "Score: " + str(current_score)

	var card = card_scene.instantiate()
	card.value = value
	card.global_position = card_spawn.global_position
	card_row.add_child(card)
	cards.append(card)

	call_deferred("_finalize_card_position", card)

	if current_score == 21:
		total_score += 50
		end_game("🎉 Jackpot! +50", true)
	elif current_score > 21:
		end_game("💥 Bust!", false)

func _finalize_card_position(card):
	if not card_row.is_inside_tree():
		await get_tree().process_frame

	var target_x = float(cards.size() - 1) * 0.25
	var target_y = float(cards.size() - 1) * 0.025
	var target_z = randf_range(-0.025, 0.025)
	var target_position = card_row.global_transform.origin + Vector3(target_x, target_y, target_z)

	card.set_target_position(target_position)

func _on_HoldButton_pressed():
	if current_score >= 18:
		total_score += current_score
		end_game("👍 Scored " + str(current_score), true)
	else:
		end_game("😐 Low score...", false)

func _on_KingdomButton_pressed():
	show_kingdom_mode()

func show_kingdom_mode():
	var tween = get_tree().create_tween()
	tween.tween_property(cam, "global_position", Vector3(0, 5, 1), 0.25)
	tween.tween_property(cam, "rotation_degrees", Vector3(-55, 0, 0), 0.25)
	show_building_ui()

func show_building_ui():
	$CanvasLayer/KingdomPanel.visible = true
	$CanvasLayer/DrawButton.visible = false
	$CanvasLayer/HoldButton.visible = false
	$KingdomRoot.visible = true

	var list = $CanvasLayer/KingdomPanel/BuildingList
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
	return $CanvasLayer/KingdomPanel/BuildingList.get_node_or_null("%s/Button" % base)

func get_building_label(key: String) -> Label:
	var base = key.replace(" ", "")
	return $CanvasLayer/KingdomPanel/BuildingList.get_node_or_null("%s/Label" % base)

func connect_building_buttons():
	for key in buildings.keys():
		var btn = get_building_button(key)
		if btn:
			btn.pressed.disconnect_all()
			btn.pressed.connect(_on_BuildingButton_pressed.bind(key))

func end_game(msg: String, gave_reward: bool):
	result_label.text = msg
	total_label.text = "Total: " + str(total_score)

	var reward = 0
	if current_score == 21:
		reward = 50
	elif current_score >= 18:
		reward = current_score

	CurrencyManager.add_coins(reward)
	target_score_bar_value = float(total_score % 100)

	if target_score_bar_value >= score_bar.max_value:
		show_reward_popup()

	draw_button.disabled = true
	hold_button.disabled = true
	restart_timer.start()

func show_reward_popup():
	reward_popup.visible = true
	reward_popup.modulate.a = 0

	var tween = get_tree().create_tween()
	tween.tween_property(reward_popup, "modulate:a", 1.0, 0.4).as_relative()
	tween.tween_interval(1.2)
	tween.tween_property(reward_popup, "modulate:a", -1.0, 0.5).as_relative()
	tween.tween_callback(reward_popup.hide)

func _on_restart_timer_timeout():
	reset_game()

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
			var build_node = $KingdomRoot.get_node_or_null(node_name)
			if build_node:
				build_node.visible = true
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
	$CanvasLayer/DrawButton.visible = true
	$CanvasLayer/HoldButton.visible = true

func hide_kingdom_mode():
	hide_building_ui()
	var tween = get_tree().create_tween()
	tween.tween_property(cam, "global_position", default_cam_pos, 0.25)
	tween.tween_property(cam, "rotation_degrees", default_cam_rot, 0.25)

func _unhandled_input(event):
	if $CanvasLayer/KingdomPanel.visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var rect = $CanvasLayer/KingdomPanel.get_global_rect()
			if not rect.has_point(event.position):
				hide_kingdom_mode()
