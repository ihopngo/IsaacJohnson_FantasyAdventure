extends ProgressBar

@onready var player: CharacterBody2D = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_value = 100
	value = max_value
	
	player.health_changed.connect(update_health)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_health(new_health):
	value = new_health
