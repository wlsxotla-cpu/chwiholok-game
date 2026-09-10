extends Node2D

var target_pos: Vector2 = Vector2.ZERO
var speed: float = 560.0
var damage: float = 10.0
var burst_radius: float = 90.0
var maxed: bool = false

func setup(target: Vector2, dmg: float, radius: float, is_maxed: bool = false) -> void:
	target_pos = target
	damage = dmg
	burst_radius = radius
	maxed = is_maxed
	rotation = (target_pos - global_position).angle()
	if maxed:
		scale *= 1.4

func _physics_process(delta: float) -> void:
	var to_target: Vector2 = target_pos - global_position
	var step: float = speed * delta
	if to_target.length() <= step:
		global_position = target_pos
		_burst()
		return
	position += to_target.normalized() * step

func _burst() -> void:
	var parent := get_parent()
	if parent == null:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(e.global_position) <= burst_radius:
			e.take_damage(damage)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	parent.add_child(fx)
	fx.global_position = global_position
	fx.modulate = Color(1.6, 1.3, 0.5, 1.0)
	fx.set_radius(burst_radius, maxed)
	queue_free()
