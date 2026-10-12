extends CharacterBody2D

enum State { IDLE, PATROL, CHASE }
var current_state = State.IDLE

var patrol_speed = 50.0
var chase_speed = 100.0

var player_ref = null
var patrol_direction = Vector2.RIGHT
var idle_time_left = 2.0

func _physics_process(delta):
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			idle_time_left -= delta
			if idle_time_left <= 0:
				current_state = State.PATROL
				idle_time_left = 2.0
				
		State.PATROL:
			velocity = patrol_direction * patrol_speed
			if is_on_wall():
				patrol_direction *= -1 
				
		State.CHASE:
			if player_ref:
				var direction = (player_ref.global_position - global_position).normalized()
				velocity = direction * chase_speed

	move_and_slide()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player": 
		player_ref = body
		current_state = State.CHASE


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player_ref:
		player_ref = null
		current_state = State.PATROL
