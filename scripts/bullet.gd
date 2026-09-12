extends Area2D

@export var spin: bool = false

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var lifetime: float = 1.2
var pierce: int = 1
var hit_count: int = 0
var rocket: bool = false
var smoke_timer: float = 0.0
var leaves_fire_zone: bool = false
var fire_zone_damage: float = 0.0
var fire_zone_duration: float = 0.0
var fire_zone_radius: float = 0.0
var fire_zone_maxed: bool = false

func setup(target_pos: Vector2, dmg: float, maxed: bool = false, is_rocket: bool = false) -> void:
	damage = dmg
	velocity = (target_pos - global_position).normalized() * 420.0
	rotation = velocity.angle()
	rocket = is_rocket and maxed
	if maxed:
		modulate = Color(2.6, 1.3, 1.5, 1.0) if rocket else Color(2.2, 2.2, 2.5, 1.0)
		scale *= 2.2 if rocket else 1.5

func _physics_process(delta: float) -> void:
	position += velocity * delta
	if spin:
		rotation += delta * 20.0
	if rocket:
		smoke_timer -= delta
		if smoke_timer <= 0.0:
			smoke_timer = 0.035
			_spawn_smoke()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _spawn_smoke() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var puff := preload("res://scenes/SmokePuff.tscn").instantiate()
	parent.add_child(puff)
	puff.global_position = global_position - velocity.normalized() * 16.0 + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.call_deferred("take_damage", damage)
		if leaves_fire_zone:
			call_deferred("_spawn_fire_zone", body.global_position)
		hit_count += 1
		if hit_count >= pierce:
			queue_free()

func _spawn_fire_zone(pos: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var zone := preload("res://scenes/FireZone.tscn").instantiate()
	parent.add_child(zone)
	zone.global_position = pos
	zone.setup(fire_zone_damage, fire_zone_duration, fire_zone_radius, fire_zone_maxed)
