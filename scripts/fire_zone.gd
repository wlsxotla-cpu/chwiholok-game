extends Area2D

var damage: float = 4.0
var duration: float = 2.0
var tick_interval: float = 0.5
var tick_timer: float = 0.0
var ember_timer: float = 0.0
var radius: float = 40.0

const FIRE_TEXTURE_OUTER_RADIUS_PX := 27.5

@onready var sprite: Sprite2D = $Sprite2D

func setup(dmg: float, dur: float, r: float, maxed: bool = false) -> void:
	damage = dmg
	duration = dur
	radius = r
	var shape := CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape

	if maxed:
		sprite.modulate = Color(1.0, 0.6, 1.4, 1.0)
	sprite.scale = Vector2(0.15, 0.15)
	var base_scale: float = radius / FIRE_TEXTURE_OUTER_RADIUS_PX
	var land_tween := create_tween()
	land_tween.tween_property(sprite, "scale", Vector2(base_scale, base_scale), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var burst := preload("res://scenes/HitSpark.tscn").instantiate()
	get_parent().add_child(burst)
	burst.global_position = global_position

	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(sprite, "scale", Vector2(base_scale * 1.08, base_scale * 1.08), 0.35).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(sprite, "scale", Vector2(base_scale * 0.96, base_scale * 0.96), 0.35).set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		queue_free()
		return

	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = tick_interval
		for body in get_overlapping_bodies():
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(damage)

	ember_timer -= delta
	if ember_timer <= 0.0:
		ember_timer = 0.18
		_spawn_ember()

func _spawn_ember() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var ember := preload("res://scenes/Ember.tscn").instantiate()
	parent.add_child(ember)
	var offset: Vector2 = Vector2(randf_range(-radius, radius), randf_range(-radius, radius)) * 0.7
	ember.global_position = global_position + offset
