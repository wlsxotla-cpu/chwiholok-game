extends Node2D

var alpha: float = 1.0
var radius: float = 70.0
var dir: Vector2 = Vector2.DOWN
var half_angle: float = deg_to_rad(50.0)

func setup(direction: Vector2, r: float, maxed: bool = false) -> void:
	dir = direction
	radius = r
	z_index = 5
	if maxed:
		radius *= 1.25
		half_angle = deg_to_rad(58.0)
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.02)
	tween.tween_callback(queue_free)

func _set_alpha(v: float) -> void:
	alpha = v
	queue_redraw()

func _draw() -> void:
	var base_angle: float = dir.angle()
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	var steps: int = 18
	for i in range(steps + 1):
		var a: float = base_angle - half_angle + (2.0 * half_angle) * (float(i) / float(steps))
		points.append(Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, Color(0.55, 0.75, 1.1, 0.42 * alpha))
	draw_polyline(points, Color(0.85, 0.93, 1.0, 0.9 * alpha), 3.5, true)
	draw_circle(Vector2.ZERO, 10.0, Color(0.7, 0.85, 1.15, 0.55 * alpha))
