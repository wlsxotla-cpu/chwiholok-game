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

func setup(player: Node2D, direction: Vector2, dmg: float) -> void:
	owner_player = player
	dir = direction
	damage = dmg
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	if not returning:
		var step: float = SPEED * delta
		position += dir * step
		traveled += step
		rotation += delta * SPIN_SPEED
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
		rotation += delta * SPIN_SPEED

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage") and not hit_enemies.has(body):
		body.call_deferred("take_damage", damage)
		hit_enemies[body] = true
