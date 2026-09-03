extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 5.0
var lifetime: float = 2.0

func setup(target_pos: Vector2, dmg: float) -> void:
	damage = dmg
	velocity = (target_pos - global_position).normalized() * 260.0
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.call_deferred("take_damage", damage)
		queue_free()
