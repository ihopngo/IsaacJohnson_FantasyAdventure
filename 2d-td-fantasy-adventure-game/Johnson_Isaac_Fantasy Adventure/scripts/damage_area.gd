extends Area2D

@onready var player = $".."
var damage_amount = 20

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		player.current_health -= damage_amount
		
		if player.current_health < 0:
			player.current_health = 0
			
		player.health_changed.emit(player.current_health)
