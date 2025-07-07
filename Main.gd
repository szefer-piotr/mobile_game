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

var current_score = 0
var total_score = 0
var cards = []

func _ready():
	restart_timer.timeout.connect(_on_restart_timer_timeout)
	reset_game()

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

	# spread cards along x axis
	var target_x = float(cards.size()) * 1.5
	card.target_position = card_row.global_transform.origin + Vector3(target_x, 0, 0)

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

func end_game(msg, gave_reward):
	result_label.text = msg
	total_label.text = "Total: " + str(total_score)
	draw_button.disabled = true
	hold_button.disabled = true
	restart_timer.start()

func _on_restart_timer_timeout():
	reset_game()
