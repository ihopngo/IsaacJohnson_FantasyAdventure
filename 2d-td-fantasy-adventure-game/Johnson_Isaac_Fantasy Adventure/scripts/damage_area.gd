class_name Hitbox
extends Area2D

@export var damage: int = 15

func _init() -> void:
	# Configure this area strictly for offensive scanning
	monitoring = true
	monitorable = false
