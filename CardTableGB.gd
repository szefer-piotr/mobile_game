extends Node3D

@onready var card_dealer = $CardDeck
@onready var deal_button = $CanvasLayer/DealButton
@onready var reset_button = $CanvasLayer/ResetButton

func _ready():
	deal_button.pressed.connect(_on_deal_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)

func _on_deal_button_pressed():
	deal_button.disabled = true
	card_dealer.deal_cards()

func _on_reset_button_pressed():
	deal_button.disabled = false
	card_dealer.reset_cards()
