extends Node3D

@onready var cam = $Camera3D
@onready var building_entry_scene = preload("res://BuildingEntry.tscn")
@onready var knight_scene = preload("res://Knight.tscn")

const KingdomData = preload("res://KingdomData.gd")

var kingdoms: Array = []
var current_kingdom_idx: int = 0
var buildings: Dictionary = {}

var default_cam_pos = Vector3()
var default_cam_rot = Vector3()

func _ready():
        randomize()
        default_cam_pos = cam.global_position
        default_cam_rot = cam.rotation_degrees
        setup_kingdoms()
        print("Loading kingdoms...")
        load_kingdom(0)

func _on_KingdomButton_pressed():
        show_kingdom_mode()

func show_kingdom_mode():
        var tween = get_tree().create_tween()
        tween.tween_property(cam, "global_position", Vector3(0, 10, 10), 0.5)
        tween.tween_property(cam, "rotation_degrees", Vector3(-40, 0, 0), 0.15)
        show_building_ui()

func show_building_ui():
        $CanvasLayer/KingdomPanel.visible = true
        $CanvasLayer/KingdomButton.visible = false
        var kroot = get_node_or_null("KingdomRoot")
        if kroot:
                kroot.visible = true
        var list = $CanvasLayer/KingdomPanel/ScrollContainer/BuildingList
        for child in list.get_children():
                child.queue_free()
        for key in buildings.keys():
                var entry = building_entry_scene.instantiate()
                var base = key.replace(" ", "")
                entry.name = base
                list.add_child(entry)
                var label: Label = entry.get_node("Label")
                label.text = "%s (Lv. %d)" % [key, buildings[key]["level"]]
                var btn: Button = entry.get_node("Button")
                btn.pressed.connect(_on_BuildingButton_pressed.bind(key))
        update_all_building_buttons()

func hide_building_ui():
        $CanvasLayer/KingdomPanel.visible = false
        $CanvasLayer/KingdomButton.visible = true

func hide_kingdom_mode():
        hide_building_ui()
        var tween = get_tree().create_tween()
        tween.tween_property(cam, "global_position", default_cam_pos, 0.05)
        tween.tween_property(cam, "rotation_degrees", default_cam_rot, 0.25)

func _unhandled_input(event):
        if $CanvasLayer/KingdomPanel.visible and event is InputEventMouseButton:
                if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
                        var rect = $CanvasLayer/KingdomPanel.get_global_rect()
                        if not rect.has_point(event.position):
                                hide_kingdom_mode()

func setup_kingdoms():
        kingdoms.clear()
        var k1 = KingdomData.new()
        k1.name = "Kingdom 1"
        k1.scene_path = "res://kingdoms/Kingdom01.tscn"
        k1.buildings = KingdomData.kingdom1_buildings()
        kingdoms.append(k1)

        var k2 = KingdomData.new()
        k2.name = "Kingdom 2"
        k2.scene_path = "res://kingdoms/Kingdom02.tscn"
        k2.buildings = KingdomData.kingdom2_buildings()
        kingdoms.append(k2)

        var k3 = KingdomData.new()
        k3.name = "Kingdom 3"
        k3.scene_path = "res://kingdoms/Kingdom03.tscn"
        k3.buildings = KingdomData.kingdom3_buildings()
        kingdoms.append(k3)

func load_kingdom(index: int):
        if index >= kingdoms.size():
                return
        current_kingdom_idx = index
        var data: KingdomData = kingdoms[index]
        buildings.clear()
        for key in data.buildings.keys():
                var entry = data.buildings[key]
                buildings[key] = {
                        "level": entry.get("level", 0),
                        "costs": entry.get("costs", []).duplicate()
                }
        var old_root = get_node_or_null("KingdomRoot")
        if old_root:
                old_root.queue_free()
        var new_root: Node3D = null
        if data.scene_path != "":
                var scene = load(data.scene_path)
                print(data.scene_path)
                if scene:
                        new_root = scene.instantiate()
        if new_root == null:
                new_root = Node3D.new()
        new_root.name = "KingdomRoot"
        add_child(new_root)
        for key in buildings.keys():
                var label = get_building_label(key)
                if label:
                        label.text = "%s (Lv. %d)" % [key, buildings[key]["level"]]
        var buildings_node = new_root.get_node_or_null("Buildings")
        if buildings_node:
                for building in buildings_node.get_children():
                        building.visible = false
                        var key_name = building.name.replace("_", " ")
                        if buildings.has(key_name) and buildings[key_name]["level"] > 0:
                                building.visible = true
        connect_building_buttons()
        update_all_building_buttons()

func check_kingdom_complete():
        for key in buildings.keys():
                var data = buildings[key]
                if data["level"] < data["costs"].size():
                        return false
        load_kingdom(current_kingdom_idx + 1)
        return true

func get_building_button(key: String) -> Button:
        var base = key.replace(" ", "")
        return $CanvasLayer/KingdomPanel/ScrollContainer/BuildingList.get_node_or_null("%s/Button" % base)

func get_building_label(key: String) -> Label:
        var base = key.replace(" ", "")
        return $CanvasLayer/KingdomPanel/ScrollContainer/BuildingList.get_node_or_null("%s/Label" % base)

func connect_building_buttons():
        for key in buildings.keys():
                var btn = get_building_button(key)
                if btn:
                        if btn.pressed.get_connections():
                                for c in btn.pressed.get_connections():
                                        btn.pressed.disconnect(c.callable)
                        btn.pressed.connect(_on_BuildingButton_pressed.bind(key))

func _on_BuildingButton_pressed(key: String):
        if not buildings.has(key):
                return
        var data = buildings[key]
        var lvl = data["level"]
        if lvl < data["costs"].size():
                var cost = data["costs"][lvl]
                if CurrencyManager.spend_coins(cost):
                        data["level"] += 1
                        buildings[key] = data
                        var label = get_building_label(key)
                        if label:
                                label.text = "%s (Lv. %d)" % [key, data["level"]]
                        var node_name = key.replace(" ", "")
                        var buildings_node = $KingdomRoot.get_node_or_null("Buildings")
                        if buildings_node:
                                var build_node = buildings_node.get_node_or_null(node_name)
                                if build_node:
                                        build_node.visible = true
                                        if key == "Castle" and data["level"] == 1:
                                                var npc = knight_scene.instantiate()
                                                npc.global_position = build_node.global_position + Vector3(2, 0, 0)
                                                npc.follow_center_node = build_node
                                                npc.area_size = 5
                                                $KingdomRoot.add_child(npc)
                update_building_button(key, data)
                check_kingdom_complete()

func update_building_button(key: String, data: Dictionary):
        var btn = get_building_button(key)
        if btn == null:
                return
        var lvl = data["level"]
        if lvl < data["costs"].size():
                var cost = data["costs"][lvl]
                if lvl == 0:
                        btn.text = "Build (%d)" % cost
                else:
                        btn.text = "Upgrade (%d)" % cost
        else:
                btn.text = "MAXED"
                btn.disabled = true

func update_all_building_buttons():
        for key in buildings.keys():
                update_building_button(key, buildings[key])

