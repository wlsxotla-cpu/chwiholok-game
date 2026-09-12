extends Node2D

@export var spawn_interval: float = 1.4
@export var min_spawn_interval: float = 0.16
@export var difficulty_ramp: float = 0.988

const BOSS_INTERVAL := 150.0
const HORDE_INTERVAL := 50.0
const FIRST_HORDE_DELAY := 110.0
const OVERLORD_TIME := 1200.0
const SAFETY_ENEMY_CEILING := 320

var elapsed: float = 0.0
var spawn_timer: float = 0.0
var heal_spawn_timer: float = 18.0
var boss_spawn_timer: float = BOSS_INTERVAL
var boss_count: int = 0
var horde_timer: float = FIRST_HORDE_DELAY
var overlord_spawned: bool = false
var run_over: bool = false
var tracked_boss: Node = null
var has_tracked_boss: bool = false
var current_overlord_name: String = "천마"
const AUTOSAVE_INTERVAL := 15.0
var autosave_timer: float = AUTOSAVE_INTERVAL
const METEOR_INTERVAL_BASE := 6.5
const METEOR_INTERVAL_MIN := 2.2
const METEOR_RAMP_TIME := 1200.0
var meteor_timer: float = METEOR_INTERVAL_BASE
const RUINS_MIDPOINT_TIME := 600.0
var ruins_midpoint_triggered: bool = false

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	var was_resuming: bool = GameState.resuming_run
	var resume_data: Dictionary = GameState.pending_run_data
	if was_resuming:
		elapsed = float(resume_data.get("elapsed", 0.0))
		boss_spawn_timer = float(resume_data.get("boss_spawn_timer", BOSS_INTERVAL))
		horde_timer = float(resume_data.get("horde_timer", HORDE_INTERVAL))
		boss_count = int(resume_data.get("boss_count", 0))
		overlord_spawned = bool(resume_data.get("overlord_spawned", false))
		ruins_midpoint_triggered = bool(resume_data.get("ruins_midpoint_triggered", false))
		chest_timer = float(resume_data.get("chest_timer", CHEST_FIRST_DELAY))
		grass_broken_count = int(resume_data.get("grass_broken_count", 0))
		chests_opened_count = int(resume_data.get("chests_opened_count", 0))
		GameState.resuming_run = false
		GameState.pending_run_data = {}
	_apply_map_theme()
	_spawn_pets()
	player.died.connect(_on_player_died)
	player.leveled_up.connect(func(options: Array) -> void:
		hud.show_level_up(options)
		hud.set_reroll_state(player.can_reroll_level_up(), player.REROLL_COST)
		_autosave())
	hud.reroll_requested.connect(player.reroll_level_up)
	player.stats_changed.connect(_update_hud)
	player.weapon_evolved.connect(hud.show_evolution)
	player.weapon_fused.connect(hud.show_fusion)
	player.revived.connect(hud.show_revived)
	player.continue_offered.connect(hud.show_continue_offer)
	player.fusion_offered.connect(hud.show_fusion_offer)
	hud.upgrade_chosen.connect(func(id: String) -> void: player.apply_upgrade(id))
	hud.restart_pressed.connect(_on_restart_pressed)
	hud.menu_pressed.connect(_on_menu_pressed)
	hud.dev_action.connect(_on_dev_action)
	hud.continue_confirmed.connect(player.confirm_continue)
	hud.continue_declined.connect(player.decline_continue)
	hud.fusion_confirmed.connect(func(fid: String) -> void:
		player.confirm_fuse(fid)
		player.invincible_timer = max(player.invincible_timer, player.LEVEL_UP_RESUME_INVINCIBLE))
	hud.fusion_declined.connect(func(fid: String) -> void:
		player.decline_fuse(fid)
		player.invincible_timer = max(player.invincible_timer, player.LEVEL_UP_RESUME_INVINCIBLE))
	hud.manual_fuse_requested.connect(player.confirm_fuse)
	hud.altar_offer_confirmed.connect(func() -> void:
		if active_altar != null and is_instance_valid(active_altar):
			active_altar.offer(player)
		active_altar = null)
	hud.altar_offer_declined.connect(func() -> void:
		active_altar = null)
	var char_data: Dictionary = GameState.get_character(GameState.selected_character)
	hud.set_character_name(char_data.name + " [하드]" if GameState.hard_mode else char_data.name)
	_update_hud()
	_spawn_map_props()
	hud.set_prop_counts(chests_opened_count, grass_broken_count)
	if GameState.selected_map == "ruins" and not was_resuming:
		hud.show_map_event_warning("이 곳에서는 캐릭터 고유 능력치와 영구 강화 효과가 대폭 감소합니다")

func _apply_map_theme() -> void:
	var map_data: Dictionary = GameState.get_map(GameState.selected_map)
	var ground: Sprite2D = $Ground
	ground.texture = load(map_data.floor)
	var env: Environment = $WorldEnvironment.environment
	env.background_color = map_data.bg_color
	var wall_tint: Color = map_data.wall_tint
	var is_ruins: bool = GameState.selected_map == "ruins"
	var wall_texture: Texture2D = load("res://assets/sprites/ruins_wall.png") if is_ruins else null
	for wall_name in ["WallTop", "WallBottom", "WallLeft", "WallRight"]:
		var glow: Sprite2D = $Walls.get_node(wall_name + "/Glow")
		glow.modulate = wall_tint
		if is_ruins:
			glow.texture = wall_texture

const GRASS_PROP_COUNT := 26
const CORRIDOR_PROP_COUNT := 14
const RUINS_PROP_COUNT := 18
const RUINS_OBSTACLE_COUNT := 16
const LAVA_CRACK_COUNT := 10
const LAVA_CRACK_SCALE := 1.7
const LAVA_LAKE_COUNT := 4
const RUINS_BOSS_HP_MULT := 1.7
const RUINS_BOSS_XP_MULT := 4.0
const CHEST_INTERVAL := 300.0
const CHEST_FIRST_DELAY := 60.0
const COIN_ALTAR_COUNT := 2
const CORRIDOR_DIVISIONS := 5
const CORRIDOR_GAP_WIDTH := 220.0
const CORRIDOR_WALL_THICKNESS := 48.0
const CORRIDOR_NUB_LENGTH := 90.0
const CORRIDOR_NUB_CHANCE := 0.35
const CORRIDOR_PILLAR_COUNT := 6
const RUINS_MAZE_DIVISIONS := 8
const RUINS_WALL_THICKNESS := 44.0
const RUINS_EXTRA_PASSAGE_RATIO := 0.06
const RUINS_SPAWN_CLEARANCE := 190.0

var grass_broken_count: int = 0
var chests_opened_count: int = 0
var in_grid_layout: bool = false
var chest_timer: float = CHEST_FIRST_DELAY
var active_altar: Node = null
var corridor_cell_centers: Array = []
var corridor_cell_size: float = 0.0

func _spawn_map_props() -> void:
	var in_corridors: bool = GameState.selected_map == "cheonmagung"
	var in_ruins: bool = GameState.selected_map == "ruins"
	var in_grid: bool = in_corridors or in_ruins
	in_grid_layout = in_grid
	if in_corridors:
		_spawn_palace_corridors()
	elif in_ruins:
		_spawn_ruins_maze()

	var prop_scene: PackedScene = preload("res://scenes/GrassProp.tscn") if not in_grid else preload("res://scenes/PalaceVaseProp.tscn")
	var prop_break_color: Color = Color(0.55, 1.0, 0.5, 1.0)
	if in_corridors:
		prop_break_color = Color(0.75, 0.6, 1.0, 1.0)
	elif in_ruins:
		prop_break_color = Color(1.0, 0.55, 0.3, 1.0)
	var prop_count: int = GRASS_PROP_COUNT
	if in_corridors:
		prop_count = CORRIDOR_PROP_COUNT
	elif in_ruins:
		prop_count = RUINS_PROP_COUNT
	for i in range(prop_count):
		var prop := prop_scene.instantiate()
		prop.global_position = _random_cell_safe_pos(100.0) if in_grid else _random_arena_pos(100.0)
		prop.break_spark_color = prop_break_color
		prop.broken_prop.connect(_on_grass_broken)
		add_child(prop)

	if in_grid:
		for i in range(COIN_ALTAR_COUNT):
			var altar := preload("res://scenes/CoinAltar.tscn").instantiate()
			altar.global_position = _random_cell_safe_pos(400.0)
			altar.player_entered_range.connect(_on_altar_range_entered)
			altar.player_exited_range.connect(_on_altar_range_exited)
			add_child(altar)

	if in_ruins:
		for i in range(RUINS_OBSTACLE_COUNT):
			var obstacle := preload("res://scenes/PalaceObstacle.tscn").instantiate()
			obstacle.global_position = _random_cell_safe_pos(260.0)
			add_child(obstacle)
		for i in range(LAVA_CRACK_COUNT):
			var lava := preload("res://scenes/LavaCrack.tscn").instantiate()
			lava.global_position = _random_cell_safe_pos(220.0)
			lava.scale = Vector2(LAVA_CRACK_SCALE, LAVA_CRACK_SCALE)
			add_child(lava)
		for i in range(LAVA_LAKE_COUNT):
			var lake := preload("res://scenes/LavaLake.tscn").instantiate()
			lake.global_position = _random_cell_safe_pos(400.0)
			lake.rotation = randf() * TAU
			add_child(lake)

func _random_cell_safe_pos(min_dist_from_center: float) -> Vector2:
	var tries: int = 0
	while tries < 15:
		var cx: float = corridor_cell_centers[randi() % corridor_cell_centers.size()]
		var cy: float = corridor_cell_centers[randi() % corridor_cell_centers.size()]
		var jitter := Vector2(randf_range(-corridor_cell_size * 0.3, corridor_cell_size * 0.3), randf_range(-corridor_cell_size * 0.3, corridor_cell_size * 0.3))
		var pos := Vector2(cx, cy) + jitter
		if pos.length() >= min_dist_from_center:
			return pos
		tries += 1
	return Vector2(corridor_cell_centers[0], corridor_cell_centers[0])

func _wall_segments_with_gaps(start: float, end: float, gap_centers: Array, gap_width: float) -> Array:
	var cuts: Array = []
	for gc in gap_centers:
		cuts.append([gc - gap_width / 2.0, gc + gap_width / 2.0])
	cuts.sort_custom(func(a, b): return a[0] < b[0])
	var segments: Array = []
	var cursor: float = start
	for cut in cuts:
		if cut[0] > cursor:
			segments.append([cursor, cut[0]])
		cursor = max(cursor, cut[1])
	if cursor < end:
		segments.append([cursor, end])
	return segments

func _add_wall_shape(walls_body: StaticBody2D, center: Vector2, size: Vector2, texture_path: String = "res://assets/sprites/palace_wall.png") -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = center
	walls_body.add_child(col)

	var sprite := Sprite2D.new()
	sprite.texture = load(texture_path)
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, size.x, size.y)
	sprite.centered = true
	sprite.position = center
	walls_body.add_child(sprite)

func _spawn_palace_corridors() -> void:
	var walls_body := StaticBody2D.new()
	walls_body.collision_layer = 32
	walls_body.collision_mask = 0
	walls_body.name = "CorridorWalls"
	add_child(walls_body)

	var half: float = GameState.ARENA_HALF_SIZE
	var cell: float = (half * 2.0) / CORRIDOR_DIVISIONS
	var lines: Array = []
	for i in range(1, CORRIDOR_DIVISIONS):
		lines.append(-half + cell * i)
	var cell_centers: Array = []
	for i in range(CORRIDOR_DIVISIONS):
		cell_centers.append(-half + cell * (i + 0.5))
	corridor_cell_centers = cell_centers
	corridor_cell_size = cell

	var nub_toggle := false
	for y in lines:
		for seg in _wall_segments_with_gaps(-half, half, cell_centers, CORRIDOR_GAP_WIDTH):
			var seg_len: float = seg[1] - seg[0]
			var seg_center_x: float = (seg[0] + seg[1]) / 2.0
			_add_wall_shape(walls_body, Vector2(seg_center_x, y), Vector2(seg_len, CORRIDOR_WALL_THICKNESS))
			if seg_len > CORRIDOR_GAP_WIDTH and randf() < CORRIDOR_NUB_CHANCE:
				nub_toggle = not nub_toggle
				var nub_dir: float = 1.0 if nub_toggle else -1.0
				_add_wall_shape(walls_body, Vector2(seg_center_x, y + nub_dir * CORRIDOR_NUB_LENGTH / 2.0), Vector2(CORRIDOR_WALL_THICKNESS, CORRIDOR_NUB_LENGTH))
	for x in lines:
		for seg in _wall_segments_with_gaps(-half, half, cell_centers, CORRIDOR_GAP_WIDTH):
			var seg_len2: float = seg[1] - seg[0]
			var seg_center_y: float = (seg[0] + seg[1]) / 2.0
			_add_wall_shape(walls_body, Vector2(x, seg_center_y), Vector2(CORRIDOR_WALL_THICKNESS, seg_len2))
			if seg_len2 > CORRIDOR_GAP_WIDTH and randf() < CORRIDOR_NUB_CHANCE:
				nub_toggle = not nub_toggle
				var nub_dir2: float = 1.0 if nub_toggle else -1.0
				_add_wall_shape(walls_body, Vector2(x + nub_dir2 * CORRIDOR_NUB_LENGTH / 2.0, seg_center_y), Vector2(CORRIDOR_NUB_LENGTH, CORRIDOR_WALL_THICKNESS))

	for i in range(CORRIDOR_PILLAR_COUNT):
		var cx: float = cell_centers[randi() % cell_centers.size()]
		var cy: float = cell_centers[randi() % cell_centers.size()]
		var jitter := Vector2(randf_range(-cell * 0.25, cell * 0.25), randf_range(-cell * 0.25, cell * 0.25))
		var pos := Vector2(cx, cy) + jitter
		if pos.length() < 260.0:
			continue
		var obstacle := preload("res://scenes/PalaceObstacle.tscn").instantiate()
		obstacle.global_position = pos
		add_child(obstacle)

func _spawn_ruins_maze() -> void:
	var walls_body := StaticBody2D.new()
	walls_body.collision_layer = 32
	walls_body.collision_mask = 0
	walls_body.name = "RuinsMazeWalls"
	add_child(walls_body)

	var n: int = RUINS_MAZE_DIVISIONS
	var half: float = GameState.ARENA_HALF_SIZE
	var cell: float = (half * 2.0) / float(n)

	var cell_centers: Array = []
	for i in range(n):
		cell_centers.append(-half + cell * (i + 0.5))
	corridor_cell_centers = cell_centers
	corridor_cell_size = cell

	var visited: Array = []
	var open_right: Array = []
	var open_down: Array = []
	for x in range(n):
		var vcol: Array = []
		var rcol: Array = []
		var dcol: Array = []
		for y in range(n):
			vcol.append(false)
			rcol.append(false)
			dcol.append(false)
		visited.append(vcol)
		open_right.append(rcol)
		open_down.append(dcol)

	var stack: Array = []
	var start := Vector2i(randi() % n, randi() % n)
	visited[start.x][start.y] = true
	stack.append(start)
	while not stack.is_empty():
		var cur: Vector2i = stack[stack.size() - 1]
		var neighbors: Array = []
		if cur.x > 0 and not visited[cur.x - 1][cur.y]:
			neighbors.append(Vector2i(cur.x - 1, cur.y))
		if cur.x < n - 1 and not visited[cur.x + 1][cur.y]:
			neighbors.append(Vector2i(cur.x + 1, cur.y))
		if cur.y > 0 and not visited[cur.x][cur.y - 1]:
			neighbors.append(Vector2i(cur.x, cur.y - 1))
		if cur.y < n - 1 and not visited[cur.x][cur.y + 1]:
			neighbors.append(Vector2i(cur.x, cur.y + 1))
		if neighbors.is_empty():
			stack.pop_back()
			continue
		var next: Vector2i = neighbors[randi() % neighbors.size()]
		visited[next.x][next.y] = true
		if next.x == cur.x + 1:
			open_right[cur.x][cur.y] = true
		elif next.x == cur.x - 1:
			open_right[next.x][next.y] = true
		elif next.y == cur.y + 1:
			open_down[cur.x][cur.y] = true
		else:
			open_down[next.x][next.y] = true
		stack.append(next)

	var extra_breaks: int = int(float(n * n) * RUINS_EXTRA_PASSAGE_RATIO)
	for i in range(extra_breaks):
		var x: int = randi() % n
		var y: int = randi() % n
		if randf() < 0.5 and x < n - 1:
			open_right[x][y] = true
		elif y < n - 1:
			open_down[x][y] = true

	for x in range(n):
		for y in range(n):
			var cx: float = -half + cell * (x + 0.5)
			var cy: float = -half + cell * (y + 0.5)
			if x < n - 1 and not open_right[x][y]:
				var c1 := Vector2(cx + cell / 2.0, cy)
				var s1 := Vector2(RUINS_WALL_THICKNESS, cell)
				if not _wall_blocks_spawn(c1, s1):
					_add_wall_shape(walls_body, c1, s1, "res://assets/sprites/ruins_wall.png")
			if y < n - 1 and not open_down[x][y]:
				var c2 := Vector2(cx, cy + cell / 2.0)
				var s2 := Vector2(cell, RUINS_WALL_THICKNESS)
				if not _wall_blocks_spawn(c2, s2):
					_add_wall_shape(walls_body, c2, s2, "res://assets/sprites/ruins_wall.png")

func _wall_blocks_spawn(center: Vector2, size: Vector2) -> bool:
	var half_size: Vector2 = size / 2.0
	var closest := Vector2(
		clamp(0.0, center.x - half_size.x, center.x + half_size.x),
		clamp(0.0, center.y - half_size.y, center.y + half_size.y)
	)
	return closest.length() <= RUINS_SPAWN_CLEARANCE

func _autosave() -> void:
	if run_over:
		return
	var data: Dictionary = player.serialize_state()
	data["character"] = GameState.selected_character
	data["map"] = GameState.selected_map
	data["hard_mode"] = GameState.hard_mode
	data["elapsed"] = elapsed
	data["boss_spawn_timer"] = boss_spawn_timer
	data["horde_timer"] = horde_timer
	data["boss_count"] = boss_count
	data["overlord_spawned"] = overlord_spawned
	data["ruins_midpoint_triggered"] = ruins_midpoint_triggered
	data["chest_timer"] = chest_timer
	data["grass_broken_count"] = grass_broken_count
	data["chests_opened_count"] = chests_opened_count
	GameState.save_run_state(data)

func _on_grass_broken() -> void:
	grass_broken_count += 1
	hud.set_prop_counts(chests_opened_count, grass_broken_count)

func _on_chest_opened() -> void:
	chests_opened_count += 1
	hud.set_prop_counts(chests_opened_count, grass_broken_count)

func _on_altar_range_entered(altar: Node) -> void:
	active_altar = altar
	hud.show_altar_offer(altar.COST, GameState.total_coins + player.coins)

func _on_altar_range_exited(altar: Node) -> void:
	if active_altar == altar:
		active_altar = null
		hud.hide_altar_offer()

func _random_arena_pos(min_dist_from_center: float) -> Vector2:
	var margin: float = 80.0
	var pos: Vector2
	var tries: int = 0
	while tries < 10:
		pos = Vector2(
			randf_range(-GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin),
			randf_range(-GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
		)
		if pos.length() >= min_dist_from_center:
			break
		tries += 1
	return pos

func _process(delta: float) -> void:
	if run_over:
		return
	elapsed += delta
	hud.set_timer(elapsed)

	autosave_timer -= delta
	if autosave_timer <= 0.0:
		autosave_timer = AUTOSAVE_INTERVAL
		_autosave()

	chest_timer -= delta
	if chest_timer <= 0.0:
		chest_timer = CHEST_INTERVAL
		_spawn_chest()

	if GameState.selected_map == "ruins":
		meteor_timer -= delta
		if meteor_timer <= 0.0:
			var ramp_t: float = clamp(elapsed / METEOR_RAMP_TIME, 0.0, 1.0)
			meteor_timer = lerp(METEOR_INTERVAL_BASE, METEOR_INTERVAL_MIN, ramp_t)
			_spawn_meteor_strike()
		if not ruins_midpoint_triggered and elapsed >= RUINS_MIDPOINT_TIME:
			ruins_midpoint_triggered = true
			_trigger_ruins_midpoint_event()

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

	if has_tracked_boss:
		if is_instance_valid(tracked_boss):
			hud.update_boss_health(tracked_boss.health, tracked_boss.max_health)
		else:
			tracked_boss = null
			has_tracked_boss = false
			hud.hide_boss_health()

func _difficulty_divisor() -> float:
	return 130.0 if GameState.hard_mode else 170.0

func _spawn_enemy() -> void:
	var enemy := preload("res://scenes/Enemy.tscn").instantiate()
	enemy.type = _pick_enemy_type()
	enemy.difficulty_mult = 1.0 + elapsed / _difficulty_divisor()
	enemy.use_cheonmagung_skin = GameState.selected_map != "plains"
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
	var boss_name := "보스"
	if GameState.selected_map == "cheonmagung":
		boss.boss_texture_override = GameState.get_character("samahoek").portrait
		boss.use_curse_attack = true
		boss_name = "사마획"
		boss.samahoek_defeated.connect(func() -> void: GameState.record_samahoek_kill())
	elif GameState.selected_map == "ruins":
		boss_name = "친위장"
		boss.boss_texture_override = "res://assets/sprites/enemy_ruins_boss.png"
		boss.use_qi_cannon = true
		boss.xp_mult_override = RUINS_BOSS_XP_MULT
	var base_mult: float = 1.0 + elapsed / _difficulty_divisor()
	var boss_mult: float = base_mult * (1.0 + (boss_count - 1) * 0.45)
	if GameState.selected_map == "ruins":
		boss_mult *= RUINS_BOSS_HP_MULT
	boss.difficulty_mult = boss_mult
	var angle: float = randf() * TAU
	var dist: float = 500.0
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var margin: float = 80.0
	pos.x = clamp(pos.x, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	pos.y = clamp(pos.y, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	boss.global_position = pos
	add_child(boss)
	if not has_tracked_boss or not is_instance_valid(tracked_boss) or tracked_boss.type != Enemy.Type.OVERLORD:
		tracked_boss = boss
		has_tracked_boss = true
		hud.show_boss_health(boss_name, boss.health, boss.max_health)
	hud.show_boss_warning()
	SoundManager.play("levelup", 3.0, 0.6)

func _spawn_horde() -> void:
	var count: int = 44 if GameState.hard_mode else 34
	var base_mult: float = 1.0 + elapsed / _difficulty_divisor()
	for i in range(count):
		var enemy := preload("res://scenes/Enemy.tscn").instantiate()
		enemy.type = _pick_enemy_type()
		enemy.difficulty_mult = base_mult
		enemy.use_cheonmagung_skin = GameState.selected_map != "plains"
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
	current_overlord_name = "천마"
	var base_mult: float = 1.0 + elapsed / _difficulty_divisor()
	if GameState.selected_map == "cheonmagung":
		overlord.boss_texture_override = GameState.get_character("jinak").portrait
		current_overlord_name = "진악"
		overlord.use_halberd_barrage = true
		overlord.speed_override = 140.0
		overlord.difficulty_mult = base_mult * 1.3
	elif GameState.selected_map == "ruins":
		overlord.boss_texture_override = "res://assets/sprites/enemy_cheonma.png"
		current_overlord_name = "천마"
		overlord.use_cheonma_finale = true
		overlord.difficulty_mult = base_mult * 1.6
	else:
		overlord.difficulty_mult = base_mult * 1.3
	var angle: float = randf() * TAU
	var dist: float = 550.0
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var margin: float = 100.0
	pos.x = clamp(pos.x, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	pos.y = clamp(pos.y, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	overlord.global_position = pos
	overlord.overlord_defeated.connect(_on_overlord_defeated)
	add_child(overlord)
	tracked_boss = overlord
	has_tracked_boss = true
	hud.show_boss_health(current_overlord_name, overlord.health, overlord.max_health)
	hud.show_overlord_warning(current_overlord_name)
	SoundManager.play("levelup", 4.0, 0.45)
	screen_shake_all()

func _on_dev_action(action: String) -> void:
	if not GameState.dev_mode:
		return
	match action:
		"heal":
			player.heal(999999.0)
		"kill_all":
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e):
					e.take_damage(9999999.0)
		"max_weapons":
			for w in player.weapons.duplicate():
				w.level = player.MAX_WEAPON_LEVEL
				player._try_evolve(w, w.id)
			for w in player.weapons.duplicate():
				var fid: String = player._fusion_id_for(w.id)
				if fid != "" and player._get_weapon(fid).is_empty():
					var partner: String = player._fusion_partner(w.id)
					var w_partner: Dictionary = player._get_weapon(partner)
					if not w_partner.is_empty() and int(w_partner.level) >= player.MAX_WEAPON_LEVEL:
						player.confirm_fuse(fid)
			player.stats_changed.emit()
		"gain_xp":
			player.gain_xp(999999.0)
		"add_coins":
			player.add_coins(9999)
		"spawn_boss":
			_spawn_boss()
		"spawn_horde":
			_spawn_horde()
		"spawn_overlord":
			_spawn_overlord()

func _on_overlord_defeated() -> void:
	tracked_boss = null
	has_tracked_boss = false
	hud.hide_boss_health()
	hud.show_overlord_defeated(current_overlord_name)
	if GameState.selected_map == "cheonmagung":
		GameState.unlock_jinak_by_clear()
	SoundManager.play("levelup", 5.0, 0.35)
	if player.has_method("screen_shake"):
		player.screen_shake(14.0, 0.6)
	run_over = true
	GameState.add_run_coins(player.coins)
	GameState.clear_run_state()
	var ranking_note: String = ""
	if GameState.dev_mode:
		ranking_note = "관리자 모드 - 랭킹 미등록"
	elif GameState.player_nickname.is_empty():
		ranking_note = "닉네임 미설정 - 랭킹 미등록"
	else:
		ranking_note = "랭킹 등록 중..."
		RankingService.submit_clear(GameState.selected_map, GameState.player_nickname, elapsed, GameState.selected_character)
		RankingService.submit_finished.connect(func(success: bool) -> void:
			hud.set_ranking_note("랭킹 등록 완료!" if success else "랭킹 등록 실패 (네트워크 오류)"), CONNECT_ONE_SHOT)
	get_tree().paused = true
	hud.show_victory(elapsed, current_overlord_name, ranking_note)

	if not GameState.dev_mode and GameState.player_nickname.is_empty():
		var clear_time: float = elapsed
		var map_id: String = GameState.selected_map
		var char_id: String = GameState.selected_character
		hud.show_ranking_nickname_prompt(func(nick: String) -> void:
			RankingService.submit_clear(map_id, nick, clear_time, char_id)
			RankingService.submit_finished.connect(func(success: bool) -> void:
				hud.set_ranking_note("랭킹 등록 완료!" if success else "랭킹 등록 실패 (네트워크 오류)"), CONNECT_ONE_SHOT))

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

func _spawn_chest() -> void:
	var chest := preload("res://scenes/TreasureChest.tscn").instantiate()
	chest.global_position = _random_cell_safe_pos(300.0) if in_grid_layout else _random_arena_pos(300.0)
	chest.chest_opened.connect(_on_chest_opened)
	add_child(chest)
	hud.show_chest_spawned()

func _spawn_meteor_strike() -> void:
	var meteor := preload("res://scenes/MeteorStrike.tscn").instantiate()
	var difficulty_mult: float = 1.0 + elapsed / _difficulty_divisor()
	meteor.damage_mult = 1.0 + (difficulty_mult - 1.0) * 0.6
	var angle: float = randf() * TAU
	var dist: float = randf_range(0.0, 260.0)
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	var margin: float = 90.0
	pos.x = clamp(pos.x, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	pos.y = clamp(pos.y, -GameState.ARENA_HALF_SIZE + margin, GameState.ARENA_HALF_SIZE - margin)
	meteor.global_position = pos
	meteor.struck.connect(screen_shake_all)
	add_child(meteor)

func _spawn_pets() -> void:
	for pet_id in GameState.owned_pets:
		var pet := preload("res://scenes/Pet.tscn").instantiate()
		pet.pet_id = pet_id
		pet.main_ref = self
		player.add_child(pet)

func _trigger_ruins_midpoint_event() -> void:
	hud.show_map_event_warning("귀마의 힘이 강해집니다")
	screen_shake_all()
	for i in range(3):
		get_tree().create_timer(1.0 + float(i) * 2.0).timeout.connect(func() -> void:
			if not run_over:
				_spawn_horde())
	for i in range(5):
		get_tree().create_timer(1.5 + float(i) * 1.2).timeout.connect(func() -> void:
			if not run_over:
				_spawn_boss())
	for i in range(5):
		get_tree().create_timer(float(i) * 2.0).timeout.connect(func() -> void:
			if not run_over:
				_spawn_meteor_strike())

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
	GameState.clear_run_state()
	get_tree().paused = true
	hud.show_game_over(elapsed)

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
