extends Area2D

@export var spin: bool = false

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var lifetime: float = 1.2
var pierce: int = 1
var hit_count: int = 0

func setup(target_pos: Vector2, dmg: float, maxed: bool = false) -> void:
	damage = dmg
	velocity = (target_pos - global_position).normalized() * 420.0
	rotation = velocity.angle()
	if maxed:
		modulate = Color(1.6, 1.2, 0.4, 1.0)
		scale *= 1.25

func _physics_process(delta: float) -> void:
	position += velocity * delta
	if spin:
		rotation += delta * 20.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.call_deferred("take_damage", damage)
		hit_count += 1
		if hit_count >= pierce:
			queue_free()
