extends CharacterBody2D

@export var speed = 200
@onready var animated_sprite = $AnimatedSprite2D

var last_direction = "down"
var is_action_playing = false

signal health_changed(current_health, max_health)

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _physics_process(delta) -> void:
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * speed
		
	update_direction(input_direction)
	
	if not is_action_playing:
		update_movement_animation(input_direction)
		
	move_and_slide()

func update_direction(input_direction):
	if input_direction.y < 0:
		last_direction = "up"
	elif input_direction.y > 0:
		last_direction = "down"
	elif input_direction.x < 0:
		last_direction = "left"
	elif input_direction.x > 0:
		last_direction = "right"

func update_movement_animation(input_direction):
	if input_direction == Vector2.ZERO:
		animated_sprite.play("idle_" + last_direction)
	else:
		animated_sprite.play("run_" + last_direction)

func play_action_animation(action_name):
	is_action_playing = true
	animated_sprite.play(action_name + "_" + last_direction)

func take_damage(amount: int) -> void:
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)

func _unhandled_input(event):
	if event.is_action_pressed("attack"):
		play_action_animation("attack")
	elif event.is_action_pressed("test_hit"):
		play_action_animation("hit")
		take_damage(15)
	elif event.is_action_pressed("test_die"):
		play_action_animation("die")

func _on_animated_sprite_2d_animation_finished():
	is_action_playing = false
	
func die() -> void:
	print("Player died!")
