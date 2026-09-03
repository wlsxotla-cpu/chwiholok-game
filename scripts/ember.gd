extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var rise: float = randf_range(14.0, 26.0)
	var drift: float = randf_range(-8.0, 8.0)
	var dur: float = randf_range(0.5, 0.8)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(drift, -rise), dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, dur)
	tween.tween_property(sprite, "scale", sprite.scale * 0.4, dur)
	tween.chain().tween_callback(queue_free)
