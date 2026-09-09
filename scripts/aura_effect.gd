extends Node2D

var radius: float = 70.0
var alpha: float = 1.0
var maxed: bool = false

func setup(r: float, is_maxed: bool = false) -> void:
	radius = r
	maxed = is_maxed
	z_index = 4
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

func _set_alpha(v: float) -> void:
	alpha = v
	queue_redraw()

func _draw() -> void:
	if maxed:
		draw_circle(Vector2.ZERO, radius, Color(0.95, 0.75, 0.25, 0.18 * alpha))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.85, 0.35, 0.75 * alpha), 4.5, true)
	else:
		draw_circle(Vector2.ZERO, radius, Color(0.55, 0.95, 0.65, 0.14 * alpha))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.7, 1.0, 0.7, 0.55 * alpha), 3.0, true)
