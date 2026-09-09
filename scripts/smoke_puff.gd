extends Node2D

var radius: float = 6.0
var alpha: float = 0.5

func _ready() -> void:
	z_index = 3
	var tween := create_tween()
	tween.tween_method(_update, 0.0, 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)

func _update(t: float) -> void:
	radius = 6.0 + t * 12.0
	alpha = 0.5 * (1.0 - t)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.52, 0.5, alpha))
	draw_circle(Vector2.ZERO, radius * 0.55, Color(0.75, 0.7, 0.65, alpha * 0.8))
