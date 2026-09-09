extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

const RING_OUTER_RADIUS_PX := 60.8

func set_radius(radius: float, maxed: bool = false) -> void:
	var base_target: float = radius / RING_OUTER_RADIUS_PX
	var target: float = base_target * (1.55 if maxed else 1.0)
	sprite.scale = Vector2(target, target)
	sprite.rotation = randf_range(0.0, TAU)
	sprite.modulate = Color(1.6, 2.6, 3.2, 1.0) if maxed else Color(1.9, 1.7, 1.2, 1.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "rotation", sprite.rotation + deg_to_rad(120.0), 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var fade_target: Color = Color(0.7, 1.4, 2.2, 0.0) if maxed else Color(1.0, 0.85, 0.55, 0.0)
	tween.tween_property(sprite, "modulate", fade_target, 0.32 if maxed else 0.26).set_delay(0.05)
	tween.chain().tween_callback(queue_free)

	if maxed:
		var flash := Sprite2D.new()
		flash.texture = sprite.texture
		flash.z_index = sprite.z_index + 1
		add_child(flash)
		flash.scale = Vector2(base_target * 0.7, base_target * 0.7)
		flash.rotation = sprite.rotation
		flash.modulate = Color(3.0, 3.0, 3.0, 1.0)
		var flash_tween := create_tween()
		flash_tween.set_parallel(true)
		flash_tween.tween_property(flash, "scale", Vector2(base_target * 1.9, base_target * 1.9), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		flash_tween.tween_property(flash, "modulate:a", 0.0, 0.18)
		flash_tween.chain().tween_callback(flash.queue_free)
