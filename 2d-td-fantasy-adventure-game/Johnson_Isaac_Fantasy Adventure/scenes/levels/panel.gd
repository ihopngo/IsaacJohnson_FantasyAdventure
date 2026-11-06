class_name Minimap
extends Panel

@export var player: Node2D
@export_range(0.01, 1.0, 0.01) var map_scale := 0.1
@export var dot_size := 3.0

@export_group("Colors")
@export var background_color := Color(0, 0, 0, 0.6)
@export var border_color := Color(1, 1, 1, 0.8)
@export var player_color := Color.WHITE
@export var monster_color := Color.RED
@export var coin_color := Color.GOLD

func _ready() -> void:
	clip_contents = true

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var map_rect := Rect2(Vector2.ZERO, size)
	draw_rect(map_rect, background_color)

	if player != null:
		_draw_group("coins", coin_color)
		_draw_group("monsters", monster_color)

	draw_circle(size / 2, dot_size + 1.0, player_color)
	draw_rect(map_rect, border_color, false, 2.0)

func _draw_group(group_name: String, color: Color) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if not node is Node2D:
			continue
		var map_pos := _world_to_map(node.global_position)
		if Rect2(Vector2.ZERO, size).has_point(map_pos):
			draw_circle(map_pos, dot_size, color)

func _world_to_map(world_pos: Vector2) -> Vector2:
	return (world_pos - player.global_position) * map_scale + size / 2
