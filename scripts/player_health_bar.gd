extends Node2D

const WIDTH := 52.0
const HEIGHT := 7.0

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var player = get_parent()
	if player == null:
		return
	var ratio: float = clamp(player.health / max(player.max_health, 1.0), 0.0, 1.0)
	var bg_rect := Rect2(-WIDTH / 2.0, 0.0, WIDTH, HEIGHT)
	draw_rect(bg_rect, Color(0.08, 0.05, 0.04, 0.85))
	if ratio > 0.0:
		var fill_rect := Rect2(-WIDTH / 2.0, 0.0, WIDTH * ratio, HEIGHT)
		draw_rect(fill_rect, Color(0.82, 0.18, 0.16, 1.0))
	draw_rect(bg_rect, Color(0.0, 0.0, 0.0, 0.6), false, 1.5)
