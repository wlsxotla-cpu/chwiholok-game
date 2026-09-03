extends Node2D

var alpha: float = 1.0
var points: PackedVector2Array = PackedVector2Array()
var branch_a: PackedVector2Array = PackedVector2Array()
var branch_b: PackedVector2Array = PackedVector2Array()

func setup() -> void:
	z_index = 7
	_build_bolt()
	var tween := create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.15, 0.05)
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

func _build_bolt() -> void:
	var y := -300.0
	var x := 0.0
	points.append(Vector2(x, y))
	while y < 0.0:
		y += randf_range(32.0, 58.0)
		x += randf_range(-20.0, 20.0)
		points.append(Vector2(x, min(y, 0.0)))
	var mid: int = points.size() / 2
	branch_a = PackedVector2Array([points[mid], points[mid] + Vector2(randf_range(20, 45), randf_range(20, 40))])
	branch_b = PackedVector2Array([points[max(mid - 2, 0)], points[max(mid - 2, 0)] + Vector2(randf_range(-45, -20), randf_range(15, 35))])

func _set_alpha(v: float) -> void:
	alpha = v
	queue_redraw()

func _draw() -> void:
	var core := Color(1.0, 1.0, 1.0, 0.95 * alpha)
	var glow := Color(0.65, 0.85, 1.0, 0.6 * alpha)
	draw_polyline(points, glow, 10.0, true)
	draw_polyline(points, core, 4.0, true)
	draw_polyline(branch_a, glow, 6.0, true)
	draw_polyline(branch_a, core, 2.5, true)
	draw_polyline(branch_b, glow, 6.0, true)
	draw_polyline(branch_b, core, 2.5, true)
	draw_circle(Vector2.ZERO, 26.0, Color(0.7, 0.88, 1.0, 0.35 * alpha))
	draw_circle(Vector2.ZERO, 12.0, Color(1.0, 1.0, 1.0, 0.6 * alpha))
