extends CharacterBody2D

# 1. State Machine Definitions
enum State { IDLE, PATROL, CHASE, ATTACK, HIT, DIE }
var current_state: State = State.IDLE

@export var walk_speed: float = 60.0
@export var chase_speed: float = 110.0
@export var dash_speed: float = 250.0 
@export var patrol_radius: float = 150.0

# 2. State Pacing Variables
var target_player: CharacterBody2D = null
var patrol_target: Vector2 = Vector2.ZERO
var spawn_position: Vector2 = Vector2.ZERO

@onready var detector: Area2D = $PlayerDectector
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationLink2D
@onready var hitbox: Area2D = $HitBox
@onready var patrol_timer: Timer = $PatrolTimer

func _ready() -> void:
	spawn_position = global_position
	patrol_target = spawn_position
	
	detector.body_entered.connect(_on_player_entered)
	detector.body_exited.connect(_on_player_exited)
	patrol_timer.timeout.connect(_on_patrol_timer_timeout)
	
	var hitbox_shape = hitbox.get_node_or_null("CollisionShape2D")
	if hitbox_shape:
		hitbox_shape.disabled = true
		
	enter_state(State.IDLE)

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.PATROL:
			process_patrol_state(delta)
		State.CHASE:
			process_chase_state(delta)
		State.ATTACK:
			pass
		State.HIT:
			velocity = Vector2.ZERO
		State.DIE:
			velocity = Vector2.ZERO

	move_and_slide()

# 3. State Management Transition Logic
func enter_state(new_state: State) -> void:
	current_state = new_state
	
	if current_state != State.ATTACK:
		var hitbox_shape = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_shape:
			hitbox_shape.disabled = true

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
			sprite.play("idle")
			patrol_timer.start(randf_range(1.5, 3.0))
		State.PATROL:
			generate_new_patrol_point()
			sprite.play("patrol")
		State.CHASE:
			patrol_timer.stop()
			sprite.play("chase")
		State.ATTACK:
			execute_blob_attack()
			sprite.play("attack")
		State.HIT:
			velocity = Vector2.ZERO
			sprite.play("hit")
		State.DIE:
			velocity = Vector2.ZERO
			sprite.play("die")

# --- BEHAVIOR 1: IDLE ---
func process_idle_state(delta: float) -> void:
	var squish = 1.0 + (sin(Time.get_ticks_msec() * 0.005) * 0.05)
	sprite.scale = Vector2(1.0 + (1.0 - squish), squish)

# --- BEHAVIOR 2: PATROL ---
func process_patrol_state(delta: float) -> void:
	var bounce = 1.0 + (abs(sin(Time.get_ticks_msec() * 0.01)) * 0.15)
	sprite.scale = Vector2(bounce, 2.0 - bounce)

	if global_position.distance_to(patrol_target) < 15.0:
		enter_state(State.IDLE)
		return

	var dir = global_position.direction_to(patrol_target).normalized()
	velocity = dir * walk_speed
	
	update_horizontal_facing(dir.x)
	sprite.play("patrol")

	if global_position.distance_to(spawn_position) > patrol_radius:
		patrol_target = spawn_position

func generate_new_patrol_point() -> void:
	var random_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(50.0, patrol_radius)
	patrol_target = spawn_position + random_offset

func _on_patrol_timer_timeout() -> void:
	if current_state == State.IDLE:
		enter_state(State.PATROL)

# --- BEHAVIOR 3: CHASE ---
func process_chase_state(delta: float) -> void:
	if not target_player:
		enter_state(State.IDLE)
		return

	var angry_bounce = 1.0 + (abs(sin(Time.get_ticks_msec() * 0.02)) * 0.2)
	sprite.scale = Vector2(angry_bounce, 2.0 - angry_bounce)

	var distance_to_player = global_position.distance_to(target_player.global_position)
	if distance_to_player <= 40.0:
		enter_state(State.ATTACK)
		return

	var dir = global_position.direction_to(target_player.global_position).normalized()
	velocity = dir * chase_speed
	
	update_horizontal_facing(dir.x)
	sprite.play("chase")

# --- BEHAVIOR 4: ATTACK (DASH & ACTIVE HITBOX) ---
func execute_blob_attack() -> void:
	if not target_player:
		enter_state(State.IDLE)
		return

	var attack_dir = global_position.direction_to(target_player.global_position).normalized()
	update_horizontal_facing(attack_dir.x)
	
	var attack_tween = create_tween()
	
	# 1. Wind-up compression squeeze
	attack_tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.15)
	
	# 2. DASH & HITBOX: Enable damage area and give a burst of speed
	attack_tween.tween_callback(func():
		var hitbox_shape = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_shape:
			hitbox_shape.disabled = false
			
		# Pass through player smoothly without sticking
		set_collision_mask_value(2, false)
		velocity = attack_dir * dash_speed
	)
	
	attack_tween.tween_property(sprite, "scale", Vector2(0.7, 1.3), 0.15)
	
	attack_tween.tween_callback(func():
		velocity = Vector2.ZERO
	)
	
	# 3. Recovery cooldown: Turn hitbox off, re-enable player collision, pause
	attack_tween.tween_interval(0.4)
	attack_tween.tween_callback(func():
		var hitbox_shape = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_shape:
			hitbox_shape.disabled = true
			
		set_collision_mask_value(2, true)
	)
	
	attack_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
	
	attack_tween.tween_callback(func():
		if target_player:
			enter_state(State.CHASE)
		else:
			enter_state(State.IDLE)
	)

# --- HELPER: LEFT/RIGHT FLIPPING ---
func update_horizontal_facing(x_dir: float) -> void:
	if x_dir > 0:
		sprite.flip_h = true
	elif x_dir < 0:
		sprite.flip_h = false

# 4. Sensor & Combat Callbacks
func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		target_player = body as CharacterBody2D
		if current_state != State.ATTACK and current_state != State.HIT:
			enter_state(State.CHASE)

func _on_player_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		if current_state != State.ATTACK and current_state != State.HIT:
			enter_state(State.IDLE)

func take_damage(amount: int) -> void:
	enter_state(State.HIT)
	var hit_tween = create_tween()
	hit_tween.tween_interval(0.3)
	hit_tween.tween_callback(func():
		die()
	)

func die() -> void:
	enter_state(State.DIE)
	await sprite.animation_finished
	queue_free()
