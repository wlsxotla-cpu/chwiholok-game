extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.rotation = randf_range(0.0, TAU)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.45, 0.45), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)
