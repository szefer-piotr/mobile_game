extends Node

var coins: int = 100000
var draws: int = 100
var gems: int = 0
var stars: int = 0

@onready var coin_label = null
@onready var draw_label = null
@onready var gem_label = null
@onready var star_label = null

func _ready():
	var root = get_tree().root
	if root.has_node("Main/CanvasLayer/CoinLabel"):
		coin_label = root.get_node("Main/CanvasLayer/CoinLabel")
	if root.has_node("Main/CanvasLayer/DrawLabel"):
		draw_label = root.get_node("Main/CanvasLayer/DrawLabel")
	if root.has_node("Main/CanvasLayer/GemLabel"):
		gem_label = root.get_node("Main/CanvasLayer/GemLabel")
	if root.has_node("Main/CanvasLayer/StarLabel"):
		star_label = root.get_node("Main/CanvasLayer/StarLabel")
	
	#update_coin_ui()
	update_all_ui()

func add_currency(type: String, amount: int):
	match type:
		"coins":
			coins += amount
		"draw":
			draws += amount
		"gems":
			gems += amount
		"stars":
			stars += amount
		_:
			push_error("Unknown currency type: " + type)

	update_all_ui()

func update_all_ui():
	if coin_label:
		coin_label.text = "🪙 Coins: " + str(coins)
	if draw_label:
		draw_label.text = "🎯 Draws: " + str(draws)
	if gem_label:
		gem_label.text = "💎 Gems: " + str(gems)
	if star_label:
		star_label.text = "⭐ Stars: " + str(stars)

func add_coins(amount: int):
	coins += amount
	update_coin_ui()

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		update_coin_ui()
		return true
	return false

func spend_draw(amount: int) -> bool:
	if draws >= amount:
		draws -= amount
		update_all_ui()
		return true
	return false

func update_coin_ui():
	if coin_label:
		coin_label.text = "🪙 Coins: " + str(coins)
