extends Node3D

@export var value: int = 0
@export var icon_texture: Texture2D
@export var icon_type: String = ""
@export var flight_time: float = 0.5
@export var reveal_delay: float = 0.1

var label_assigned := false

func _ready():
    rotation_degrees = Vector3(0, 0, 180)
    update_label()
    update_icon()

func fly_to(target_pos: Vector3) -> void:
    var tween = get_tree().create_tween()
    tween.tween_property(self, "global_position", target_pos, flight_time)
        .set_trans(Tween.TRANS_LINEAR)
        .set_ease(Tween.EASE_IN_OUT)
    tween.tween_callback(func():
        var flip = get_tree().create_tween()
        flip.tween_interval(reveal_delay)
        flip.tween_property(self, "rotation_degrees:z", 0.0, 0.2)
            .set_ease(Tween.EASE_OUT)
            .set_trans(Tween.TRANS_QUAD)
        flip.tween_callback(_show_front)
    )

func _show_front():
    update_label()
    update_icon()

func update_label():
    if has_node("ValueLabel"):
        var label = $ValueLabel
        if label:
            label.text = str(value)
            label_assigned = true

func update_icon():
    if has_node("IconSprite"):
        var sprite = $IconSprite
        if sprite:
            sprite.texture = icon_texture
