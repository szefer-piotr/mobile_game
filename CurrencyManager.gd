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
	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))
	_on_scene_changed(get_tree().current_scene)

func _on_scene_changed(scene):
	var root = get_tree().root
	var base_path = "Main/CanvasLayer"
	if scene and scene.name == "CardTable":
		base_path = "CardTable/CanvasLayer"
	coin_label = root.get_node_or_null(base_path + "/CoinLabel")
	draw_label = root.get_node_or_null(base_path + "/DrawLabel")
	gem_label = root.get_node_or_null(base_path + "/GemLabel")
	star_label = root.get_node_or_null(base_path + "/StarLabel")
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
