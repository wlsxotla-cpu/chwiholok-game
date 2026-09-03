extends Node2D

var radius: float = 70.0
var alpha: float = 1.0

func setup(r: float) -> void:
	radius = r
	z_index = 4
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_alpha, 1.0, 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

func _set_alpha(v: float) -> void:
	alpha = v
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.95, 0.65, 0.14 * alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.7, 1.0, 0.7, 0.55 * alpha), 3.0, true)
