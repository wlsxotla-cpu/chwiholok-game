extends CharacterBody2D

signal died
signal stats_changed
signal leveled_up(options: Array)
signal weapon_evolved(weapon_name: String)
signal weapon_fused(weapon_name: String)
signal revived
signal continue_offered(cost: int, available: int)
signal fusion_offered(fid: String, wid: String, partner: String)

const MAX_WEAPON_LEVEL := 8
const SOFT_CAP_LEVEL := 5
const MAX_WEAPON_SLOTS := 5
const PASSIVE_SLOTS := 5
const FUSION_START_LEVEL := 5
const TARGET_SEARCH_RANGE := 300.0

const WEAPON_DEFS := {
	"slash": {"name": "회전베기", "cooldown": 1.1, "damage": 10.0, "radius": 85.0},
	"pierce": {"name": "관통시", "cooldown": 1.0, "damage": 9.0},
	"fireball": {"name": "화염구 장판", "cooldown": 2.2, "damage": 5.0, "duration": 2.0, "zone_radius": 75.0},
	"aura": {"name": "호신강기", "cooldown": 0.45, "damage": 5.0, "radius": 70.0, "knockback": 70.0},
	"shuriken": {"name": "표창난사", "cooldown": 1.2, "damage": 6.0, "count": 2.0},
	"orbit": {"name": "어검비행", "cooldown": 0.2, "damage": 8.0, "radius": 65.0, "count": 2.0},
	"boomerang": {"name": "회류표", "cooldown": 1.4, "damage": 8.0, "count": 1.0},
	"beam": {"name": "일자검기", "cooldown": 1.6, "damage": 14.0, "radius": 260.0},
	"lightning": {"name": "뇌전장", "cooldown": 1.8, "damage": 7.0, "count": 2.0},
	"heaven_blade": {"name": "천지개벽검", "cooldown": 1.0, "damage": 22.0, "radius": 130.0, "knockback": 160.0},
	"piercing_calamity": {"name": "멸겁관천검", "cooldown": 1.3, "damage": 26.0, "radius": 340.0},
	"whirl_storm": {"name": "선풍만리표", "cooldown": 1.2, "damage": 12.0, "count": 5.0},
	"thunder_formation": {"name": "뇌검진", "cooldown": 1.0, "damage": 9.0, "radius": 100.0, "count": 3.0},
}

const FUSION_DEFS := {
	"heaven_blade": {"pair": ["slash", "aura"]},
	"piercing_calamity": {"pair": ["pierce", "beam"]},
	"whirl_storm": {"pair": ["shuriken", "boomerang"]},
	"thunder_formation": {"pair": ["orbit", "lightning"]},
}

const EVOLUTION_DEFS := {
	"slash": {"name": "폭풍베기", "damage_mult": 1.3, "radius_mult": 1.25, "cooldown_mult": 0.85},
	"aura": {"name": "파극호신강기", "damage_mult": 1.25, "radius_mult": 1.25, "knockback_mult": 1.3},
	"pierce": {"name": "만천화우시", "damage_mult": 1.3, "extra_pierce": 3.0},
	"fireball": {"name": "겁화지옥진", "damage_mult": 1.3, "zone_radius_mult": 1.3, "extra_duration": 1.0},
	"shuriken": {"name": "만화표창진", "damage_mult": 1.25, "extra_count": 2.0},
	"orbit": {"name": "천검진", "damage_mult": 1.25, "extra_count": 2.0},
	"boomerang": {"name": "만리회선표", "damage_mult": 1.3, "extra_count": 2.0},
	"beam": {"name": "무형검기", "damage_mult": 1.3, "radius_mult": 1.3},
	"lightning": {"name": "천둔뇌영", "damage_mult": 1.25, "extra_count": 2.0},
}

const PASSIVE_DEFS := {
	"power_scroll": {"weapons": ["slash", "pierce", "orbit"], "name": "파산도결", "desc": "공격력 +12%. 회전베기/관통시/어검비행 만렙 시 진화 가능", "effect": "damage"},
	"body_scroll": {"weapons": ["aura", "lightning"], "name": "철갑신공", "desc": "최대체력 +25. 호신강기/뇌전장 만렙 시 진화 가능", "effect": "hp"},
	"agility_scroll": {"weapons": ["shuriken", "boomerang"], "name": "비연신법", "desc": "이동속도 +10%. 표창난사/회류표 만렙 시 진화 가능", "effect": "move"},
	"haste_scroll": {"weapons": ["beam"], "name": "연격지결", "desc": "공격속도 +10%. 일자검기 만렙 시 진화 가능", "effect": "cooldown"},
	"gather_scroll": {"weapons": ["fireball"], "name": "채기흡자결", "desc": "수집 반경 +15%. 화염구 만렙 시 진화 가능", "effect": "pickup"},
}

@export var speed: float = 160.0
@export var max_health: float = 100.0
@export var pickup_radius: float = 60.0

var health: float
var xp: float = 0.0
var xp_to_level: float = 20.0
var level: int = 1
var facing: String = "down"
var coins: int = 0
var base_pickup_radius: float = 60.0
var magnet_timer: float = 0.0
var global_damage_mult: float = 1.0
var global_cooldown_mult: float = 1.0

var weapons: Array = []
var owned_passives: Dictionary = {}
var orbit_node: Node2D = null
var shake_time: float = 0.0
var shake_strength: float = 0.0

const INVINCIBLE_DURATION := 0.5
const REVIVE_INVINCIBLE_DURATION := 2.0
const REVIVE_HEALTH_FRACTION := 0.5
var invincible_timer: float = 0.0
var continues_used: int = 0
var max_continues: int = 1
var declined_fusions: Dictionary = {}
var pending_fusion_id: String = ""

var upgrade_pool: Array = [
	{"id": "dmg", "name": "공격력 증가", "desc": "모든 무기 공격력 +10%"},
	{"id": "speed", "name": "공격속도 증가", "desc": "모든 무기 쿨타임 -10%"},
	{"id": "hp", "name": "체력 증가", "desc": "최대체력 +20, 전체 회복"},
	{"id": "move", "name": "이동속도 증가", "desc": "이동속도 +12%"},
	{"id": "pickup", "name": "수집 반경 증가", "desc": "픽업 반경 +25%"},
]

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var joystick: Control = null

func _ready() -> void:
	add_to_group("player")
	call_deferred("_find_joystick")
	var char_data: Dictionary = GameState.get_character(GameState.selected_character)
	_apply_meta_upgrades()
	_apply_character_tier_bonus(char_data)
	health = max_health
	pickup_radius = base_pickup_radius

	anim.sprite_frames = _build_sprite_frames(char_data.walk_sheet)
	anim.play("walk_down")
	anim.stop()
	var starting_weapon: String = char_data.get("weapon", "slash")
	if not WEAPON_DEFS.has(starting_weapon):
		starting_weapon = "slash"
	weapons.append({"id": starting_weapon, "level": 1, "timer": 0.0})
	_ensure_orbit_node(starting_weapon)

	stats_changed.emit()

func _ensure_orbit_node(wid: String) -> void:
	if wid == "orbit" and orbit_node == null:
		orbit_node = preload("res://scenes/OrbitWeapon.tscn").instantiate()
		add_child(orbit_node)

func _find_joystick() -> void:
	joystick = get_tree().get_first_node_in_group("joystick")

func _apply_meta_upgrades() -> void:
	var meta: Dictionary = GameState.meta_upgrades
	max_health += 15.0 * float(meta.get("hp", 0))
	global_damage_mult *= (1.0 + 0.07 * float(meta.get("dmg", 0)))
	speed *= (1.0 + 0.06 * float(meta.get("move", 0)))
	base_pickup_radius *= (1.0 + 0.10 * float(meta.get("pickup", 0)))
	max_continues = 1 + int(meta.get("revive_slots", 0))

func _apply_character_tier_bonus(char_data: Dictionary) -> void:
	var tier: int = int(char_data.get("tier", 0))
	if tier <= 0:
		return
	max_health *= (1.0 + 0.06 * tier)
	global_damage_mult *= (1.0 + 0.06 * tier)

func _build_sprite_frames(sheet_path: String) -> SpriteFrames:
	var tex: Texture2D = load(sheet_path)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var row_map := {"up": 0, "side": 1, "down": 2}
	for anim_name in row_map.keys():
		var full_name: String = "walk_" + anim_name
		frames.add_animation(full_name)
		frames.set_animation_loop(full_name, true)
		frames.set_animation_speed(full_name, 7.0)
		var row: int = row_map[anim_name]
		for col in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * 64, row * 64, 64, 64)
			frames.add_frame(full_name, atlas)
	return frames

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	var from_joystick := false
	if joystick and joystick.direction.length() > 0.01:
		input_dir = joystick.direction
		from_joystick = true
	if not from_joystick and input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	var target_velocity: Vector2 = input_dir * speed
	velocity = velocity.lerp(target_velocity, clamp(20.0 * delta, 0.0, 1.0))
	move_and_slide()
	_update_animation(input_dir)

	if invincible_timer > 0.0:
		invincible_timer -= delta
		anim.visible = int(invincible_timer * 20.0) % 2 == 0
		if invincible_timer <= 0.0:
			anim.visible = true
			anim.modulate = Color(1, 1, 1, 1)

	for w in weapons:
		w.timer -= delta
		if w.timer <= 0.0:
			_fire_weapon(w)
			w.timer = _weapon_stat(w, "cooldown")

	if magnet_timer > 0.0:
		magnet_timer -= delta
		if magnet_timer <= 0.0:
			pickup_radius = base_pickup_radius

	if shake_time > 0.0:
		shake_time -= delta
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
	else:
		shake_strength = 0.0
		camera.offset = Vector2.ZERO

func screen_shake(strength: float, duration: float) -> void:
	shake_strength = max(shake_strength, strength)
	shake_time = max(shake_time, duration)

func _update_animation(input_dir: Vector2) -> void:
	if input_dir.length() > 0.01:
		if abs(input_dir.x) > abs(input_dir.y):
			facing = "side"
			anim.flip_h = input_dir.x < 0
		else:
			facing = "up" if input_dir.y < 0 else "down"
		anim.play("walk_" + facing)
	else:
		anim.stop()

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := TARGET_SEARCH_RANGE
	for e in enemies:
		var d: float = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

func _level_mult(lvl: int, per_level: float) -> float:
	var full_steps: int = min(lvl - 1, SOFT_CAP_LEVEL - 1)
	var soft_steps: int = max(0, lvl - SOFT_CAP_LEVEL)
	return 1.0 + per_level * full_steps + (per_level * 0.5) * soft_steps

func _weapon_stat(w: Dictionary, key: String) -> float:
	var def: Dictionary = WEAPON_DEFS[w.id]
	var lvl: int = w.level
	var value: float = 0.0
	match key:
		"cooldown":
			value = float(def.cooldown) * global_cooldown_mult
		"damage":
			value = float(def.damage) * _level_mult(lvl, 0.15) * global_damage_mult
		"radius":
			value = float(def.get("radius", 0.0)) * _level_mult(lvl, 0.15)
		"duration":
			value = float(def.get("duration", 0.0)) + 1.0 * min(lvl - 1, SOFT_CAP_LEVEL - 1) + 0.5 * max(0, lvl - SOFT_CAP_LEVEL)
		"zone_radius":
			value = float(def.get("zone_radius", 0.0)) * _level_mult(lvl, 0.15)
		"pierce":
			value = float(lvl)
		"knockback":
			value = float(def.get("knockback", 0.0)) * _level_mult(lvl, 0.12)
		"count":
			value = float(def.get("count", 1.0)) + float(lvl - 1)
	if w.get("evolved", false):
		var evo: Dictionary = EVOLUTION_DEFS.get(w.id, {})
		match key:
			"damage":
				value *= float(evo.get("damage_mult", 1.0))
			"radius":
				value *= float(evo.get("radius_mult", 1.0))
			"zone_radius":
				value *= float(evo.get("zone_radius_mult", 1.0))
			"knockback":
				value *= float(evo.get("knockback_mult", 1.0))
			"cooldown":
				value *= float(evo.get("cooldown_mult", 1.0))
			"pierce":
				value += float(evo.get("extra_pierce", 0.0))
			"duration":
				value += float(evo.get("extra_duration", 0.0))
			"count":
				value += float(evo.get("extra_count", 0.0))
	return value

func _is_maxed(w: Dictionary) -> bool:
	return int(w.level) >= MAX_WEAPON_LEVEL or FUSION_DEFS.has(w.id)

func _facing_vector() -> Vector2:
	match facing:
		"up":
			return Vector2(0, -1)
		"side":
			return Vector2(-1.0 if anim.flip_h else 1.0, 0)
	return Vector2(0, 1)

func _fire_weapon(w: Dictionary) -> void:
	match w.id:
		"slash":
			_fire_slash(w)
		"pierce":
			_fire_pierce(w)
		"fireball":
			_fire_fireball(w)
		"aura":
			_fire_aura(w)
		"shuriken":
			_fire_shuriken(w)
		"orbit":
			_fire_orbit(w)
		"boomerang":
			_fire_boomerang(w)
		"beam":
			_fire_beam(w)
		"lightning":
			_fire_lightning(w)
		"heaven_blade":
			_fire_heaven_blade(w)
		"piercing_calamity":
			_fire_beam(w)
		"whirl_storm":
			_fire_boomerang(w)
		"thunder_formation":
			_fire_thunder_formation(w)

func _fire_heaven_blade(w: Dictionary) -> void:
	var radius: float = _weapon_stat(w, "radius")
	var damage: float = _weapon_stat(w, "damage")
	var knockback: float = _weapon_stat(w, "knockback")
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		var to_e: Vector2 = e.global_position - global_position
		if to_e.length() <= radius:
			e.take_damage(damage)
			if e.has_method("apply_knockback") and to_e.length() > 0.001:
				e.apply_knockback(to_e.normalized() * knockback)
			hit_any = true
	if hit_any:
		screen_shake(4.0, 0.15)
	SoundManager.play("attack_melee", -1.0, 0.75)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.set_radius(radius, _is_maxed(w))

func _fire_thunder_formation(w: Dictionary) -> void:
	if orbit_node == null:
		orbit_node = preload("res://scenes/OrbitWeapon.tscn").instantiate()
		add_child(orbit_node)
	orbit_node.sync(_weapon_stat(w, "damage"), _weapon_stat(w, "radius"), int(_weapon_stat(w, "count")), _is_maxed(w))
	_fire_lightning(w)

func _fire_beam(w: Dictionary) -> void:
	var target := _find_nearest_enemy()
	var dir: Vector2 = (target.global_position - global_position).normalized() if target else _facing_vector()
	var length: float = _weapon_stat(w, "radius")
	var damage: float = _weapon_stat(w, "damage")
	var width: float = 90.0 if w.id == "piercing_calamity" else 36.0
	if _is_maxed(w):
		width *= 1.6
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		var to_e: Vector2 = e.global_position - global_position
		var proj: float = to_e.dot(dir)
		if proj < 0.0 or proj > length:
			continue
		var perp: float = (to_e - dir * proj).length()
		if perp <= width / 2.0:
			e.take_damage(damage)
			hit_any = true
	if hit_any:
		screen_shake(2.5, 0.1)
	SoundManager.play("attack_melee", -3.0, 1.1)
	var fx := preload("res://scenes/BeamEffect.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.setup(dir, length, width, w.id == "piercing_calamity" or _is_maxed(w))

func _fire_lightning(w: Dictionary) -> void:
	var damage: float = _weapon_stat(w, "damage")
	var count: int = int(_weapon_stat(w, "count"))
	var enemies: Array = get_tree().get_nodes_in_group("enemies").filter(
		func(e: Node) -> bool: return global_position.distance_to(e.global_position) <= TARGET_SEARCH_RANGE
	)
	enemies.shuffle()
	var struck: int = 0
	for e in enemies:
		e.take_damage(damage)
		var fx := preload("res://scenes/LightningEffect.tscn").instantiate()
		get_parent().add_child(fx)
		fx.global_position = e.global_position
		fx.setup(_is_maxed(w))
		struck += 1
		if struck >= count:
			break
	if struck > 0:
		SoundManager.play("attack_fireball", -2.0, 1.3)
		screen_shake(2.0, 0.08)

func _fire_orbit(w: Dictionary) -> void:
	if orbit_node == null:
		return
	orbit_node.sync(_weapon_stat(w, "damage"), _weapon_stat(w, "radius"), int(_weapon_stat(w, "count")), _is_maxed(w))

func _fire_boomerang(w: Dictionary) -> void:
	var target := _find_nearest_enemy()
	var dir: Vector2 = (target.global_position - global_position).normalized() if target else _facing_vector()
	var damage: float = _weapon_stat(w, "damage")
	var count: int = int(_weapon_stat(w, "count"))
	var spread_deg: float = 18.0
	for i in range(count):
		var offset: float = (i - (count - 1) / 2.0) * spread_deg
		var d: Vector2 = dir.rotated(deg_to_rad(offset))
		var dart := preload("res://scenes/BoomerangBullet.tscn").instantiate()
		get_parent().add_child(dart)
		dart.global_position = global_position
		dart.setup(self, d, damage, _is_maxed(w))
	SoundManager.play("attack_ranged", -4.0, 1.05)

func _fire_slash(w: Dictionary) -> void:
	var radius: float = _weapon_stat(w, "radius")
	var damage: float = _weapon_stat(w, "damage")
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(e.global_position) <= radius:
			e.take_damage(damage)
			hit_any = true
	if hit_any:
		screen_shake(2.0, 0.08)
	SoundManager.play("attack_melee", -4.0)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.set_radius(radius, _is_maxed(w))

func _fire_pierce(w: Dictionary) -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	var bullet := preload("res://scenes/Bullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -24)
	bullet.pierce = int(_weapon_stat(w, "pierce"))
	bullet.setup(target.global_position, _weapon_stat(w, "damage"), _is_maxed(w))
	SoundManager.play("attack_ranged", -6.0)

func _fire_fireball(w: Dictionary) -> void:
	var target := _find_nearest_enemy()
	var pos: Vector2 = target.global_position if target else (global_position + Vector2(0, -80))
	var zone := preload("res://scenes/FireZone.tscn").instantiate()
	get_parent().add_child(zone)
	zone.global_position = pos
	zone.setup(_weapon_stat(w, "damage"), _weapon_stat(w, "duration"), _weapon_stat(w, "zone_radius"), _is_maxed(w))
	SoundManager.play("attack_fireball", -4.0)

func _fire_aura(w: Dictionary) -> void:
	var radius: float = _weapon_stat(w, "radius")
	var damage: float = _weapon_stat(w, "damage")
	var knockback: float = _weapon_stat(w, "knockback")
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector2 = e.global_position - global_position
		var dist: float = to_enemy.length()
		if dist <= radius and dist > 0.001:
			e.take_damage(damage)
			if e.has_method("apply_knockback"):
				e.apply_knockback(to_enemy.normalized() * knockback)
			hit_any = true
	if hit_any:
		SoundManager.play("attack_melee", -10.0, 1.3)
	var fx := preload("res://scenes/AuraEffect.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.setup(radius, _is_maxed(w))

func _fire_shuriken(w: Dictionary) -> void:
	var target := _find_nearest_enemy()
	if target == null:
		return
	var base_dir: Vector2 = (target.global_position - global_position).normalized()
	var count: int = int(_weapon_stat(w, "count"))
	var damage: float = _weapon_stat(w, "damage")
	var spread_deg: float = 10.0
	for i in range(count):
		var offset: float = (i - (count - 1) / 2.0) * spread_deg
		var dir: Vector2 = base_dir.rotated(deg_to_rad(offset))
		var bullet := preload("res://scenes/ShurikenBullet.tscn").instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position + Vector2(0, -24)
		bullet.pierce = 1
		bullet.setup(global_position + dir * 400.0, damage, _is_maxed(w))
	SoundManager.play("attack_ranged", -3.0, 1.15)

func _get_weapon(id: String) -> Dictionary:
	for w in weapons:
		if w.id == id:
			return w
	return {}

func has_weapon(id: String) -> bool:
	return not _get_weapon(id).is_empty()

func take_damage(amount: float) -> void:
	if invincible_timer > 0.0:
		return
	health -= amount
	stats_changed.emit()
	screen_shake(clamp(amount * 0.5, 3.0, 10.0), 0.18)
	SoundManager.play("hurt")
	_flash_hurt()
	invincible_timer = INVINCIBLE_DURATION
	if health <= 0.0:
		if continues_used < max_continues:
			health = 0.0
			get_tree().paused = true
			continue_offered.emit(GameState.CONTINUE_COST, GameState.total_coins + coins)
			return
		health = 0.0
		died.emit()

func confirm_continue() -> void:
	if GameState.total_coins + coins < GameState.CONTINUE_COST:
		return
	continues_used += 1
	GameState.add_run_coins(coins)
	coins = 0
	GameState.spend_coins(GameState.CONTINUE_COST)
	health = max_health * REVIVE_HEALTH_FRACTION
	invincible_timer = REVIVE_INVINCIBLE_DURATION
	stats_changed.emit()
	revived.emit()
	get_tree().paused = false

func decline_continue() -> void:
	get_tree().paused = false
	died.emit()

func _flash_hurt() -> void:
	anim.modulate = Color(1.6, 0.55, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(anim, "modulate", Color(1, 1, 1, 1), 0.18)

const HARD_MODE_COIN_MULT := 1.3
const HARD_MODE_XP_MULT := 1.15

func gain_xp(amount: float) -> void:
	if GameState.hard_mode:
		amount *= HARD_MODE_XP_MULT
	xp += amount
	stats_changed.emit()
	if xp >= xp_to_level:
		xp -= xp_to_level
		level += 1
		xp_to_level *= 1.20
		_offer_level_up()

func _offer_level_up() -> void:
	var owned_ids: Array = []
	for w in weapons:
		owned_ids.append(w.id)

	var pool: Array = []
	if weapons.size() < MAX_WEAPON_SLOTS:
		for wid in WEAPON_DEFS.keys():
			if not owned_ids.has(wid) and not FUSION_DEFS.has(wid):
				pool.append({"kind": "new_weapon", "wid": wid})
	for w in weapons:
		if w.level < MAX_WEAPON_LEVEL:
			pool.append({"kind": "upgrade_weapon", "wid": w.id})
			pool.append({"kind": "upgrade_weapon", "wid": w.id})
			pool.append({"kind": "upgrade_weapon", "wid": w.id})
	if owned_passives.size() < PASSIVE_SLOTS:
		for pid in PASSIVE_DEFS.keys():
			if owned_passives.get(pid, false):
				continue
			var pdef: Dictionary = PASSIVE_DEFS[pid]
			var has_maxed_weapon := false
			for wid2 in pdef.weapons:
				var w2 := _get_weapon(wid2)
				if not w2.is_empty() and int(w2.level) >= MAX_WEAPON_LEVEL:
					has_maxed_weapon = true
					break
			if has_maxed_weapon:
				pool.append({"kind": "passive", "pid": pid})
	for s in upgrade_pool:
		pool.append({"kind": "stat", "sid": s.id})

	SoundManager.play("levelup")
	pool.shuffle()
	var chosen: Array = []
	var seen: Array = []
	for entry in pool:
		var key: String = str(entry.kind, "_", entry.get("wid", entry.get("sid", entry.get("pid", ""))))
		if seen.has(key):
			continue
		seen.append(key)
		chosen.append(_describe_option(entry))
		if chosen.size() >= 3:
			break

	get_tree().paused = true
	leveled_up.emit(chosen)

func _describe_option(entry: Dictionary) -> Dictionary:
	match entry.kind:
		"new_weapon":
			var def: Dictionary = WEAPON_DEFS[entry.wid]
			return {"id": "new_weapon:" + entry.wid, "name": "신규무기: %s" % def.name, "desc": "장착", "kind": "new_weapon"}
		"upgrade_weapon":
			var w := _get_weapon(entry.wid)
			var def: Dictionary = WEAPON_DEFS[entry.wid]
			if w.level + 1 >= MAX_WEAPON_LEVEL:
				var pid: String = _passive_id_for_weapon(entry.wid)
				var evo_name: String = EVOLUTION_DEFS.get(entry.wid, {}).get("name", def.name)
				if pid != "" and owned_passives.get(pid, false):
					return {"id": "upgrade_weapon:" + entry.wid, "name": "%s 강화" % def.name, "desc": "Lv.%d → 진화! (%s)" % [w.level, evo_name], "kind": "upgrade_weapon"}
				var passive_name: String = PASSIVE_DEFS.get(pid, {}).get("name", "")
				return {"id": "upgrade_weapon:" + entry.wid, "name": "%s 강화" % def.name, "desc": "Lv.%d → 만렙 (진화하려면 %s 필요)" % [w.level, passive_name], "kind": "upgrade_weapon"}
			return {"id": "upgrade_weapon:" + entry.wid, "name": "%s 강화" % def.name, "desc": "Lv.%d → Lv.%d" % [w.level, w.level + 1], "kind": "upgrade_weapon"}
		"passive":
			var pdef: Dictionary = PASSIVE_DEFS[entry.pid]
			return {"id": "passive:" + entry.pid, "name": "비급: %s" % pdef.name, "desc": pdef.desc, "kind": "passive"}
		"stat":
			for s in upgrade_pool:
				if s.id == entry.sid:
					return {"id": "stat:" + entry.sid, "name": s.name, "desc": s.desc, "kind": "stat"}
	return {"id": "", "name": "", "desc": "", "kind": "stat"}

func _passive_id_for_weapon(wid: String) -> String:
	for pid in PASSIVE_DEFS.keys():
		if PASSIVE_DEFS[pid].weapons.has(wid):
			return pid
	return ""

func _try_evolve(w: Dictionary, wid: String) -> void:
	if w.level < MAX_WEAPON_LEVEL or w.get("evolved", false):
		return
	var pid: String = _passive_id_for_weapon(wid)
	if pid == "" or not owned_passives.get(pid, false):
		return
	w.evolved = true
	SoundManager.play("levelup", 2.0, 0.8)
	screen_shake(4.0, 0.15)
	weapon_evolved.emit(EVOLUTION_DEFS.get(wid, {}).get("name", wid))

func _fusion_id_for(wid: String) -> String:
	for fid in FUSION_DEFS.keys():
		if FUSION_DEFS[fid].pair.has(wid):
			return fid
	return ""

func _fusion_partner(wid: String) -> String:
	var fid: String = _fusion_id_for(wid)
	if fid == "":
		return ""
	for other in FUSION_DEFS[fid].pair:
		if other != wid:
			return other
	return ""

func _check_fusion_offer(wid: String) -> void:
	var fid: String = _fusion_id_for(wid)
	if fid == "" or not _get_weapon(fid).is_empty() or declined_fusions.get(fid, false) or pending_fusion_id != "":
		return
	var partner: String = _fusion_partner(wid)
	var w_self := _get_weapon(wid)
	var w_partner := _get_weapon(partner)
	if w_self.is_empty() or w_partner.is_empty():
		return
	if int(w_self.level) < MAX_WEAPON_LEVEL or int(w_partner.level) < MAX_WEAPON_LEVEL:
		return
	pending_fusion_id = fid
	get_tree().paused = true
	fusion_offered.emit(fid, wid, partner)

func confirm_fuse(fid: String) -> void:
	var pair: Array = FUSION_DEFS[fid].pair
	var w_a := _get_weapon(pair[0])
	var w_b := _get_weapon(pair[1])
	if w_a.is_empty() or w_b.is_empty():
		pending_fusion_id = ""
		return
	weapons.erase(w_a)
	weapons.erase(w_b)
	weapons.append({"id": fid, "level": FUSION_START_LEVEL, "timer": 0.0})
	SoundManager.play("levelup", 3.0, 0.5)
	screen_shake(6.0, 0.25)
	weapon_fused.emit(WEAPON_DEFS.get(fid, {}).get("name", fid))
	pending_fusion_id = ""
	stats_changed.emit()

func decline_fuse(fid: String) -> void:
	declined_fusions[fid] = true
	pending_fusion_id = ""

func apply_upgrade(id: String) -> void:
	if id.begins_with("new_weapon:"):
		var wid: String = id.substr("new_weapon:".length())
		weapons.append({"id": wid, "level": 1, "timer": 0.0})
		_ensure_orbit_node(wid)
	elif id.begins_with("upgrade_weapon:"):
		var wid: String = id.substr("upgrade_weapon:".length())
		var w := _get_weapon(wid)
		if not w.is_empty():
			w.level = min(MAX_WEAPON_LEVEL, w.level + 1)
			_try_evolve(w, wid)
			_check_fusion_offer(wid)
	elif id.begins_with("passive:"):
		var pid: String = id.substr("passive:".length())
		if not owned_passives.get(pid, false):
			owned_passives[pid] = true
			var pdef: Dictionary = PASSIVE_DEFS[pid]
			match pdef.effect:
				"cooldown":
					global_cooldown_mult = max(0.4, global_cooldown_mult * 0.90)
				"hp":
					max_health += 25.0
					health = max_health
				"damage":
					global_damage_mult *= 1.12
				"pickup":
					base_pickup_radius *= 1.15
					if magnet_timer <= 0.0:
						pickup_radius = base_pickup_radius
				"move":
					speed *= 1.10
			for wid2 in pdef.weapons:
				var w := _get_weapon(wid2)
				if not w.is_empty():
					_try_evolve(w, wid2)
	elif id.begins_with("stat:"):
		var sid: String = id.substr("stat:".length())
		match sid:
			"dmg":
				global_damage_mult *= 1.10
			"speed":
				global_cooldown_mult = max(0.4, global_cooldown_mult * 0.90)
			"hp":
				max_health += 20.0
				health = max_health
			"move":
				speed *= 1.12
			"pickup":
				base_pickup_radius *= 1.25
				if magnet_timer <= 0.0:
					pickup_radius = base_pickup_radius
	stats_changed.emit()
	if pending_fusion_id == "":
		get_tree().paused = false

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	stats_changed.emit()

func add_coins(amount: int) -> void:
	if GameState.hard_mode:
		amount = int(round(amount * HARD_MODE_COIN_MULT))
	coins += amount
	stats_changed.emit()

func activate_magnet(duration: float) -> void:
	magnet_timer = duration
	pickup_radius = 2000.0
