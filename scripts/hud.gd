extends CanvasLayer

signal upgrade_chosen(id: String)
signal restart_pressed
signal menu_pressed
signal dev_action(action: String)
signal continue_confirmed
signal continue_declined
signal fusion_confirmed(fid: String)
signal fusion_declined(fid: String)
signal manual_fuse_requested(fid: String)
signal reroll_requested
signal altar_offer_confirmed
signal altar_offer_declined

@onready var xp_bar: ProgressBar = $XPBar
@onready var boss_health_panel: VBoxContainer = $BossHealthPanel
@onready var boss_name_label: Label = $BossHealthPanel/BossNameLabel
@onready var boss_health_bar: ProgressBar = $BossHealthPanel/BossHealthBar
@onready var timer_label: Label = $TopRightInfo/TimerLabel
@onready var prop_label: Label = $TopRightInfo/PropLabel
@onready var level_label: Label = $Margin/VBox/CharInfo/NameRow/LevelLabel
@onready var coin_label: Label = $TopRightInfo/CoinLabel
@onready var level_up_panel: Panel = $LevelUpPanel
@onready var option_buttons: Array = [
	$LevelUpPanel/VBox/Option1,
	$LevelUpPanel/VBox/Option2,
	$LevelUpPanel/VBox/Option3,
	$LevelUpPanel/VBox/Option4,
]
@onready var reroll_button: Button = $LevelUpPanel/VBox/RerollButton
@onready var end_label: Label = $EndLabel
@onready var continue_panel: Panel = $ContinuePanel
@onready var continue_cost_label: Label = $ContinuePanel/VBox/CostLabel
@onready var continue_confirm_button: Button = $ContinuePanel/VBox/ConfirmButton
@onready var continue_decline_button: Button = $ContinuePanel/VBox/DeclineButton
@onready var altar_offer_panel: Panel = $AltarOfferPanel
@onready var altar_cost_label: Label = $AltarOfferPanel/VBox/CostLabel
@onready var altar_confirm_button: Button = $AltarOfferPanel/VBox/ConfirmButton
@onready var altar_decline_button: Button = $AltarOfferPanel/VBox/DeclineButton
@onready var fusion_offer_panel: Panel = $FusionOfferPanel
@onready var fusion_desc_label: Label = $FusionOfferPanel/VBox/DescLabel
@onready var fusion_confirm_button: Button = $FusionOfferPanel/VBox/ConfirmButton
@onready var fusion_decline_button: Button = $FusionOfferPanel/VBox/DeclineButton
var pending_fusion_fid: String = ""
@onready var restart_button: Button = $RestartButton
@onready var menu_button: Button = $MenuButton
@onready var pause_button: Button = $PauseButton
@onready var pause_panel: Panel = $PausePanel
@onready var resume_button: Button = $PausePanel/VBox/ResumeButton
@onready var pause_menu_button: Button = $PausePanel/VBox/MenuButton
@onready var char_name_label: Label = $Margin/VBox/CharInfo/NameRow/NameLabel
@onready var char_stats_label: Label = $Margin/VBox/CharInfo/StatsLabel
@onready var sfx_button: Button = $PausePanel/VBox/SfxButton
@onready var music_button: Button = $PausePanel/VBox/MusicButton
@onready var weapon_list_button: Button = $PausePanel/VBox/WeaponListButton
@onready var guide_button: Button = $PausePanel/VBox/GuideButton
@onready var weapon_list_panel: Panel = $WeaponListPanel
@onready var weapon_list: VBoxContainer = $WeaponListPanel/VBox/Scroll/List
@onready var weapon_list_close: Button = $WeaponListPanel/VBox/CloseButton
@onready var ingame_guide_panel: Panel = $InGameGuidePanel
@onready var ingame_guide_list: VBoxContainer = $InGameGuidePanel/VBox/Scroll/List
@onready var ingame_guide_close: Button = $InGameGuidePanel/VBox/CloseButton
@onready var dev_button: Button = $PausePanel/VBox/DevButton
@onready var dev_panel: Panel = $DevPanel
@onready var dev_close: Button = $DevPanel/VBox/CloseButton
@onready var dev_heal_button: Button = $DevPanel/VBox/Scroll/List/HealButton
@onready var dev_kill_all_button: Button = $DevPanel/VBox/Scroll/List/KillAllButton
@onready var dev_max_weapons_button: Button = $DevPanel/VBox/Scroll/List/MaxWeaponsButton
@onready var dev_gain_xp_button: Button = $DevPanel/VBox/Scroll/List/GainXpButton
@onready var dev_add_coins_button: Button = $DevPanel/VBox/Scroll/List/AddCoinsButton
@onready var dev_spawn_boss_button: Button = $DevPanel/VBox/Scroll/List/SpawnBossButton
@onready var dev_spawn_horde_button: Button = $DevPanel/VBox/Scroll/List/SpawnHordeButton
@onready var dev_spawn_overlord_button: Button = $DevPanel/VBox/Scroll/List/SpawnOverlordButton
@onready var weapon_row: HBoxContainer = $Margin/VBox/WeaponRow
@onready var passive_row: HBoxContainer = $Margin/VBox/PassiveRow
@onready var evolve_label: Label = $EvolveLabel

const MAX_WEAPON_LEVEL := 8

const Guide = preload("res://scripts/weapon_guide_data.gd")
const WEAPON_ICONS := Guide.WEAPON_ICONS
const PASSIVE_ICONS := Guide.PASSIVE_ICONS

const PASSIVE_NAMES := Guide.PASSIVE_NAMES

func _ready() -> void:
	level_up_panel.visible = false
	end_label.visible = false
	restart_button.visible = false
	menu_button.visible = false
	pause_panel.visible = false
	continue_panel.visible = false
	continue_confirm_button.pressed.connect(func() -> void:
		SoundManager.play("click")
		continue_panel.visible = false
		continue_confirmed.emit())
	continue_decline_button.pressed.connect(func() -> void:
		SoundManager.play("click")
		continue_panel.visible = false
		continue_declined.emit())

	altar_offer_panel.visible = false
	altar_confirm_button.pressed.connect(func() -> void:
		SoundManager.play("click")
		altar_offer_panel.visible = false
		altar_offer_confirmed.emit())
	altar_decline_button.pressed.connect(func() -> void:
		SoundManager.play("click")
		altar_offer_panel.visible = false
		altar_offer_declined.emit())

	fusion_offer_panel.visible = false
	fusion_confirm_button.pressed.connect(func() -> void:
		SoundManager.play("click")
		fusion_offer_panel.visible = false
		get_tree().paused = false
		fusion_confirmed.emit(pending_fusion_fid))
	fusion_decline_button.pressed.connect(func() -> void:
		SoundManager.play("click")
		fusion_offer_panel.visible = false
		get_tree().paused = false
		fusion_declined.emit(pending_fusion_fid))
	restart_button.pressed.connect(func() -> void: SoundManager.play("click"); restart_pressed.emit())
	menu_button.pressed.connect(func() -> void: SoundManager.play("click"); menu_pressed.emit())
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_menu_button.pressed.connect(func() -> void: SoundManager.play("click"); menu_pressed.emit())
	sfx_button.pressed.connect(_on_sfx_toggle)
	music_button.pressed.connect(_on_music_toggle)
	weapon_list_button.pressed.connect(_on_weapon_list_pressed)
	guide_button.pressed.connect(_on_guide_pressed)
	weapon_list_close.pressed.connect(_on_weapon_list_close)
	ingame_guide_close.pressed.connect(_on_ingame_guide_close)
	weapon_list_panel.visible = false
	ingame_guide_panel.visible = false
	_build_ingame_guide()
	_refresh_sound_buttons()

	dev_button.visible = GameState.dev_mode
	dev_panel.visible = false
	dev_button.pressed.connect(_on_dev_pressed)
	dev_close.pressed.connect(_on_dev_close)
	dev_heal_button.pressed.connect(func() -> void: dev_action.emit("heal"))
	dev_kill_all_button.pressed.connect(func() -> void: dev_action.emit("kill_all"))
	dev_max_weapons_button.pressed.connect(func() -> void: dev_action.emit("max_weapons"))
	dev_gain_xp_button.pressed.connect(func() -> void: dev_action.emit("gain_xp"))
	dev_add_coins_button.pressed.connect(func() -> void: dev_action.emit("add_coins"))
	dev_spawn_boss_button.pressed.connect(func() -> void: dev_action.emit("spawn_boss"))
	dev_spawn_horde_button.pressed.connect(func() -> void: dev_action.emit("spawn_horde"))
	dev_spawn_overlord_button.pressed.connect(func() -> void: dev_action.emit("spawn_overlord"))

func _on_dev_pressed() -> void:
	SoundManager.play("click")
	pause_panel.visible = false
	dev_panel.visible = true

func _on_dev_close() -> void:
	SoundManager.play("click")
	dev_panel.visible = false
	pause_panel.visible = true

func _on_sfx_toggle() -> void:
	SoundManager.set_sfx_enabled(not SoundManager.sfx_enabled)
	SoundManager.play("click")
	_refresh_sound_buttons()

func _on_music_toggle() -> void:
	SoundManager.set_music_enabled(not SoundManager.music_enabled)
	SoundManager.play("click")
	_refresh_sound_buttons()

func _refresh_sound_buttons() -> void:
	sfx_button.text = "효과음: %s" % ("ON" if SoundManager.sfx_enabled else "OFF")
	music_button.text = "음악: %s" % ("ON" if SoundManager.music_enabled else "OFF")

var levelup_hidden_for_pause: bool = false

func _on_pause_pressed() -> void:
	SoundManager.play("click")
	get_tree().paused = true
	if level_up_panel.visible:
		level_up_panel.visible = false
		levelup_hidden_for_pause = true
	pause_panel.visible = true

func _on_resume_pressed() -> void:
	SoundManager.play("click")
	pause_panel.visible = false
	if levelup_hidden_for_pause:
		levelup_hidden_for_pause = false
		level_up_panel.visible = true
	else:
		get_tree().paused = false

func _on_weapon_list_pressed() -> void:
	SoundManager.play("click")
	pause_panel.visible = false
	_refresh_weapon_list()
	weapon_list_panel.visible = true

func _on_weapon_list_close() -> void:
	SoundManager.play("click")
	weapon_list_panel.visible = false
	pause_panel.visible = true

func _on_guide_pressed() -> void:
	SoundManager.play("click")
	pause_panel.visible = false
	ingame_guide_panel.visible = true

func _on_ingame_guide_close() -> void:
	SoundManager.play("click")
	ingame_guide_panel.visible = false
	pause_panel.visible = true

func _refresh_weapon_list() -> void:
	for c in weapon_list.get_children():
		c.queue_free()
	if current_weapons.is_empty():
		var empty_label := Label.new()
		empty_label.text = "보유 무기 없음"
		weapon_list.add_child(empty_label)
	for w in current_weapons:
		var evolved: bool = w.get("evolved", false)
		var name_txt: String = Guide.EVOLVED_NAMES.get(w.id, Guide.WEAPON_NAMES.get(w.id, w.id)) if evolved else Guide.WEAPON_NAMES.get(w.id, w.id)
		var maxed: bool = int(w.level) >= MAX_WEAPON_LEVEL
		var status: String
		if evolved:
			status = "진화 완료"
		elif maxed:
			status = "만렙 (8)"
		else:
			status = "Lv.%d / 8" % int(w.level)
		_add_weapon_list_row(w.id, name_txt, status, Color(0.98, 0.82, 0.35, 1) if evolved else Color(0.9, 0.87, 0.8, 1))

	if not current_passives.is_empty():
		var sep := Label.new()
		sep.text = "보유 비급"
		sep.add_theme_font_size_override("font_size", 18)
		sep.add_theme_color_override("font_color", Color(0.93, 0.89, 0.81, 1))
		weapon_list.add_child(sep)
		for pid in PASSIVE_ICONS.keys():
			if not current_passives.get(pid, false):
				continue
			_add_passive_list_row(pid, PASSIVE_NAMES.get(pid, pid))

	_add_weapon_paths_section()

func _add_weapon_paths_section() -> void:
	var owned: Dictionary = {}
	for w in current_weapons:
		owned[w.id] = w

	var shown_fusions: Dictionary = {}
	var rows: Array = []

	for w in current_weapons:
		if Guide.EVOLUTION_PASSIVE.has(w.id) and not w.get("evolved", false):
			var pid: String = Guide.EVOLUTION_PASSIVE[w.id]
			var passive_owned: bool = current_passives.get(pid, false)
			var mine_maxed2: bool = int(w.level) >= MAX_WEAPON_LEVEL
			var status2: String
			var ready2: bool = false
			if not passive_owned:
				status2 = "%s 비급 필요" % PASSIVE_NAMES.get(pid, pid)
			elif not mine_maxed2:
				status2 = "만렙(8) 필요"
			else:
				status2 = "진화 조건 충족!"
				ready2 = true
			rows.append({"kind": "evolution", "a": w.id, "pid": pid, "p_owned": passive_owned, "result": Guide.EVOLVED_NAMES.get(w.id, w.id), "status": status2, "ready": ready2})

		for fused_id in Guide.FUSION_PAIRS.keys():
			var pair: Array = Guide.FUSION_PAIRS[fused_id]
			if pair.has(w.id) and not shown_fusions.has(fused_id):
				shown_fusions[fused_id] = true
				var partner_id: String = pair[1] if pair[0] == w.id else pair[0]
				var partner_owned: bool = owned.has(partner_id)
				var mine_maxed: bool = int(w.level) >= MAX_WEAPON_LEVEL
				var status: String
				var ready: bool = false
				if not partner_owned:
					status = "%s 획득 필요" % Guide.WEAPON_NAMES.get(partner_id, partner_id)
				elif not (mine_maxed and int(owned[partner_id].level) >= MAX_WEAPON_LEVEL):
					status = "둘 다 만렙(8) 필요"
				else:
					status = "합체 조건 충족!"
					ready = true
				rows.append({"kind": "fusion", "a": w.id, "b": partner_id, "b_owned": partner_owned, "result": fused_id, "status": status, "ready": ready})

	if rows.is_empty():
		return

	var sep2 := Label.new()
	sep2.text = "진화·융합(보너스) 경로"
	sep2.add_theme_font_size_override("font_size", 18)
	sep2.add_theme_color_override("font_color", Color(0.93, 0.89, 0.81, 1))
	weapon_list.add_child(sep2)

	for r in rows:
		if r.kind == "fusion":
			_add_path_row(r.a, r.b, r.b_owned, WEAPON_ICONS.get(r.result, ""), Guide.WEAPON_NAMES.get(r.result, r.result), r.status, r.ready, false, r.result)
		else:
			_add_path_row(r.a, r.pid, r.p_owned, "", r.result, r.status, r.ready, true)

func _add_path_row(a_id: String, b_id: String, b_owned: bool, result_icon_path: String, result_name: String, status_txt: String, ready: bool, b_is_passive: bool = false, fusion_fid: String = "") -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	weapon_list.add_child(box)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)

	row.add_child(_path_icon(WEAPON_ICONS.get(a_id, ""), true))
	row.add_child(_path_plus_label())
	row.add_child(_path_icon(PASSIVE_ICONS.get(b_id, "") if b_is_passive else WEAPON_ICONS.get(b_id, ""), b_owned))
	row.add_child(_path_plus_label("="))
	if result_icon_path != "":
		row.add_child(_path_icon(result_icon_path, true))
	var result_label := Label.new()
	result_label.text = result_name
	result_label.add_theme_font_size_override("font_size", 15)
	result_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35, 1) if ready else Color(0.75, 0.7, 0.65, 1))
	row.add_child(result_label)

	var status_label := Label.new()
	status_label.text = status_txt
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.47, 0.9, 0.5, 1) if ready else Color(0.65, 0.6, 0.55, 1))
	box.add_child(status_label)

	if ready and fusion_fid != "":
		var fuse_now_btn := Button.new()
		fuse_now_btn.text = "지금 합치기"
		fuse_now_btn.custom_minimum_size = Vector2(0, 44)
		fuse_now_btn.pressed.connect(func() -> void:
			SoundManager.play("click")
			manual_fuse_requested.emit(fusion_fid)
			_refresh_weapon_list())
		box.add_child(fuse_now_btn)

func _path_icon(icon_path: String, owned: bool) -> TextureRect:
	var icon := TextureRect.new()
	if icon_path != "":
		icon.texture = load(icon_path)
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not owned:
		icon.modulate = Color(0.4, 0.4, 0.4, 1)
	return icon

func _path_plus_label(txt: String = "+") -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55, 1))
	return l

func _add_weapon_list_row(wid: String, name_txt: String, status_txt: String, name_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	weapon_list.add_child(row)

	var icon := TextureRect.new()
	if WEAPON_ICONS.has(wid):
		icon.texture = load(WEAPON_ICONS[wid])
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = name_txt
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", name_color)
	info.add_child(name_label)

	var status_label := Label.new()
	status_label.text = status_txt
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6, 1))
	info.add_child(status_label)

func _add_passive_list_row(pid: String, name_txt: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	weapon_list.add_child(row)

	var icon := TextureRect.new()
	if PASSIVE_ICONS.has(pid):
		icon.texture = load(PASSIVE_ICONS[pid])
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = name_txt
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.47, 0.82, 0.51, 1))
	row.add_child(name_label)

func _build_ingame_guide() -> void:
	_add_guide_header("기본 무기")
	for entry in Guide.BASE_WEAPON_GUIDE:
		_add_guide_weapon_row(entry[0], entry[1], entry[2], Color(0.91, 0.71, 0.24, 1))

	_add_guide_header("무기 진화 — 무기 만렙(8) + 대응 비급 보유 시 진화")
	for entry in Guide.EVOLUTION_GUIDE:
		_add_guide_text_row(entry[0], entry[1], entry[2])

	_add_guide_header("무기 융합 (보너스) — 몰라도 무방한 히든 콘텐츠")
	for entry in Guide.FUSION_GUIDE:
		_add_guide_weapon_row(entry[0], entry[1], "%s\n%s" % [entry[2], entry[3]], Color(0.82, 0.59, 0.92, 1))

func _add_guide_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.93, 0.89, 0.81, 1))
	ingame_guide_list.add_child(label)

func _add_guide_weapon_row(wid: String, name_txt: String, desc_txt: String, name_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	ingame_guide_list.add_child(row)

	var icon := TextureRect.new()
	if WEAPON_ICONS.has(wid):
		icon.texture = load(WEAPON_ICONS[wid])
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = name_txt
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", name_color)
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = desc_txt
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65, 1))
	info.add_child(desc_label)

func _add_guide_text_row(name_txt: String, effect_txt: String, mapping_txt: String) -> void:
	var box := VBoxContainer.new()
	ingame_guide_list.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)

	var name_label := Label.new()
	name_label.text = name_txt
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(0.47, 0.82, 0.51, 1))
	header.add_child(name_label)

	var effect_label := Label.new()
	effect_label.text = effect_txt
	effect_label.add_theme_font_size_override("font_size", 13)
	effect_label.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6, 1))
	header.add_child(effect_label)

	var mapping_label := Label.new()
	mapping_label.text = mapping_txt
	mapping_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	mapping_label.add_theme_font_size_override("font_size", 12)
	mapping_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65, 1))
	box.add_child(mapping_label)

func set_xp(cur: float, needed: float, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = cur
	level_label.text = "Lv. %d" % level

func set_coins(amount: int) -> void:
	coin_label.text = "내공 %d" % amount

func set_prop_counts(chests: int, grass: int) -> void:
	prop_label.text = "상자 %d · 풀숲 %d" % [chests, grass]

func set_character_name(n: String) -> void:
	char_name_label.text = n

func set_stats(max_hp: float, dmg_mult: float) -> void:
	char_stats_label.text = "HP %d · 공격 x%.2f" % [int(max_hp), dmg_mult]

var current_weapons: Array = []
var current_passives: Dictionary = {}

func set_weapons(weapons: Array) -> void:
	current_weapons = weapons
	for c in weapon_row.get_children():
		c.queue_free()
	var owned_ids: Dictionary = {}
	for w in weapons:
		owned_ids[w.id] = w
	for w in weapons:
		var icon_path: String = WEAPON_ICONS.get(w.id, "")
		if icon_path == "":
			continue
		var slot := VBoxContainer.new()
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_theme_constant_override("separation", 0)

		var evolved: bool = w.get("evolved", false)

		var icon_wrap := Control.new()
		icon_wrap.custom_minimum_size = Vector2(36, 36)
		slot.add_child(icon_wrap)

		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if evolved:
			icon.modulate = Color(1.5, 1.25, 0.6, 1.0)
		icon_wrap.add_child(icon)

		if not evolved:
			var combo_state: String = _fusion_combo_state(w, owned_ids)
			if combo_state != "":
				var combo_dot := Control.new()
				combo_dot.size = Vector2(10, 10)
				combo_dot.position = Vector2(27, -1)
				var dot_color: Color = Color(1.0, 0.85, 0.3, 1.0) if combo_state == "close" else Color(0.6, 0.6, 0.6, 0.9)
				combo_dot.draw.connect(func() -> void:
					combo_dot.draw_circle(Vector2(5, 5), 5.0, dot_color)
					combo_dot.draw_arc(Vector2(5, 5), 5.0, 0, TAU, 16, Color(0.1, 0.08, 0.06, 1), 1.5))
				icon_wrap.add_child(combo_dot)

		var maxed: bool = int(w.level) >= MAX_WEAPON_LEVEL
		var lvl_label := Label.new()
		if evolved:
			lvl_label.text = "진화"
		elif maxed:
			lvl_label.text = "만렙"
		else:
			lvl_label.text = "Lv%d" % int(w.level)
		lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_label.add_theme_font_size_override("font_size", 13)
		lvl_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.3, 1) if maxed else Color(0.85, 0.8, 0.72, 1))
		slot.add_child(lvl_label)

		weapon_row.add_child(slot)

func _fusion_combo_state(w: Dictionary, owned_ids: Dictionary) -> String:
	for fused_id in Guide.FUSION_PAIRS.keys():
		var pair: Array = Guide.FUSION_PAIRS[fused_id]
		if not pair.has(w.id):
			continue
		var partner_id: String = pair[1] if pair[0] == w.id else pair[0]
		if not owned_ids.has(partner_id):
			return "distant"
		var partner: Dictionary = owned_ids[partner_id]
		if int(w.level) >= MAX_WEAPON_LEVEL and int(partner.level) >= MAX_WEAPON_LEVEL:
			return ""
		return "close"
	return ""

func set_passives(owned_passives: Dictionary) -> void:
	current_passives = owned_passives
	for c in passive_row.get_children():
		c.queue_free()
	for pid in PASSIVE_ICONS.keys():
		if not owned_passives.get(pid, false):
			continue
		var icon := TextureRect.new()
		icon.texture = load(PASSIVE_ICONS[pid])
		icon.custom_minimum_size = Vector2(26, 26)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		passive_row.add_child(icon)

func show_evolution(weapon_name: String) -> void:
	_show_banner("진화! %s" % weapon_name, Color(0.98, 0.82, 0.35, 1))

func show_fusion(weapon_name: String) -> void:
	_show_banner("무기 합체! %s" % weapon_name, Color(1.0, 0.95, 0.6, 1))

func show_boss_health(boss_name: String, current: float, max_hp: float) -> void:
	boss_name_label.text = boss_name
	boss_health_bar.max_value = max(max_hp, 1.0)
	boss_health_bar.value = current
	boss_health_panel.visible = true

func update_boss_health(current: float, max_hp: float) -> void:
	boss_health_bar.max_value = max(max_hp, 1.0)
	boss_health_bar.value = current

func hide_boss_health() -> void:
	boss_health_panel.visible = false

func show_boss_warning() -> void:
	_show_banner("보스 출현!", Color(1.0, 0.4, 0.35, 1))

func show_horde_warning() -> void:
	_show_banner("몬스터 웨이브!", Color(1.0, 0.65, 0.3, 1))

func show_chest_spawned() -> void:
	_show_banner("보물상자 출현!", Color(0.95, 0.82, 0.35, 1))

func show_overlord_warning(boss_name: String = "천마") -> void:
	_show_banner("%s 강림!!" % boss_name, Color(0.85, 0.4, 1.0, 1))

func show_overlord_defeated(boss_name: String = "천마") -> void:
	_show_banner("%s 격파! 천하제일이 되었다!" % boss_name, Color(1.0, 0.85, 0.3, 1))

func show_revived() -> void:
	_show_banner("환생!", Color(0.55, 0.9, 1.0, 1))

func show_map_event_warning(text: String) -> void:
	_show_banner(text, Color(1.0, 0.25, 0.2, 1), 3.0)

func _show_banner(text: String, color: Color, hold: float = 1.2) -> void:
	evolve_label.text = text
	evolve_label.add_theme_color_override("font_color", color)
	evolve_label.visible = true
	evolve_label.modulate.a = 0.0
	evolve_label.scale = Vector2(0.8, 0.8)
	evolve_label.pivot_offset = evolve_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(evolve_label, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(evolve_label, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold)
	tween.tween_property(evolve_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void: evolve_label.visible = false)

func set_timer(t: float) -> void:
	t = max(0.0, t)
	var m: int = int(t) / 60
	var s: int = int(t) % 60
	timer_label.text = "생존 %02d:%02d" % [m, s]

const KIND_TINTS := {
	"new_weapon": Color(1.25, 1.05, 0.55),
	"upgrade_weapon": Color(0.7, 0.95, 1.25),
	"stat": Color(0.8, 1.2, 0.75),
	"passive": Color(1.3, 0.85, 1.2),
}

func show_level_up(options: Array) -> void:
	for i in range(option_buttons.size()):
		var btn: Button = option_buttons[i]
		if i >= options.size():
			btn.visible = false
			continue
		btn.visible = true
		var opt: Dictionary = options[i]
		btn.text = "%s\n%s" % [opt["name"], opt["desc"]]
		btn.modulate = KIND_TINTS.get(opt.get("kind", "stat"), Color(1, 1, 1, 1))
		for c in btn.pressed.get_connections():
			btn.pressed.disconnect(c["callable"])
		btn.pressed.connect(_on_option_pressed.bind(opt["id"]))
	level_up_panel.visible = true

func set_reroll_state(available: bool, cost: int) -> void:
	reroll_button.disabled = not available
	reroll_button.text = "다시 뽑기 (내공 %d)" % cost if available else "다시 뽑기 불가"

func _on_option_pressed(id: String) -> void:
	SoundManager.play("click")
	level_up_panel.visible = false
	upgrade_chosen.emit(id)

func show_fusion_offer(fid: String, wid: String, partner: String) -> void:
	pending_fusion_fid = fid
	var a_name: String = Guide.WEAPON_NAMES.get(wid, wid)
	var b_name: String = Guide.WEAPON_NAMES.get(partner, partner)
	var result_name: String = Guide.WEAPON_NAMES.get(fid, fid)
	fusion_desc_label.text = "%s + %s를 합쳐서 %s로 만드시겠습니까?" % [a_name, b_name, result_name]
	fusion_offer_panel.visible = true

func show_continue_offer(cost: int, available: int) -> void:
	var can_afford: bool = available >= cost
	continue_cost_label.text = "내공 %d을 써서 계속하시겠습니까?\n(보유 내공: %d)" % [cost, available]
	continue_confirm_button.disabled = not can_afford
	continue_confirm_button.text = "계속하기" if can_afford else "내공 부족"
	continue_panel.visible = true

func show_altar_offer(cost: int, available: int) -> void:
	var can_afford: bool = available >= cost
	altar_cost_label.text = "내공 %d을 제물로 바치시겠습니까?\n(보유 내공: %d)\n체력 30%% 회복 + 즉시 레벨업" % [cost, available]
	altar_confirm_button.disabled = not can_afford
	altar_confirm_button.text = "제물 바치기" if can_afford else "내공 부족"
	altar_offer_panel.visible = true

func hide_altar_offer() -> void:
	altar_offer_panel.visible = false

func show_game_over(t: float) -> void:
	end_label.text = "쓰러졌다...\n생존 시간 %02d:%02d" % [int(t) / 60, int(t) % 60]
	end_label.visible = true
	restart_button.visible = true
	menu_button.visible = true
	pause_button.visible = false

func show_victory(t: float, boss_name: String, ranking_note: String = "") -> void:
	end_label.text = "%s 격파! 천하제일이 되었다!\n클리어 시간 %02d:%02d" % [boss_name, int(t) / 60, int(t) % 60]
	if ranking_note != "":
		end_label.text += "\n" + ranking_note
	end_label.visible = true
	restart_button.visible = true
	menu_button.visible = true
	pause_button.visible = false

func set_ranking_note(note: String) -> void:
	var lines: PackedStringArray = end_label.text.split("\n")
	if lines.size() >= 3:
		lines[2] = note
	else:
		lines.append(note)
	end_label.text = "\n".join(lines)

func show_ranking_nickname_prompt(on_registered: Callable) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(300, 60)
	box.position = Vector2(-150, -110)
	overlay.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var title := Label.new()
	title.text = "랭킹에 등록하려면 닉네임이 필요해요"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var edit := LineEdit.new()
	edit.placeholder_text = "닉네임 (최대 12자)"
	edit.max_length = 12
	edit.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(edit)

	var status := Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6, 1))
	vbox.add_child(status)

	var confirm_btn := Button.new()
	confirm_btn.text = "등록하고 랭킹 저장"
	confirm_btn.custom_minimum_size = Vector2(0, 48)
	vbox.add_child(confirm_btn)

	var skip_btn := Button.new()
	skip_btn.text = "괜찮아요 (랭킹 미참여)"
	skip_btn.flat = true
	vbox.add_child(skip_btn)

	skip_btn.pressed.connect(func() -> void:
		SoundManager.play("click")
		GameState.mark_nickname_prompt_shown()
		overlay.queue_free())

	confirm_btn.pressed.connect(func() -> void:
		var nick: String = edit.text.strip_edges()
		if nick.is_empty():
			status.text = "닉네임을 입력해주세요"
			status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1))
			return
		confirm_btn.disabled = true
		status.text = "확인 중..."
		status.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6, 1))
		RankingService.claim_nickname(nick))

	RankingService.nickname_claim_result.connect(func(success: bool, nick: String, reason: String) -> void:
		if not is_instance_valid(confirm_btn):
			return
		confirm_btn.disabled = false
		if success:
			GameState.set_nickname(nick)
			GameState.mark_nickname_prompt_shown()
			status.text = "등록 완료! 랭킹 제출 중..."
			status.add_theme_color_override("font_color", Color(0.55, 0.9, 0.6, 1))
			SoundManager.play("levelup", 3.0, 1.2)
			on_registered.call(nick)
			await get_tree().create_timer(0.6).timeout
			if is_instance_valid(overlay):
				overlay.queue_free()
		elif reason == "taken":
			status.text = "이미 사용 중인 닉네임입니다"
			status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1))
		elif reason != "empty":
			status.text = "네트워크 오류, 다시 시도해주세요"
			status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1)))

	edit.grab_focus()
	edit.text_submitted.connect(func(_t: String) -> void: confirm_btn.pressed.emit())
