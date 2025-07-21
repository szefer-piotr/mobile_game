extends Control

var current_score = 0
var total_score = 0
var cards = []
var auto_draw_enabled := false

@onready var auto_draw_timer = $AutoDrawTimer


func _ready():
	$RestartTimer.timeout.connect(self._on_RestartTimer_timeout)
	auto_draw_timer.timeout.connect(_on_AutoDrawTimer_timeout)
	reset_game()

func reset_game():
	current_score = 0
	cards.clear()
	$ScoreLabel.text = "Score: 0"
	$ResultLabel.text = ""
	# … remove existing cards …
	$DrawButton.disabled = false
	$HoldButton.disabled = false
	if auto_draw_enabled:
		start_auto_draw()


func start_auto_draw():
	if not auto_draw_enabled:
		return
	if current_score < 15:
		$DrawButton.disabled = true
		$HoldButton.disabled = true
		auto_draw_timer.start()
	else:
		auto_draw_timer.stop()
		$DrawButton.disabled = false
		$HoldButton.disabled = false


func draw_card():
	var value = randi() % 6 + 1  # Random 1–6
	cards.append(value)
	current_score += value

	var card_label = Label.new()
	card_label.text = str(value)
	$CardContainer.add_child(card_label)

	$ScoreLabel.text = "Score: " + str(current_score)

	if current_score == 21:
		total_score += 50
		end_game("🎉 Jackpot! +50", true)
	elif current_score > 21:
		end_game("💥 Bust!", false)

func _on_AutoDrawTimer_timeout():
	if current_score < 15:
		draw_card()
	if current_score >= 15:
		$DrawButton.disabled = false
		$HoldButton.disabled = false
		auto_draw_timer.stop()

func _on_DrawButton_pressed():
	draw_card()

func _on_HoldButton_pressed():
	if current_score >= 18:
		var reward = current_score  # e.g. 18 = +18 coins
		total_score += reward
		end_game("👍 Scored " + str(current_score) + "! +" + str(reward), true)
	else:
		end_game("😐 Low score...", false)

func end_game(message: String, reward_given: bool):
	$ResultLabel.text = message
	$TotalScoreLabel.text = "Total: " + str(total_score)

	$DrawButton.disabled = true
	$HoldButton.disabled = true
	auto_draw_timer.stop()

	$RestartTimer.start()  # wait 1.5s, then reset

func _on_RestartTimer_timeout():
	reset_game()
