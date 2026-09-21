extends Area2D

const ORBIT_RADIUS := 55.0
const ORBIT_DURATION := 0.35
const ORBIT_SPEED := 16.0
const LAUNCH_SPEED := 460.0
const MAX_LAUNCH_DIST := 340.0
const SPIN_VISUAL_SPEED := 22.0

var owner_player: Node2D
var damage: float = 8.0
var maxed: bool = false
var angle: float = 0.0
var orbit_timer: float = ORBIT_DURATION
var launching: bool = false
var launch_dir: Vector2 = Vector2.RIGHT
var traveled: float = 0.0
var hit_enemies: Dictionary = {}

func setup(player: Node2D, start_angle: float, dmg: float, is_maxed: bool = false, aim_dir: Vector2 = Vector2.RIGHT) -> void:
	owner_player = player
	angle = start_angle
	damage = dmg
	maxed = is_maxed
	launch_dir = aim_dir
	modulate = Color(0.85, 2.1, 2.0, 1.0) if maxed else Color(0.6, 1.5, 1.5, 1.0)
	if maxed:
		scale *= 1.5

func _physics_process(delta: float) -> void:
	if not launching:
		if owner_player == null or not is_instance_valid(owner_player):
			queue_free()
			return
		angle += delta * ORBIT_SPEED
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS
		global_position = owner_player.global_position + offset
		rotation += delta * SPIN_VISUAL_SPEED
		orbit_timer -= delta
		if orbit_timer <= 0.0:
			launching = true
			hit_enemies.clear()
	else:
		var step: float = LAUNCH_SPEED * delta
		global_position += launch_dir * step
		traveled += step
		rotation += delta * SPIN_VISUAL_SPEED
		if traveled >= MAX_LAUNCH_DIST:
			queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage") and not hit_enemies.has(body):
		body.call_deferred("take_damage", damage)
		hit_enemies[body] = true
