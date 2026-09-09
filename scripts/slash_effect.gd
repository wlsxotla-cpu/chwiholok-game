extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

const RING_OUTER_RADIUS_PX := 60.8

func set_radius(radius: float, maxed: bool = false) -> void:
	var target: float = (radius / RING_OUTER_RADIUS_PX) * (1.18 if maxed else 1.0)
	sprite.scale = Vector2(target, target)
	sprite.rotation = randf_range(0.0, TAU)
	sprite.modulate = Color(2.4, 1.3, 2.0, 1.0) if maxed else Color(1.9, 1.7, 1.2, 1.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "rotation", sprite.rotation + deg_to_rad(120.0), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var fade_target: Color = Color(1.3, 0.75, 1.1, 0.0) if maxed else Color(1.0, 0.85, 0.55, 0.0)
	tween.tween_property(sprite, "modulate", fade_target, 0.26).set_delay(0.05)
	tween.chain().tween_callback(queue_free)
