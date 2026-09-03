extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

const RING_OUTER_RADIUS_PX := 60.8

func set_radius(radius: float) -> void:
	var target: float = radius / RING_OUTER_RADIUS_PX
	sprite.scale = Vector2(target, target)
	sprite.rotation = randf_range(0.0, TAU)
	sprite.modulate = Color(1.9, 1.7, 1.2, 1.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "rotation", sprite.rotation + deg_to_rad(120.0), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.85, 0.55, 0.0), 0.26).set_delay(0.05)
	tween.chain().tween_callback(queue_free)
