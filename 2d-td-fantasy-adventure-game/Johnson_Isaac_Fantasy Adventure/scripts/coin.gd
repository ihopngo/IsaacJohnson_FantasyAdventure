extends Area2D


func _on_body_entered(body: Node2D) -> void:
# Check if the body entering the coin is the player
	if body.name == "Player": 
		queue_free()
