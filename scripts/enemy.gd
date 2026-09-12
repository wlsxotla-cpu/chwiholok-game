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
	Type.OVERLORD: {"texture": "res://assets/sprites/enemy_overlord.png", "speed": 300.0, "health": 1600.0, "contact_damage": 60.0, "xp": 150.0},
}

const CHEONMAGUNG_TEXTURES := {
	Type.GRUNT: "res://assets/sprites/enemy_grunt_cheonmagung.png",
	Type.BRUTE: "res://assets/sprites/enemy_brute_cheonmagung.png",
	Type.ARCHER: "res://assets/sprites/enemy_archer_cheonmagung.png",
	Type.BOMBER: "res://assets/sprites/enemy_bomber_cheonmagung.png",
	Type.STRIKER: "res://assets/sprites/enemy_striker_cheonmagung.png",
}

const BOSS_SLAM_RANGE := 110.0
const BOSS_SLAM_DAMAGE := 30.0
const BOSS_SLAM_INTERVAL := 3.5
const OVERLORD_SLAM_RANGE := 220.0
const OVERLORD_SLAM_DAMAGE := 55.0
const OVERLORD_SLAM_INTERVAL := 2.6

const HALBERD_BARRAGE_COUNT := 10
const HALBERD_BARRAGE_DAMAGE := 34.0
const HALBERD_BARRAGE_INTERVAL := 2.4
const HALBERD_BOLT_SPEED_MULT := 1.9
const HALBERD_BOLT_LIFETIME := 3.4
const HALBERD_BOLT_SCALE := 1.9

const CHEONMA_ATTACK_INTERVAL := 2.0
const CHEONMA_NOVA_RADIUS := 260.0
const CHEONMA_NOVA_DAMAGE := 70.0
const CHEONMA_NOVA_TELEGRAPH := 0.9
const CHEONMA_RECOVERY_DURATION := 0.35

const QI_CANNON_BURST_COUNT := 5
const QI_CANNON_BURST_INTERVAL := 0.18
const QI_CANNON_DAMAGE := 10.0
const QI_CANNON_ATTACK_INTERVAL := 3.0

signal overlord_defeated
signal samahoek_defeated
signal died

var aura_timer: float = 0.0

@export var type: Type = Type.GRUNT
@export var difficulty_mult: float = 1.0
var boss_texture_override: String = ""
var use_curse_attack: bool = false
var use_halberd_barrage: bool = false
var use_cheonma_finale: bool = false
var cheonma_phase: int = 0
var cheonma_recovery_timer: float = 0.0
var use_qi_cannon: bool = false
var qi_burst_remaining: int = 0
var qi_burst_timer: float = 0.0
var speed_override: float = -1.0
var xp_mult_override: float = 1.0
var use_cheonmagung_skin: bool = false
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
	speed = def.speed if speed_override < 0.0 else speed_override
	max_health = def.health * difficulty_mult
	contact_damage = def.contact_damage * (1.0 + (difficulty_mult - 1.0) * 0.6)
	xp_value = def.xp * (1.0 + (difficulty_mult - 1.0) * 0.5) * xp_mult_override
	health = max_health
	var texture_path: String = def.texture
	if boss_texture_override != "":
		texture_path = boss_texture_override
	elif use_cheonmagung_skin and CHEONMAGUNG_TEXTURES.has(type):
		texture_path = CHEONMAGUNG_TEXTURES[type]
	sprite.texture = load(texture_path)
	fire_timer = float(def.get("fire_cooldown", 0.0)) * randf_range(0.4, 1.0)

	if type == Type.BOSS or type == Type.OVERLORD:
		var override_size_bonus: float = 1.3 if boss_texture_override != "" else 1.0
		sprite.scale *= (2.6 if type == Type.OVERLORD else 1.9) * override_size_bonus
		var shape := CircleShape2D.new()
		shape.radius = (42.0 if type == Type.OVERLORD else 30.0) * override_size_bonus
		$CollisionShape2D.shape = shape
		if type == Type.OVERLORD:
			if boss_texture_override == "":
				sprite.modulate = Color(0.75, 0.35, 1.0, 1.0)
			var base_interval: float = OVERLORD_SLAM_INTERVAL
			if use_cheonma_finale:
				base_interval = CHEONMA_ATTACK_INTERVAL
			elif use_halberd_barrage:
				base_interval = HALBERD_BARRAGE_INTERVAL
			slam_timer = base_interval * randf_range(0.5, 1.0)
		else:
			slam_timer = (QI_CANNON_ATTACK_INTERVAL if use_qi_cannon else BOSS_SLAM_INTERVAL) * randf_range(0.5, 1.0)
	else:
		_apply_rank_tint()

	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")

func _apply_rank_tint() -> void:
	if difficulty_mult >= 5.0:
		sprite.modulate = Color(0.95, 0.68, 0.92, 1.0)
		sprite.scale *= 1.25
	elif difficulty_mult >= 3.5:
		sprite.modulate = Color(1.0, 0.62, 0.58, 1.0)
		sprite.scale *= 1.16
	elif difficulty_mult >= 2.2:
		sprite.modulate = Color(1.0, 0.78, 0.58, 1.0)
		sprite.scale *= 1.08
	elif difficulty_mult >= 1.4:
		sprite.modulate = Color(1.0, 0.93, 0.7, 1.0)

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
	if use_cheonma_finale and cheonma_recovery_timer > 0.0:
		cheonma_recovery_timer -= delta
		velocity = velocity.lerp(Vector2.ZERO, 0.25)
		move_and_slide()
	else:
		_process_chase(delta)
	if type == Type.OVERLORD:
		_process_overlord_aura(delta)

	if qi_burst_remaining > 0:
		qi_burst_timer -= delta
		if qi_burst_timer <= 0.0:
			qi_burst_timer = QI_CANNON_BURST_INTERVAL
			_fire_qi_orb()
			qi_burst_remaining -= 1
		return

	slam_timer -= delta
	if slam_timer <= 0.0:
		if use_cheonma_finale:
			slam_timer = CHEONMA_ATTACK_INTERVAL
			cheonma_recovery_timer = CHEONMA_RECOVERY_DURATION
			match cheonma_phase:
				0:
					_boss_slam()
				1:
					_halberd_barrage()
				_:
					_cheonma_nova()
			cheonma_phase = (cheonma_phase + 1) % 3
		elif use_halberd_barrage:
			slam_timer = HALBERD_BARRAGE_INTERVAL
			_halberd_barrage()
		elif use_qi_cannon:
			slam_timer = QI_CANNON_ATTACK_INTERVAL
			qi_burst_remaining = QI_CANNON_BURST_COUNT
		else:
			slam_timer = OVERLORD_SLAM_INTERVAL if type == Type.OVERLORD else BOSS_SLAM_INTERVAL
			if use_curse_attack:
				_curse_bolt()
			else:
				_boss_slam()

func _boss_slam() -> void:
	var is_overlord: bool = type == Type.OVERLORD
	var slam_range: float = OVERLORD_SLAM_RANGE if is_overlord else BOSS_SLAM_RANGE
	var base_damage: float = OVERLORD_SLAM_DAMAGE if is_overlord else BOSS_SLAM_DAMAGE
	if global_position.distance_to(player.global_position) <= slam_range:
		player.take_damage(base_damage * (1.0 + (difficulty_mult - 1.0) * 0.6))
	SoundManager.play("explosion", -2.0, 0.55 if is_overlord else 0.7)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.set_radius(slam_range, is_overlord)

func _curse_bolt() -> void:
	var parent := get_parent()
	if parent == null:
		return
	SoundManager.play("attack_fireball", -2.0, 0.7)
	for i in range(3):
		var bolt := preload("res://scenes/EnemyBullet.tscn").instantiate()
		parent.add_child(bolt)
		bolt.global_position = global_position
		var spread: float = deg_to_rad(float(i - 1) * 12.0)
		var aim: Vector2 = (player.global_position - global_position).rotated(spread) + global_position
		bolt.setup(aim, BOSS_SLAM_DAMAGE * 0.55 * (1.0 + (difficulty_mult - 1.0) * 0.6))
		bolt.modulate = Color(1.3, 0.5, 1.5, 1.0)
		bolt.scale *= 1.6

func _fire_qi_orb() -> void:
	var parent := get_parent()
	if parent == null:
		return
	SoundManager.play("attack_fireball", -1.0, 1.1)
	var orb := preload("res://scenes/EnemyOrb.tscn").instantiate()
	parent.add_child(orb)
	orb.global_position = global_position
	orb.setup(player.global_position, QI_CANNON_DAMAGE * (1.0 + (difficulty_mult - 1.0) * 0.6))
	orb.modulate = Color(1.9, 0.35, 0.3, 1.0)
	orb.scale *= 1.3

func _cheonma_nova() -> void:
	var parent := get_parent()
	if parent == null:
		return
	SoundManager.play("explosion", 2.0, 0.4)
	var telegraph := preload("res://scenes/SlashEffect.tscn").instantiate()
	parent.add_child(telegraph)
	telegraph.global_position = global_position
	telegraph.modulate = Color(2.0, 0.3, 0.3, 0.55)
	telegraph.set_radius(CHEONMA_NOVA_RADIUS, true)
	get_tree().create_timer(CHEONMA_NOVA_TELEGRAPH).timeout.connect(func() -> void:
		if is_instance_valid(self):
			_cheonma_nova_impact())

func _cheonma_nova_impact() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if global_position.distance_to(player.global_position) <= CHEONMA_NOVA_RADIUS:
		player.take_damage(CHEONMA_NOVA_DAMAGE * (1.0 + (difficulty_mult - 1.0) * 0.6))
	SoundManager.play("explosion", 2.0, 0.5)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	parent.add_child(fx)
	fx.global_position = global_position
	fx.modulate = Color(2.4, 0.4, 0.35, 1.0)
	fx.set_radius(CHEONMA_NOVA_RADIUS, true)

func _halberd_barrage() -> void:
	var parent := get_parent()
	if parent == null:
		return
	SoundManager.play("attack_fireball", -1.0, 0.55)
	for i in range(HALBERD_BARRAGE_COUNT):
		var angle: float = TAU * float(i) / float(HALBERD_BARRAGE_COUNT)
		var bolt := preload("res://scenes/EnemyOrb.tscn").instantiate()
		parent.add_child(bolt)
		bolt.global_position = global_position
		var aim: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * 400.0
		bolt.setup(aim, HALBERD_BARRAGE_DAMAGE * (1.0 + (difficulty_mult - 1.0) * 0.6))
		bolt.velocity *= HALBERD_BOLT_SPEED_MULT
		bolt.rotation = bolt.velocity.angle()
		bolt.lifetime = HALBERD_BOLT_LIFETIME
		var bolt_sprite: Sprite2D = bolt.get_node("Sprite2D")
		bolt_sprite.texture = preload("res://assets/sprites/orbit_blade.png")
		bolt_sprite.scale = Vector2(0.6, 0.6)
		bolt.modulate = Color(1.3, 0.5, 0.95, 1.0)
		bolt.scale *= HALBERD_BOLT_SCALE

func _process_overlord_aura(delta: float) -> void:
	if boss_texture_override == "":
		sprite.modulate = Color(0.75, 0.35, 1.0, 1.0).lerp(Color(1.1, 0.5, 1.3, 1.0), (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5)
	aura_timer -= delta
	if aura_timer <= 0.0:
		aura_timer = 0.12
		var parent := get_parent()
		if parent == null:
			return
		var spark := preload("res://scenes/HitSpark.tscn").instantiate()
		parent.add_child(spark)
		spark.global_position = global_position + Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
		spark.modulate = Color(0.8, 0.4, 1.0, 1.0)

func apply_knockback(v: Vector2) -> void:
	knockback_timer = 0.25
	knockback_velocity = v

func take_damage(amount: float) -> void:
	health -= amount
	_spawn_hit_spark()
	if health <= 0.0:
		SoundManager.play("death", -4.0, randf_range(0.9, 1.1))
		_drop_loot()
		died.emit()
		if type == Type.OVERLORD:
			overlord_defeated.emit()
		elif type == Type.BOSS and use_curse_attack:
			samahoek_defeated.emit()
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
