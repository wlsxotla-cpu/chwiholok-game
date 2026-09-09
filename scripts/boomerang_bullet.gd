extends Area2D

const SPEED := 380.0
const MAX_DIST := 260.0
const SPIN_SPEED := 14.0

var dir: Vector2 = Vector2.RIGHT
var damage: float = 8.0
var traveled: float = 0.0
var returning: bool = false
var owner_player: Node2D
var hit_enemies: Dictionary = {}
var maxed: bool = false
var smoke_timer: float = 0.0

func setup(player: Node2D, direction: Vector2, dmg: float, is_maxed: bool = false) -> void:
	owner_player = player
	dir = direction
	damage = dmg
	rotation = dir.angle()
	maxed = is_maxed
	if maxed:
		modulate = Color(1.0, 1.9, 2.3, 1.0)
		scale *= 2.1

func _physics_process(delta: float) -> void:
	if maxed and not returning:
		smoke_timer -= delta
		if smoke_timer <= 0.0:
			smoke_timer = 0.035
			_spawn_smoke()
	if not returning:
		var step: float = SPEED * delta
		position += dir * step
		traveled += step
		rotation += delta * (SPIN_SPEED * 0.15 if maxed else SPIN_SPEED)
		if traveled >= MAX_DIST:
			returning = true
			hit_enemies.clear()
	else:
		if owner_player == null or not is_instance_valid(owner_player):
			queue_free()
			return
		var to_owner: Vector2 = owner_player.global_position - global_position
		if to_owner.length() < 20.0:
			queue_free()
			return
		position += to_owner.normalized() * SPEED * delta
		rotation += delta * (SPIN_SPEED * 0.15 if maxed else SPIN_SPEED)

func _spawn_smoke() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var puff := preload("res://scenes/SmokePuff.tscn").instantiate()
	parent.add_child(puff)
	puff.global_position = global_position - dir * 14.0 + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage") and not hit_enemies.has(body):
		body.call_deferred("take_damage", damage)
		hit_enemies[body] = true
