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

var current_score = 0
var total_score = 0
var cards = []

var displayed_score_value: float = 0.0
var target_score_bar_value: float = 0.0
var fill_speed = 6.0

func _ready():
	randomize()
	restart_timer.timeout.connect(_on_restart_timer_timeout)

	score_bar.min_value = 0
	score_bar.max_value = 100
	score_bar.value = 0
	displayed_score_value = 0.0
	target_score_bar_value = 0.0
	reward_popup.visible = false

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

func end_game(msg: String, gave_reward: bool):
	result_label.text = msg
	total_label.text = "Total: " + str(total_score)

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
