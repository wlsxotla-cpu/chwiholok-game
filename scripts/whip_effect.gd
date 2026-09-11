extends Node2D

var dir: Vector2 = Vector2.RIGHT
var length: float = 200.0
var alpha: float = 1.0
var line_color: Color = Color(0.85, 0.45, 1.0, 1.0)
var line_width: float = 5.0
var wave_amp: float = 26.0
var wave_count: float = 2.5
var tip_point: Vector2 = Vector2.ZERO

func setup(direction: Vector2, l: float, empowered: bool = false) -> void:
	dir = direction
	length = l
	z_index = 5
	if empowered:
		line_color = Color(1.15, 0.65, 1.35, 1.0)
		line_width = 8.0
	rotation = 0.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.05)
	tween.tween_callback(queue_free)

func _set_alpha(v: float) -> void:
	alpha = v
	queue_redraw()

func _draw() -> void:
	var perp: Vector2 = dir.orthogonal()
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 26
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var taper: float = 1.0 - t
		var wave: float = sin(t * wave_count * TAU) * wave_amp * taper
		var p: Vector2 = dir * (length * t) + perp * wave
		points.append(p)
		if i == steps:
			tip_point = p
	var col: Color = Color(line_color.r, line_color.g, line_color.b, line_color.a * alpha)
	draw_polyline(points, col, line_width, true)
	draw_polyline(points, Color(1.0, 0.95, 1.0, alpha * 0.8), line_width * 0.35, true)
	draw_circle(tip_point, line_width * 1.6, Color(1.0, 0.9, 1.0, alpha))
