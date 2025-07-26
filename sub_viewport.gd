extends Node

func _ready():
	var image = $WorldEnvironment.get_texture().get_image()
	image.save_png("res://mug_full_icon.png")
