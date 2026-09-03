extends Node2D

var dir: Vector2 = Vector2.DOWN
var length: float = 260.0
var width: float = 36.0
var alpha: float = 1.0
var fill_color: Color = Color(1.9, 1.75, 1.35, 0.45)
var core_color: Color = Color(1.0, 0.95, 0.75, 0.9)
var core_width: float = 5.0

func setup(direction: Vector2, l: float, w: float, empowered: bool = false) -> void:
	dir = direction
	length = l
	width = w
	z_index = 5
	if empowered:
		width *= 1.6
		fill_color = Color(1.7, 1.1, 1.9, 0.5)
		core_color = Color(1.15, 0.85, 1.0, 0.95)
		core_width = 8.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.03)
	tween.tween_callback(queue_free)

func _set_alpha(v: float) -> void:
	alpha = v
	queue_redraw()

func _draw() -> void:
	var perp: Vector2 = dir.orthogonal() * (width / 2.0)
	var p1: Vector2 = perp
	var p2: Vector2 = dir * length + perp
	var p3: Vector2 = dir * length - perp
	var p4: Vector2 = -perp
	draw_colored_polygon([p1, p2, p3, p4], Color(fill_color.r, fill_color.g, fill_color.b, fill_color.a * alpha))
	draw_line(Vector2.ZERO, dir * length, Color(core_color.r, core_color.g, core_color.b, core_color.a * alpha), core_width)
