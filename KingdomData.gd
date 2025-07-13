extends Resource
class_name KingdomData

@export var name: String = ""
@export var scene_path: String = ""
@export var buildings: Dictionary = {}

static func default_buildings() -> Dictionary:
    return {
        "Peon Hut": {"level": 0, "costs": [100, 200, 400, 800, 1600]},
        "Card Shrine": {"level": 0, "costs": [150, 300, 600, 1200, 2400]},
        "Barracks": {"level": 0, "costs": [200, 400, 800, 1600, 3200]},
        "Farm": {"level": 0, "costs": [120, 240, 480, 960, 1920]},
        "Blacksmith": {"level": 0, "costs": [250, 500, 1000, 2000, 4000]},
        "Archery Range": {"level": 0, "costs": [180, 360, 720, 1440, 2880]},
        "Stable": {"level": 0, "costs": [220, 440, 880, 1760, 3520]},
        "Wizard Tower": {"level": 0, "costs": [300, 600, 1200, 2400, 4800]},
        "Market": {"level": 0, "costs": [160, 320, 640, 1280, 2560]},
        "Wall": {"level": 0, "costs": [140, 280, 560, 1120, 2240]},
    }
