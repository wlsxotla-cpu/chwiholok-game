extends Node2D

var alpha: float = 1.0
var radius: float = 80.0
var ring_progress: float = 0.0

func setup(r: float, maxed: bool = false) -> void:
	radius = r * (1.2 if maxed else 1.0)
	z_index = 5
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(_set_alpha, 1.0, 0.0, 0.32).set_delay(0.06)
	tween.tween_callback(queue_free)

func _set_progress(v: float) -> void:
	ring_progress = v
	queue_redraw()

func _set_alpha(v: float) -> void:
	alpha = v
	queue_redraw()

func _draw() -> void:
	var outer_r: float = radius * ring_progress
	var inner_r: float = radius * max(ring_progress - 0.22, 0.0)
	var col := Color(0.65, 0.82, 1.15, 0.55 * alpha)
	var core_col := Color(0.9, 0.95, 1.0, 0.9 * alpha)
	draw_arc(Vector2.ZERO, outer_r, 0.0, TAU, 40, col, 6.0, true)
	draw_arc(Vector2.ZERO, inner_r, 0.0, TAU, 40, core_col, 3.0, true)
	# small shield emblem flash at center that fades fast
	var emblem_scale: float = clamp(1.0 - ring_progress * 1.6, 0.0, 1.0)
	if emblem_scale > 0.0:
		var pts := PackedVector2Array([
			Vector2(0, -18), Vector2(14, -8), Vector2(14, 8), Vector2(0, 20), Vector2(-14, 8), Vector2(-14, -8),
		])
		var scaled := PackedVector2Array()
		for p in pts:
			scaled.append(p * emblem_scale)
		draw_colored_polygon(scaled, Color(0.85, 0.92, 1.0, 0.8 * alpha * emblem_scale))
