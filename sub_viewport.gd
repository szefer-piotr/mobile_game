extends SubViewport

func _ready():
	await get_tree().process_frame # let the viewport render
	var image = get_texture().get_image()
	image.save_png("res://mug_full_icon.png")
