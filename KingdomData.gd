extends Resource
class_name KingdomData

@export var name: String = ""
@export var scene_path: String = ""
@export var buildings: Dictionary = {}

#static func default_buildings() -> Dictionary:
	#return {
		#"Peon Hut": {"level": 0, "costs": [100, 200, 400, 800, 1600]},
		#"Card Shrine": {"level": 0, "costs": [150, 300, 600, 1200, 2400]},
		#"Barracks": {"level": 0, "costs": [200, 400, 800, 1600, 3200]},
		#"Farm": {"level": 0, "costs": [120, 240, 480, 960, 1920]},
		#"Blacksmith": {"level": 0, "costs": [250, 500, 1000, 2000, 4000]},
		#"Archery Range": {"level": 0, "costs": [180, 360, 720, 1440, 2880]},
		#"Stable": {"level": 0, "costs": [220, 440, 880, 1760, 3520]},
		#"Wizard Tower": {"level": 0, "costs": [300, 600, 1200, 2400, 4800]},
		#"Market": {"level": 0, "costs": [160, 320, 640, 1280, 2560]},
		#"Wall": {"level": 0, "costs": [140, 280, 560, 1120, 2240]},
		#}

static func kingdom1_buildings() -> Dictionary:
		return {
				"Castle": {"level": 0, "costs": [50, 100, 150, 250, 400]},
				"Barracks": {"level": 0, "costs": [60, 120, 240, 480, 960]},
				"Blacksmith": {"level": 0, "costs": [80, 160, 320, 640, 1280]},
				"Sawmill": {"level": 0, "costs": [40, 80, 160, 320, 640]},
				"Windmill": {"level": 0, "costs": [90, 180, 360, 720, 1440]},
				"Archery Range": {"level": 0, "costs": [70, 140, 280, 560, 1120]},
				"Mine": {"level": 0, "costs": [75, 150, 300, 600, 1200]},
				"Wizard Tower": {"level": 0, "costs": [100, 200, 400, 800, 1600]},
				"Market": {"level": 0, "costs": [65, 130, 260, 520, 1040]},
				"Wall": {"level": 0, "costs": [55, 110, 220, 440, 880]},
		}

static func kingdom2_buildings() -> Dictionary:
		return {
				"Peon Hut": {"level": 0, "costs": [200, 400, 800, 1600, 3200]},
				"Card Shrine": {"level": 0, "costs": [220, 440, 880, 1760, 3520]},
				"Barracks": {"level": 0, "costs": [250, 500, 1000, 2000, 4000]},
				"Farm": {"level": 0, "costs": [180, 360, 720, 1440, 2880]},
				"Blacksmith": {"level": 0, "costs": [300, 600, 1200, 2400, 4800]},
				"Archery Range": {"level": 0, "costs": [260, 520, 1040, 2080, 4160]},
				"Stable": {"level": 0, "costs": [240, 480, 960, 1920, 3840]},
				"Wizard Tower": {"level": 0, "costs": [320, 640, 1280, 2560, 5120]},
				"Market": {"level": 0, "costs": [210, 420, 840, 1680, 3360]},
				"Wall": {"level": 0, "costs": [190, 380, 760, 1520, 3040]},
		}

static func kingdom3_buildings() -> Dictionary:
		return {
				"Peon Hut": {"level": 0, "costs": [400, 800, 1600, 3200, 6400]},
				"Card Shrine": {"level": 0, "costs": [450, 900, 1800, 3600, 7200]},
				"Barracks": {"level": 0, "costs": [500, 1000, 2000, 4000, 8000]},
				"Farm": {"level": 0, "costs": [350, 700, 1400, 2800, 5600]},
				"Blacksmith": {"level": 0, "costs": [550, 1100, 2200, 4400, 8800]},
				"Archery Range": {"level": 0, "costs": [480, 960, 1920, 3840, 7680]},
				"Stable": {"level": 0, "costs": [520, 1040, 2080, 4160, 8320]},
				"Wizard Tower": {"level": 0, "costs": [600, 1200, 2400, 4800, 9600]},
				"Market": {"level": 0, "costs": [430, 860, 1720, 3440, 6880]},
				"Wall": {"level": 0, "costs": [370, 740, 1480, 2960, 5920]},
		}
