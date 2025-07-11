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

var current_score = 0
var total_score = 0
var cards = []

var displayed_score_value: float = 0.0
var target_score_bar_value: float = 0.0
var fill_speed = 6.0

var buildings = {
        "Peon Hut": {
                "level": 0,
                "costs": [100, 200, 400, 800, 1600]
        },
        "Card Shrine": {
                "level": 0,
                "costs": [150, 300, 600, 1200, 2400]
        },
        "Barracks": {
                "level": 0,
                "costs": [200, 400, 800, 1600, 3200]
        },
        "Farm": {
                "level": 0,
                "costs": [120, 240, 480, 960, 1920]
        },
        "Blacksmith": {
                "level": 0,
                "costs": [250, 500, 1000, 2000, 4000]
        },
        "Archery Range": {
                "level": 0,
                "costs": [180, 360, 720, 1440, 2880]
        },
        "Stable": {
                "level": 0,
                "costs": [220, 440, 880, 1760, 3520]
        },
        "Wizard Tower": {
                "level": 0,
                "costs": [300, 600, 1200, 2400, 4800]
        },
        "Market": {
                "level": 0,
                "costs": [160, 320, 640, 1280, 2560]
        },
        "Wall": {
                "level": 0,
                "costs": [140, 280, 560, 1120, 2240]
        }
}

func _ready():
	randomize()
	restart_timer.timeout.connect(_on_restart_timer_timeout)

	score_bar.min_value = 0
	score_bar.max_value = 100
	score_bar.value = 0
	displayed_score_value = 0.0
	target_score_bar_value = 0.0
	reward_popup.visible = false
	
	for building in $KingdomRoot.get_children():
		building.visible = false

	reset_game()

func _process(delta):
	# Animate the progress bar toward the target
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

	# remove old cards
	for c in card_row.get_children():
		c.queue_free()

func _on_DrawButton_pressed():
	var value = randi() % 6 + 1
	current_score += value
	score_label.text = "Score: " + str(current_score)

	var card = card_scene.instantiate()
	card.value = value
	card.global_position = card_spawn.global_position

	# spread cards along x axis, slightly offset for fun
	var target_x = float(cards.size()) * 0.25
	var target_y = float(cards.size()) * 0.025
	var target_z = randf_range(-0.025, 0.025)
	card.target_position = card_row.global_transform.origin + Vector3(target_x, target_y, target_z)

	card_row.add_child(card)
	cards.append(card)

	if current_score == 21:
		total_score += 50
		end_game("🎉 Jackpot! +50", true)
	elif current_score > 21:
		end_game("💥 Bust!", false)

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
        connect_building_buttons()
        update_all_building_buttons()

func connect_building_buttons():
        for key in buildings.keys():
                var btn_name = key.replace(" ", "") + "Button"
                var btn = $CanvasLayer/KingdomPanel/BuildingList.get_node_or_null(btn_name)
                if btn:
                        btn.set_meta("building_key", key)
                        if not btn.pressed.is_connected(_on_BuildingButton_pressed):
                                btn.pressed.connect(_on_BuildingButton_pressed.bind(btn))

func end_game(msg: String, gave_reward: bool):
	result_label.text = msg
	total_label.text = "Total: " + str(total_score)
	
	# Give coins as Blackjack reward
	var reward = 0
	if current_score == 21:
		reward = 50
	elif current_score >= 18:
		reward = current_score

	CurrencyManager.add_coins(reward)

	# Update progress bar target value (modulo if you want looped bar)
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

func _on_BuildingButton_pressed(btn: Button):
        if not btn.has_meta("building_key"):
                return

        var key = btn.get_meta("building_key")
        if not buildings.has(key):
                return

        var data = buildings[key]
        var lvl = data["level"]
        if lvl < data["costs"].size():
                var cost = data["costs"][lvl]
                if CurrencyManager.spend_coins(cost):
                        data["level"] += 1
                        buildings[key] = data

                        var label_name = key.replace(" ", "") + "Label"
                        var label = $CanvasLayer/KingdomPanel/BuildingList.get_node_or_null(label_name)
                        if label:
                                label.text = "%s (Lv. %d)" % [key, data["level"]]

                        var node_name = key.replace(" ", "")
                        var build_node = $KingdomRoot.get_node_or_null(node_name)
                        if build_node:
                                build_node.visible = true

                        update_building_button(btn.name, data)


func update_building_button(button_name: String, data: Dictionary):
	var btn = $CanvasLayer/KingdomPanel/BuildingList.get_node_or_null(button_name)
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
	for name in buildings.keys():
		var data = buildings[name]
		var button_name = name.replace(" ", "") + "Button"
		update_building_button(button_name, data)
