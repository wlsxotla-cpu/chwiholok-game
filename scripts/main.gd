extends Node2D

@export var spawn_interval: float = 2.3
@export var min_spawn_interval: float = 0.25
@export var difficulty_ramp: float = 0.992

const BOSS_INTERVAL := 150.0
const HORDE_INTERVAL := 50.0
const FIRST_HORDE_DELAY := 110.0
const OVERLORD_TIME := 1800.0
const SAFETY_ENEMY_CEILING := 220

var elapsed: float = 0.0
var spawn_timer: float = 0.0
var heal_spawn_timer: float = 18.0
var boss_spawn_timer: float = BOSS_INTERVAL
var boss_count: int = 0
var horde_timer: float = FIRST_HORDE_DELAY
var overlord_spawned: bool = false
var run_over: bool = false

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	if GameState.hard_mode:
		spawn_interval *= 0.7
		min_spawn_interval *= 0.7
		difficulty_ramp = 0.988
	player.died.connect(_on_player_died)
	player.leveled_up.connect(hud.show_level_up)
	player.stats_changed.connect(_update_hud)
	player.weapon_evolved.connect(hud.show_evolution)
	player.weapon_fused.connect(hud.show_fusion)
	player.revived.connect(hud.show_revived)
	hud.upgrade_chosen.connect(func(id: String) -> void: player.apply_upgrade(id))
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.menu_pressed.connect(_on_menu_pressed)
	var char_data: Dictionary = GameState.get_character(GameState.selected_character)
	hud.set_character_name(char_data.name + " [하드]" if GameState.hard_mode else char_data.name)
	_update_hud()

func _process(delta: float) -> void:
	if run_over:
		return
	elapsed += delta
	hud.set_timer(elapsed)

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = spawn_interval
		spawn_interval = max(min_spawn_interval, spawn_interval * difficulty_ramp)
		if get_tree().get_nodes_in_group("enemies").size() < SAFETY_ENEMY_CEILING:
			_spawn_enemy()

	heal_spawn_timer -= delta
	if heal_spawn_timer <= 0.0:
		_spawn_heal()
		heal_spawn_timer = randf_range(22.0, 32.0)

	boss_spawn_timer -= delta
	if boss_spawn_timer <= 0.0:
		boss_spawn_timer = BOSS_INTERVAL
		_spawn_boss()

	horde_timer -= delta
	if horde_timer <= 0.0:
		horde_timer = HORDE_INTERVAL
		_spawn_horde()

	if not overlord_spawned and elapsed >= OVERLORD_TIME:
		overlord_spawned = true
		_spawn_overlord()

func _difficulty_divisor() -> float:
	return 130.0 if GameState.hard_mode else 170.0

func _spawn_enemy() -> void:
	var enemy := preload("res://scenes/Enemy.tscn").instantiate()
	enemy.type = _pick_enemy_type()
	enemy.difficulty_mult = 1.0 + elapsed / _difficulty_divisor()
	var angle: float = randf() * TAU
	var dist: float = 420.0
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var margin: float = 60.0
	pos.x = clamp(pos.x, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	pos.y = clamp(pos.y, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	enemy.global_position = pos
	add_child(enemy)

func _spawn_boss() -> void:
	boss_count += 1
	var boss := preload("res://scenes/Enemy.tscn").instantiate()
	boss.type = Enemy.Type.BOSS
	var base_mult: float = 1.0 + elapsed / _difficulty_divisor()
	boss.difficulty_mult = base_mult * (1.0 + (boss_count - 1) * 0.45)
	var angle: float = randf() * TAU
	var dist: float = 500.0
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var margin: float = 80.0
	pos.x = clamp(pos.x, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	pos.y = clamp(pos.y, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	boss.global_position = pos
	add_child(boss)
	hud.show_boss_warning()
	SoundManager.play("levelup", 3.0, 0.6)

func _spawn_horde() -> void:
	var count: int = 32 if GameState.hard_mode else 24
	var base_mult: float = 1.0 + elapsed / _difficulty_divisor()
	for i in range(count):
		var enemy := preload("res://scenes/Enemy.tscn").instantiate()
		enemy.type = _pick_enemy_type()
		enemy.difficulty_mult = base_mult
		var angle: float = TAU * i / float(count)
		var dist: float = 420.0 if i % 2 == 0 else 560.0
		var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
		var margin: float = 60.0
		pos.x = clamp(pos.x, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
		pos.y = clamp(pos.y, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
		enemy.global_position = pos
		add_child(enemy)
	hud.show_horde_warning()
	SoundManager.play("explosion", -2.0, 0.85)

func _spawn_overlord() -> void:
	var overlord := preload("res://scenes/Enemy.tscn").instantiate()
	overlord.type = Enemy.Type.OVERLORD
	var base_mult: float = 1.0 + elapsed / _difficulty_divisor()
	overlord.difficulty_mult = base_mult * 3.0
	var angle: float = randf() * TAU
	var dist: float = 550.0
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var margin: float = 100.0
	pos.x = clamp(pos.x, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	pos.y = clamp(pos.y, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	overlord.global_position = pos
	overlord.overlord_defeated.connect(_on_overlord_defeated)
	add_child(overlord)
	hud.show_overlord_warning()
	SoundManager.play("levelup", 4.0, 0.45)
	screen_shake_all()

func _on_overlord_defeated() -> void:
	hud.show_overlord_defeated()
	SoundManager.play("levelup", 5.0, 0.35)
	if player.has_method("screen_shake"):
		player.screen_shake(14.0, 0.6)

func screen_shake_all() -> void:
	if player.has_method("screen_shake"):
		player.screen_shake(8.0, 0.4)

func _pick_enemy_type() -> int:
	var t: float = elapsed * (1.6 if GameState.hard_mode else 1.0)
	var pool: Array = [Enemy.Type.GRUNT, Enemy.Type.GRUNT, Enemy.Type.GRUNT]
	if t > 40.0:
		pool.append(Enemy.Type.ARCHER)
	if t > 55.0:
		pool.append(Enemy.Type.BRUTE)
	if t > 75.0:
		pool.append(Enemy.Type.STRIKER)
	if t > 90.0:
		pool.append(Enemy.Type.BOMBER)
	return pool[randi() % pool.size()]

func _spawn_heal() -> void:
	var heal := preload("res://scenes/Pickup.tscn").instantiate()
	heal.type = heal.Type.HEAL
	heal.value = 25.0
	var angle: float = randf() * TAU
	var dist: float = randf_range(120.0, 300.0)
	heal.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	add_child(heal)

func _update_hud() -> void:
	hud.set_xp(player.xp, player.xp_to_level, player.level)
	hud.set_coins(player.coins)
	hud.set_stats(player.max_health, player.global_damage_mult)
	hud.set_weapons(player.weapons)
	hud.set_passives(player.owned_passives)

func _on_player_died() -> void:
	run_over = true
	GameState.add_run_coins(player.coins)
	get_tree().paused = true
	hud.show_game_over(elapsed)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
