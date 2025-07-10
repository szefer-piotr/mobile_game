extends Node

var coins: int = 0
@onready var coin_label = null

func _ready():
	if coin_label == null and get_tree().root.has_node("Main/CanvasLayer/CoinLabel"):
		coin_label = get_tree().root.get_node("Main/CanvasLayer/CoinLabel")
	update_coin_ui()

func add_coins(amount: int):
	coins += amount
	update_coin_ui()

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		update_coin_ui()
		return true
	return false

func update_coin_ui():
	if coin_label:
		coin_label.text = "🪙 Coins: " + str(coins)
