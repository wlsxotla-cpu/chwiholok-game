extends Node2D

enum State { TRAVEL, STABBING, DONE }

const STAB_INTERVAL := 0.09
const STAB_HIT_RADIUS := 34.0

var target_pos: Vector2 = Vector2.ZERO
var speed: float = 560.0
var damage: float = 10.0
var burst_radius: float = 90.0
var maxed: bool = false
var stab_count: int = 0
var stab_damage: float = 0.0

var state: int = State.TRAVEL
var stabs_done: int = 0
var stab_timer: float = 0.0
var stuck_enemy: Node = null

func setup(target: Vector2, dmg: float, radius: float, is_maxed: bool = false, stabs: int = 0, stab_dmg: float = 0.0) -> void:
	target_pos = target
	damage = dmg
	burst_radius = radius
	maxed = is_maxed
	stab_count = stabs
	stab_damage = stab_dmg
	rotation = (target_pos - global_position).angle()
	if maxed:
		scale *= 1.4

func _physics_process(delta: float) -> void:
	match state:
		State.TRAVEL:
			var to_target: Vector2 = target_pos - global_position
			var step: float = speed * delta
			if to_target.length() <= step:
				global_position = target_pos
				_acquire_stuck_enemy()
				if stab_count > 0:
					state = State.STABBING
					stab_timer = 0.0
				else:
					_burst()
			else:
				position += to_target.normalized() * step
		State.STABBING:
			if is_instance_valid(stuck_enemy):
				global_position = stuck_enemy.global_position
			stab_timer -= delta
			if stab_timer <= 0.0:
				stab_timer = STAB_INTERVAL
				_do_one_stab()
				stabs_done += 1
				if stabs_done >= stab_count:
					_burst()

func _acquire_stuck_enemy() -> void:
	var nearest: Node = null
	var nearest_dist: float = STAB_HIT_RADIUS
	for e in get_tree().get_nodes_in_group("enemies"):
		var d: float = global_position.distance_to(e.global_position)
		if d <= nearest_dist:
			nearest = e
			nearest_dist = d
	stuck_enemy = nearest

func _do_one_stab() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if is_instance_valid(stuck_enemy):
		stuck_enemy.take_damage(stab_damage)
	else:
		for e in get_tree().get_nodes_in_group("enemies"):
			if global_position.distance_to(e.global_position) <= STAB_HIT_RADIUS:
				e.take_damage(stab_damage)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	parent.add_child(fx)
	fx.global_position = global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	fx.modulate = Color(1.0, 1.85, 1.6, 1.0)
	fx.set_radius(STAB_HIT_RADIUS, false)

func _burst() -> void:
	state = State.DONE
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
