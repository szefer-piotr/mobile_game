extends Node3D

@onready var card_scene = preload("res://Card3D.tscn")
@onready var card_row = $CardRow
@onready var camera: Camera3D = $Camera3D
@onready var card_spawn = $Camera3D/CardSpawn
@onready var draw_button = $CanvasLayer/DrawButton
@onready var hold_button = $CanvasLayer/HoldButton
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var total_label = $CanvasLayer/TotalScoreLabel
@onready var restart_timer = $CanvasLayer/RestartTimer
@onready var score_bar = $CanvasLayer/ScoreProgressBar
@onready var score_bar_label = $CanvasLayer/ScoreProgressLabel
@onready var auto_draw_timer = $CanvasLayer/AutoDrawTimer
@onready var auto_toggle_button = $CanvasLayer/AutoToggleButton
@onready var reward_popup = $CanvasLayer/RewardReadyPopup
@onready var kingdom_button = $CanvasLayer/KingdomButton
@onready var icon_bar_container = $CanvasLayer/IconBars
@onready var icon_bar_template = $CanvasLayer/IconBars/IconBarTemplate
@onready var icon_bars = {}

var current_score = 0
var total_score = 0
var cards = []
var icon_counts: Dictionary = {}
var available_icons := ["attack", "shield", "gold", "pillage", "special_item"]
var icon_textures = {
	"attack": preload("res://item_icons/attack_256_256.png"),
	"shield": preload("res://item_icons/shield_256_256.png"),
	"gold": preload("res://item_icons/gold_256_256.png"),
	"pillage": preload("res://item_icons/pillage_256_256.png"),
	"special_item": preload("res://item_icons/special_item_256_256.png"),
}

var current_path_name: String = ""
var reward_path: Array = []
var current_reward_index: int = 0
var progress_towards_current: int = 0

var reward_message_queue: Array[String] = []
var reward_popup_active: bool = false

var displayed_score_value: float = 0.0
var target_score_bar_value: float = 0.0
var fill_speed = 6.0

var auto_draw_enabled = false
var force_draw_until_15 = false

func _ready():
	randomize()
	if restart_timer:
		restart_timer.timeout.connect(_on_restart_timer_timeout)
	if auto_draw_timer:
		auto_draw_timer.timeout.connect(_on_AutoDrawTimer_timeout)
	if auto_toggle_button:
		auto_toggle_button.text = "Auto: OFF"
		auto_toggle_button.pressed.connect(_on_AutoToggleButton_pressed)
	if score_bar:
		score_bar.min_value = 0
		score_bar.max_value = 100
		score_bar.value = 0
	displayed_score_value = 0.0
	target_score_bar_value = 0.0
	if reward_popup:
		reward_popup.visible = false
	if kingdom_button:
		kingdom_button.pressed.connect(_on_KingdomButton_pressed)
	_setup_icon_bars()
	load_reward_path("starter_path")
	reset_game()


func _setup_icon_bars():
	icon_bar_template.hide()
	for icon in available_icons:
		var bar = icon_bar_template.duplicate()
		var texture_rect: TextureRect = bar.get_node("Icon")
		if icon_textures.has(icon):
			texture_rect.texture = icon_textures[icon]
		texture_rect.custom_minimum_size = Vector2(32, 32)      # desired size
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE   # let it scale
		var progress: ProgressBar = bar.get_node("ProgressBar")
		progress.max_value = 4
		progress.value = 0
		icon_bar_container.add_child(bar)
		icon_bars[icon] = progress


func _update_icon_bar(icon_type: String):
	if not icon_bars.has(icon_type):
		return
	var bar: ProgressBar = icon_bars[icon_type]
	var count = icon_counts.get(icon_type, 0)
	bar.value = min(count, 4)
	bar.get_parent().visible = true


func _highlight_icon_bar(icon_type: String):
	if not icon_bars.has(icon_type):
		return
	var bar_parent: Control = icon_bars[icon_type].get_parent()
	var tween = get_tree().create_tween()
	tween.tween_property(bar_parent, "modulate", Color(1, 1, 0), 0.2)
	tween.tween_property(bar_parent, "modulate", Color(1, 1, 1), 0.6)


func _process(delta):
	if score_bar:
		if abs(displayed_score_value - target_score_bar_value) > 0.1:
			displayed_score_value = lerp(displayed_score_value, target_score_bar_value, delta * fill_speed)
			score_bar.value = round(displayed_score_value)
		else:
			displayed_score_value = target_score_bar_value
			score_bar.value = round(target_score_bar_value)


func draw_card():
	if current_score == 0:
		if not CurrencyManager.spend_draw(1):
			return
	var value = randi() % 6 + 1
	current_score += value
	hold_button.disabled = current_score < 18
	score_label.text = "Score: " + str(current_score)

	var card = card_scene.instantiate()
	card.value = value
	var icon_type = available_icons[randi() % available_icons.size()]
	if icon_textures.has(icon_type):
		card.icon_texture = icon_textures[icon_type]
	if "icon_type" in card:
		card.icon_type = icon_type
	icon_counts[icon_type] = icon_counts.get(icon_type, 0) + 1
	_update_icon_bar(icon_type)
	if icon_counts[icon_type] == 4:
		show_reward_popup("Collected four %s icons!" % icon_type)
		_highlight_icon_bar(icon_type)

	var spawn_transform = _get_spawn_transform()
	spawn_transform.basis = spawn_transform.basis.rotated(Vector3(1,0,0), -45)
	if card_spawn:
		card_spawn.global_transform = spawn_transform
	if card:
		card_row.add_child(card)
		card.global_transform = spawn_transform
		card.spawn_pos = spawn_transform.origin
		card.rotation_degrees = Vector3(0, 0, 180)
		var idx := cards.size()
		cards.append(card)
		call_deferred("_finalize_card_position", card, spawn_transform, idx)

	if current_score == 21:
		total_score += 50
		end_game("🎉 Jackpot! +50", true)
	elif current_score > 21:
		end_game("💥 Bust!", false)


func _get_spawn_transform() -> Transform3D:
	var viewport_rect: Rect2i = get_viewport().get_visible_rect()
	var viewport_size: Vector2 = Vector2(viewport_rect.size)  # cast from Vector2i
	var screen_pos: Vector2 = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.85)

	var origin: Vector3 = camera.project_ray_origin(screen_pos)
	var dir: Vector3 = camera.project_ray_normal(screen_pos)

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, origin + dir * 60.0
	)
	# params.collision_mask = 1 << 2  # (optional) if your table is on a specific layer

	var hit: Dictionary = space_state.intersect_ray(params)

	var spawn_pos: Vector3
	if not hit.is_empty():
		spawn_pos = (hit["position"] as Vector3) + Vector3(0, 0.2, 0)
	else:
		spawn_pos = origin + dir * 2.0

	return Transform3D(camera.global_transform.basis, spawn_pos)


func _finalize_card_position(card, spawn_transform: Transform3D, idx):
	if not card_row.is_inside_tree():
		await get_tree().process_frame
	card.global_transform = spawn_transform
	const CARDS_PER_ROW: int = 4
	const SPACING_X: float = 0.6
	const SPACING_Z: float = 0.8
	var col: int = idx % CARDS_PER_ROW
	var row: int = idx / CARDS_PER_ROW
	var base: Transform3D = card_row.global_transform
	var origin: Vector3 = base.origin
	var right: Vector3 = (-base.basis.x).normalized()
	var forward: Vector3 = (-base.basis.z).normalized()    # local +forward
	var leftmost: Vector3 = origin - right * ((CARDS_PER_ROW - 1) * 0.5 * SPACING_X)
	var target_pos: Vector3 = leftmost + right * (col * SPACING_X) + forward * (row * SPACING_Z)
	card.fly_to(target_pos)



func _on_DrawButton_pressed():
	draw_button.disabled = true
	hold_button.disabled = true
	draw_card()

	while current_score < 15 and restart_timer.is_stopped():
		await get_tree().create_timer(0.1).timeout
		draw_card()
	if restart_timer.is_stopped():
		draw_button.disabled = false
		hold_button.disabled = current_score < 18

func _on_HoldButton_pressed():
	if current_score >= 18:
		total_score += current_score
		end_game("👍 Scored " + str(current_score), true)
	else:
		end_game("😐 Low score...", false)

func end_game(msg: String, gave_reward: bool):
	total_label.text = "Total: " + str(total_score)

	var reward = 0
	if current_score == 21:
		reward = 50
	elif current_score >= 18 and current_score < 21:
		reward = current_score
	else:
		reward = 0
	add_score(reward)

	draw_button.disabled = true
	hold_button.disabled = true
	force_draw_until_15 = false
	if auto_draw_timer:
		auto_draw_timer.stop()
	restart_timer.start()

func reset_game():
	current_score = 0
	icon_counts.clear()
	for icon in available_icons:
		icon_counts[icon] = 0
	cards.clear()
	score_label.text = "Score: 0"
	draw_button.disabled = false
	hold_button.disabled = true
	force_draw_until_15 = false
	if auto_draw_timer:
		auto_draw_timer.stop()
	for c in card_row.get_children():
		c.queue_free()
	for bar in icon_bars.values():
		bar.value = 0
		bar.get_parent().visible = false

func add_score(amount: int):
	progress_towards_current += amount

	while current_reward_index < reward_path.size():
		var reward = reward_path[current_reward_index]
		var required = reward["points_needed"]
		if progress_towards_current < required:
			break
		progress_towards_current -= required
		give_reward(reward)
		current_reward_index += 1
	update_score_bar()
	if current_reward_index >= reward_path.size():
		load_reward_path("kingdom_path")

func give_reward(reward: Dictionary):
	CurrencyManager.add_currency(reward["reward_type"], reward["amount"])
	var text = "Recieved %d %s!" % [reward["amount"], reward["reward_type"]]
	show_reward_popup(text)

func show_reward_popup(text: String = ""):
	if reward_popup == null:
		return
	if text != "":
		reward_message_queue.append(text)
	if reward_popup_active:
		return
	_display_next_reward_popup()

	
func _display_next_reward_popup():
	if reward_message_queue.is_empty():
		reward_popup_active = false
		return
	reward_popup_active = true
	reward_popup.text = reward_message_queue.pop_front()
	reward_popup.visible = true
	reward_popup.modulate = 0
		
	var tween = get_tree().create_tween()
	tween.tween_property(reward_popup, "modulate:a", 1.0, 0.4).as_relative()
	tween.tween_interval(1.2)
	tween.tween_property(reward_popup, "modulate:a", -1.0, 0.5).as_relative()
	tween.tween_callback(reward_popup.hide)
	tween.tween_callback(_display_next_reward_popup)


func update_score_bar():
	if score_bar == null or score_bar_label == null:
		return
	if current_reward_index >= reward_path.size():
		target_score_bar_value = score_bar.max_value
		score_bar_label.text = "Path Complete!"
		return

	var reward = reward_path[current_reward_index]
	var current_goal = reward["points_needed"]
	var ratio = float(progress_towards_current) / current_goal
	target_score_bar_value = ratio * score_bar.max_value

	var reward_type = reward.get("reward_type", "")
	var reward_amount = reward.get("amount", 0)
	score_bar_label.text = "%d / %d -> %s %d" % [
		progress_towards_current,
		current_goal,
		reward_type,
		reward_amount
	]

func load_reward_path(path_name: String):
	var file_path = "res://reward_paths/%s.json" % path_name
	if not FileAccess.file_exists(file_path):
		push_error("Reward path not found: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = file.get_as_text()
	var result = JSON.parse_string(data)

	if typeof(result) == TYPE_ARRAY:
		reward_path = result
		current_path_name = path_name
		current_reward_index = 0
		progress_towards_current = 0
		update_score_bar()
		print("Loaded reward path: ", path_name)
	else:
		push_error("Failed to parse JSON reward path.")

func start_auto_draw():
	if current_score < 15:
		draw_button.disabled = true
		hold_button.disabled = true
		if auto_draw_timer:
			auto_draw_timer.start()
	else:
		if auto_draw_timer:
			auto_draw_timer.stop()
		draw_button.disabled = false
		hold_button.disabled = current_score < 18

func _on_restart_timer_timeout():
	reset_game()
	if auto_draw_enabled:
		start_auto_draw()

func _on_AutoDrawTimer_timeout():
	if not auto_draw_enabled:
		if auto_draw_timer:
			auto_draw_timer.stop()
		return

	draw_card()
	hold_button.disabled = current_score < 18
	if current_score >= 21:
		return

	if current_score >= 18:
		if randi() % 2 == 0:
			_on_HoldButton_pressed()
		else:
			if auto_draw_timer:
				auto_draw_timer.start()
	else:
		if auto_draw_timer:
			auto_draw_timer.start()

func _on_AutoToggleButton_pressed():
	auto_draw_enabled = !auto_draw_enabled
	if auto_draw_enabled:
		auto_toggle_button.text = "Auto: ON"
		start_auto_draw()
	else:
		if auto_draw_timer:
			auto_draw_timer.stop()
		draw_button.disabled = false
		hold_button.disabled = current_score < 18
		auto_toggle_button.text = "Auto: OFF"

func _on_KingdomButton_pressed():
	if restart_timer:
		restart_timer.stop()
	reset_game()
	get_tree().change_scene_to_file("res://Main.tscn")
			
