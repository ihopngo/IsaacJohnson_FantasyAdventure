extends Area2D

@onready var player = $".."
var damage_amount = 20

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		if player.has_method("take_damage"):
			player.take_damage(damage_amount)
