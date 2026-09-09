class_name Enemy
extends CharacterBody2D

enum Type { GRUNT, BRUTE, ARCHER, BOMBER, STRIKER, BOSS, OVERLORD }

const DEFS := {
	Type.GRUNT: {"texture": "res://assets/sprites/enemy_placeholder.png", "speed": 70.0, "health": 20.0, "contact_damage": 8.0, "xp": 5.0},
	Type.BRUTE: {"texture": "res://assets/sprites/enemy_brute.png", "speed": 40.0, "health": 60.0, "contact_damage": 14.0, "xp": 12.0},
	Type.ARCHER: {"texture": "res://assets/sprites/enemy_archer.png", "speed": 60.0, "health": 12.0, "contact_damage": 5.0, "xp": 8.0, "preferred_range": 190.0, "fire_cooldown": 1.8, "arrow_damage": 6.0},
	Type.BOMBER: {"texture": "res://assets/sprites/enemy_bomber.png", "speed": 115.0, "health": 15.0, "contact_damage": 22.0, "xp": 10.0},
	Type.STRIKER: {"texture": "res://assets/sprites/enemy_striker.png", "speed": 145.0, "health": 14.0, "contact_damage": 10.0, "xp": 7.0},
	Type.BOSS: {"texture": "res://assets/sprites/enemy_boss.png", "speed": 55.0, "health": 380.0, "contact_damage": 26.0, "xp": 60.0},
	Type.OVERLORD: {"texture": "res://assets/sprites/enemy_overlord.png", "speed": 50.0, "health": 900.0, "contact_damage": 40.0, "xp": 150.0},
}

const BOSS_SLAM_RANGE := 110.0
const BOSS_SLAM_DAMAGE := 30.0
const BOSS_SLAM_INTERVAL := 3.5

@export var type: Type = Type.GRUNT
@export var difficulty_mult: float = 1.0
var slam_timer: float = 0.0

var speed: float
var max_health: float
var contact_damage: float
var xp_value: float

var health: float
var player: Node2D
var damage_tick: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0
var fire_timer: float = 0.0
var exploded: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var def: Dictionary = DEFS[type]
	speed = def.speed
	max_health = def.health * difficulty_mult
	contact_damage = def.contact_damage * (1.0 + (difficulty_mult - 1.0) * 0.6)
	xp_value = def.xp * (1.0 + (difficulty_mult - 1.0) * 0.5)
	health = max_health
	sprite.texture = load(def.texture)
	fire_timer = float(def.get("fire_cooldown", 0.0)) * randf_range(0.4, 1.0)

	if type == Type.BOSS or type == Type.OVERLORD:
		sprite.scale *= 2.6 if type == Type.OVERLORD else 1.9
		var shape := CircleShape2D.new()
		shape.radius = 42.0 if type == Type.OVERLORD else 30.0
		$CollisionShape2D.shape = shape
		slam_timer = BOSS_SLAM_INTERVAL * randf_range(0.5, 1.0)
	else:
		_apply_rank_tint()

	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _apply_rank_tint() -> void:
	if difficulty_mult >= 5.0:
		sprite.modulate = Color(1.0, 0.35, 0.95, 1.0)
		sprite.scale *= 1.25
	elif difficulty_mult >= 3.5:
		sprite.modulate = Color(1.0, 0.25, 0.25, 1.0)
		sprite.scale *= 1.16
	elif difficulty_mult >= 2.2:
		sprite.modulate = Color(1.0, 0.55, 0.15, 1.0)
		sprite.scale *= 1.08
	elif difficulty_mult >= 1.4:
		sprite.modulate = Color(1.0, 0.95, 0.3, 1.0)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity = knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 0.2)
		return

	match type:
		Type.ARCHER:
			_process_archer(delta)
		Type.BOMBER:
			_process_bomber(delta)
		Type.BOSS, Type.OVERLORD:
			_process_boss(delta)
		_:
			_process_chase(delta)

func _process_chase(delta: float) -> void:
	var dir: Vector2 = (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	sprite.flip_h = dir.x < 0

	if global_position.distance_to(player.global_position) < 26.0:
		damage_tick -= delta
		if damage_tick <= 0.0:
			player.take_damage(contact_damage)
			damage_tick = 0.6

func _process_archer(delta: float) -> void:
	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	var dir: Vector2 = to_player.normalized()
	var preferred: float = DEFS[Type.ARCHER].preferred_range
	if dist > preferred + 20.0:
		velocity = dir * speed
	elif dist < preferred - 20.0:
		velocity = -dir * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	sprite.flip_h = dir.x < 0

	fire_timer -= delta
	if fire_timer <= 0.0 and dist < preferred + 60.0:
		_fire_arrow()
		fire_timer = DEFS[Type.ARCHER].fire_cooldown

	if dist < 26.0:
		damage_tick -= delta
		if damage_tick <= 0.0:
			player.take_damage(contact_damage)
			damage_tick = 0.6

func _fire_arrow() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var arrow := preload("res://scenes/EnemyBullet.tscn").instantiate()
	parent.add_child(arrow)
	arrow.global_position = global_position
	arrow.setup(player.global_position, DEFS[Type.ARCHER].arrow_damage)

func _process_bomber(_delta: float) -> void:
	var dir: Vector2 = (player.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	sprite.flip_h = dir.x < 0

	if not exploded and global_position.distance_to(player.global_position) < 24.0:
		_explode()

func _explode() -> void:
	exploded = true
	player.take_damage(contact_damage)
	SoundManager.play("explosion")
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.set_radius(40.0)
	queue_free()

func _process_boss(delta: float) -> void:
	_process_chase(delta)
	slam_timer -= delta
	if slam_timer <= 0.0:
		slam_timer = BOSS_SLAM_INTERVAL
		_boss_slam()

func _boss_slam() -> void:
	if global_position.distance_to(player.global_position) <= BOSS_SLAM_RANGE:
		player.take_damage(BOSS_SLAM_DAMAGE * (1.0 + (difficulty_mult - 1.0) * 0.6))
	SoundManager.play("explosion", -2.0, 0.7)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.set_radius(BOSS_SLAM_RANGE)

func apply_knockback(v: Vector2) -> void:
	knockback_timer = 0.25
	knockback_velocity = v

func take_damage(amount: float) -> void:
	health -= amount
	_spawn_hit_spark()
	if health <= 0.0:
		SoundManager.play("death", -4.0, randf_range(0.9, 1.1))
		_drop_loot()
		queue_free()
	else:
		SoundManager.play("hit", -8.0, randf_range(0.9, 1.1))

func _spawn_hit_spark() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var spark := preload("res://scenes/HitSpark.tscn").instantiate()
	parent.add_child(spark)
	spark.global_position = global_position

func _drop_loot() -> void:
	var parent := get_parent()
	if parent == null:
		return

	var gem := preload("res://scenes/Pickup.tscn").instantiate()
	gem.type = gem.Type.XP
	gem.value = xp_value
	gem.global_position = global_position
	parent.add_child(gem)

	if randf() < 0.35:
		var coin := preload("res://scenes/Pickup.tscn").instantiate()
		coin.type = coin.Type.COIN
		coin.value = 1.0
		coin.global_position = global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		parent.add_child(coin)

	if randf() < 0.03:
		var magnet := preload("res://scenes/Pickup.tscn").instantiate()
		magnet.type = magnet.Type.MAGNET
		magnet.global_position = global_position
		parent.add_child(magnet)

	if type == Type.BOSS or type == Type.OVERLORD:
		var coin_count: int = 24 if type == Type.OVERLORD else 8
		for i in range(coin_count):
			var bonus_coin := preload("res://scenes/Pickup.tscn").instantiate()
			bonus_coin.type = bonus_coin.Type.COIN
			bonus_coin.value = 1.0
			var angle: float = TAU * i / float(coin_count)
			bonus_coin.global_position = global_position + Vector2(cos(angle), sin(angle)) * 26.0
			parent.add_child(bonus_coin)

		var xp_gem_count: int = 10 if type == Type.OVERLORD else 5
		var bonus_xp_total: float = xp_value * (2.0 if type == Type.OVERLORD else 1.0)
		var xp_per_gem: float = bonus_xp_total / float(xp_gem_count)
		for i in range(xp_gem_count):
			var bonus_gem := preload("res://scenes/Pickup.tscn").instantiate()
			bonus_gem.type = bonus_gem.Type.XP
			bonus_gem.value = xp_per_gem
			var angle: float = TAU * (i + 0.5) / float(xp_gem_count)
			bonus_gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * 44.0
			parent.add_child(bonus_gem)
