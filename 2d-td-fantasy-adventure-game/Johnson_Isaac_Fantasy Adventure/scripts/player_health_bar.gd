extends TextureProgressBar

@export var animation_duration: float = 0.25

var health_tween: Tween

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	max_value = max_health
	
	if health_tween and health_tween.is_running():
		health_tween.kill()

	health_tween = create_tween()
	
	health_tween.tween_property(self, "value", current_health, animation_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
