extends Node3D

@onready var card_scene = preload("res://Card3D.tscn")
@onready var card_row = $CardRow
@onready var card_spawn = $CardSpawn
@onready var draw_button = $CanvasLayer/DrawButton
@onready var hold_button = $CanvasLayer/HoldButton
@onready var score_label = $CanvasLayer/ScoreLabel
@onready var total_label = $CanvasLayer/TotalScoreLabel
@onready var restart_timer = $CanvasLayer/RestartTimer

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
    if icon_counts[icon_type] == 3:
        print("Collected three %s icons" % icon_type)

    var i = cards.size()
    var col = i % 4
    var row = i / 4
    card.global_position = card_spawn.global_position + Vector3(col * 0.5, row * 1.5, row + 2.0)

    card_row.add_child(card)
    cards.append(card)

    call_deferred("_finalize_card_position", card)

    if current_score == 21:
        total_score += 50
        end_game("🎉 Jackpot! +50", true)
    elif current_score > 21:
        end_game("💥 Bust!", false)

func _finalize_card_position(card):
    if not card_row.is_inside_tree():
        await get_tree().process_frame

    var i = cards.size() - 1
    var col = i % 4
    var row = i / 4
    var base_pos = card_row.global_transform.origin

    var spacing = Vector3(0.9, -0.5, 0)
    var offset = Vector3(col, row, 0) * spacing

    var rand_offset = Vector3(
        randf_range(-0.1, 0.1),
        randf_range(-0.1, 0.1),
        randf_range(-0.1, 0.1)
    )

    card.set_target_position(base_pos + offset + rand_offset)

    card.rotation_degrees = Vector3(
        randf_range(-10, 10),
        randf_range(-10, 10),
        randf_range(-10, 10)
    )

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
    draw_button.disabled = true
    hold_button.disabled = true
    restart_timer.start()
