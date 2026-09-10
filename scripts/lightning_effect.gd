extends Node2D

var alpha: float = 1.0
var maxed: bool = false
var points: PackedVector2Array = PackedVector2Array()
var branch_a: PackedVector2Array = PackedVector2Array()
var branch_b: PackedVector2Array = PackedVector2Array()
var branch_c: PackedVector2Array = PackedVector2Array()
var branch_d: PackedVector2Array = PackedVector2Array()

func setup(is_maxed: bool = false) -> void:
	maxed = is_maxed
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
	if maxed:
		var q1: int = points.size() / 4
		var q3: int = min(points.size() - 1, points.size() * 3 / 4)
		branch_c = PackedVector2Array([points[q1], points[q1] + Vector2(randf_range(35, 65), randf_range(10, 30))])
		branch_d = PackedVector2Array([points[q3], points[q3] + Vector2(randf_range(-65, -35), randf_range(10, 30))])

func _set_alpha(v: float) -> void:
	alpha = v
	queue_redraw()

func _draw() -> void:
	var core := Color(1.0, 1.0, 1.0, 0.95 * alpha)
	var glow := Color(0.35, 0.5, 1.1, 0.95 * alpha) if maxed else Color(0.65, 0.85, 1.0, 0.6 * alpha)
	var outer_scale: float = 2.6 if maxed else 1.0
	draw_polyline(points, glow, 10.0 * outer_scale, true)
	draw_polyline(points, core, 4.0 * (1.6 if maxed else 1.0), true)
	draw_polyline(branch_a, glow, 6.0 * outer_scale, true)
	draw_polyline(branch_a, core, 2.5, true)
	draw_polyline(branch_b, glow, 6.0 * outer_scale, true)
	draw_polyline(branch_b, core, 2.5, true)
	if maxed:
		draw_polyline(branch_c, glow, 6.0 * outer_scale, true)
		draw_polyline(branch_c, core, 2.5, true)
		draw_polyline(branch_d, glow, 6.0 * outer_scale, true)
		draw_polyline(branch_d, core, 2.5, true)
	draw_circle(Vector2.ZERO, 26.0 * outer_scale, glow.lerp(Color(1, 1, 1, glow.a), 0.4))
	draw_circle(Vector2.ZERO, 12.0 * (2.0 if maxed else 1.0), Color(1.0, 1.0, 1.0, 0.6 * alpha))
