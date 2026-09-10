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
	if not (body.is_in_group("player") and body.has_method("take_damage")):
		return
	if body.has_method("can_parry") and body.can_parry():
		_parry(body)
		return
	body.call_deferred("take_damage", damage)
	queue_free()

func _parry(body: Node) -> void:
	body.trigger_parry()
	SoundManager.play("attack_melee", -2.0, 1.5)
	var spark := preload("res://scenes/HitSpark.tscn").instantiate()
	body.get_parent().add_child(spark)
	spark.global_position = global_position
	spark.modulate = Color(1.0, 0.85, 0.35, 1.2)
	spark.scale *= 1.4
	queue_free()
