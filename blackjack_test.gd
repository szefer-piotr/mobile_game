extends Control

var current_score = 0
var cards = []

func _ready():
	reset_game()

func reset_game():
	current_score = 0
	cards.clear()
	$ScoreLabel.text = "Score: 0"
	$ResultLabel.text = ""
	for child in $CardContainer.get_children():
		$CardContainer.remove_child(child)
		child.queue_free()
	$DrawButton.disabled = false
	$HoldButton.disabled = false

func _on_DrawButton_pressed():
	var value = randi() % 6 + 1  # Random number 1–6
	cards.append(value)
	current_score += value

	var card_label = Label.new()
	card_label.text = str(value)
	$CardContainer.add_child(card_label)

	$ScoreLabel.text = "Score: " + str(current_score)

	if current_score == 21:
		end_game("🎉 Jackpot! You hit 21!")
	elif current_score > 21:
		end_game("💥 Bust! You went over 21.")

func _on_HoldButton_pressed():
	if current_score < 15:
		end_game("😐 Low score. Try again.")
	elif current_score < 21:
		end_game("👍 Good job! You scored " + str(current_score) + ".")
	# Note: exact 21 already handled in draw

func end_game(message):
	$ResultLabel.text = message
	$DrawButton.disabled = true
	$HoldButton.disabled = true
	# Optionally: Add restart button or auto-reset delay

# Optional: You can add this method to reset the game after a delay
# func _on_Timer_timeout():
#     reset_game()
