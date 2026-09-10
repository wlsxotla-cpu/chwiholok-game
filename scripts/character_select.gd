extends Control

@onready var grid: GridContainer = $Margin/VBox/GridScroll/Grid
@onready var grid_scroll: ScrollContainer = $Margin/VBox/GridScroll
@onready var coins_label: Label = $Margin/VBox/CoinsRow/CoinsLabel
@onready var shop_toggle: Button = $Margin/VBox/CoinsRow/ShopToggle
@onready var shop_panel: PanelContainer = $Margin/VBox/ShopPanel
@onready var shop_list: VBoxContainer = $Margin/VBox/ShopPanel/ShopList
@onready var guide_toggle: Button = $Margin/VBox/CoinsRow/GuideToggle
@onready var guide_panel: PanelContainer = $Margin/VBox/GuidePanel
@onready var guide_list: VBoxContainer = $Margin/VBox/GuidePanel/GuideScroll/GuideList
@onready var normal_button: Button = $Margin/VBox/DifficultyRow/NormalButton
@onready var hard_button: Button = $Margin/VBox/DifficultyRow/HardButton
@onready var difficulty_desc: Label = $Margin/VBox/DifficultyDesc
@onready var map_row: HBoxContainer = $Margin/VBox/MapRow
@onready var map_desc: Label = $Margin/VBox/MapDesc

const Guide = preload("res://scripts/weapon_guide_data.gd")

func _ready() -> void:
	var version_label := Button.new()
	version_label.text = GameState.VERSION
	version_label.flat = true
	version_label.focus_mode = Control.FOCUS_NONE
	version_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	version_label.position = Vector2(6, 4)
	version_label.add_theme_font_size_override("font_size", 11)
	version_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55, 0.7))
	version_label.add_theme_color_override("font_hover_color", Color(0.6, 0.58, 0.55, 0.7))
	version_label.pressed.connect(_show_admin_prompt)
	add_child(version_label)
	if GameState.dev_mode:
		var dev_label := Label.new()
		dev_label.text = "개발자 모드 — 모든 캐릭터 해금됨"
		dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dev_label.add_theme_font_size_override("font_size", 16)
		dev_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1))
		$Margin/VBox.add_child(dev_label)
		$Margin/VBox.move_child(dev_label, 1)

		var dev_coins_btn := Button.new()
		dev_coins_btn.text = "[테스트] 내공 +9999"
		dev_coins_btn.pressed.connect(func() -> void:
			GameState.total_coins += 9999
			_refresh_all())
		$Margin/VBox.add_child(dev_coins_btn)
		$Margin/VBox.move_child(dev_coins_btn, 2)

		var dev_max_btn := Button.new()
		dev_max_btn.text = "[테스트] 모든 강화 만렙"
		dev_max_btn.pressed.connect(func() -> void:
			for id in GameState.META_DEFS.keys():
				GameState.meta_upgrades[id] = int(GameState.META_DEFS[id].max_level)
			_refresh_all())
		$Margin/VBox.add_child(dev_max_btn)
		$Margin/VBox.move_child(dev_max_btn, 3)

		var dev_off_btn := Button.new()
		dev_off_btn.text = "[테스트] 관리자 모드 해제"
		dev_off_btn.pressed.connect(func() -> void:
			GameState.dev_mode = false
			if OS.has_feature("web"):
				JavaScriptBridge.eval("try { localStorage.removeItem('chwiholok_admin_v2'); } catch(e) {}", true)
			get_tree().reload_current_scene())
		$Margin/VBox.add_child(dev_off_btn)
		$Margin/VBox.move_child(dev_off_btn, 4)
	shop_toggle.pressed.connect(_on_shop_toggle)
	shop_panel.visible = false
	guide_toggle.pressed.connect(_on_guide_toggle)
	guide_panel.visible = false
	_build_guide()
	normal_button.pressed.connect(_on_difficulty_pressed.bind(false))
	hard_button.pressed.connect(_on_difficulty_pressed.bind(true))
	_refresh_difficulty_buttons()
	_build_map_buttons()
	_refresh_all()

func _build_map_buttons() -> void:
	for c in map_row.get_children():
		c.queue_free()
	var group := ButtonGroup.new()
	for map_data in GameState.MAPS:
		var btn := Button.new()
		btn.text = map_data.name
		btn.toggle_mode = true
		btn.button_group = group
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_stylebox_override("normal", normal_button.get_theme_stylebox("normal"))
		btn.add_theme_stylebox_override("hover", normal_button.get_theme_stylebox("hover"))
		btn.add_theme_stylebox_override("pressed", normal_button.get_theme_stylebox("pressed"))
		btn.button_pressed = map_data.id == GameState.selected_map
		btn.pressed.connect(_on_map_pressed.bind(map_data.id))
		map_row.add_child(btn)
	_refresh_map_desc()

func _on_map_pressed(id: String) -> void:
	SoundManager.play("click")
	GameState.selected_map = id
	_refresh_map_desc()

func _refresh_map_desc() -> void:
	var map_data: Dictionary = GameState.get_map(GameState.selected_map)
	map_desc.text = map_data.desc

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		if grid_scroll.get_global_rect().has_point(event.position):
			grid_scroll.scroll_vertical -= int(event.relative.y)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if grid_scroll.get_global_rect().has_point(event.position):
			grid_scroll.scroll_vertical -= int(event.relative.y)

func _on_difficulty_pressed(hard: bool) -> void:
	SoundManager.play("click")
	GameState.hard_mode = hard
	_refresh_difficulty_buttons()

func _refresh_difficulty_buttons() -> void:
	normal_button.button_pressed = not GameState.hard_mode
	hard_button.button_pressed = GameState.hard_mode
	if GameState.hard_mode:
		difficulty_desc.text = "몬스터 스폰 속도·최대 마릿수 증가, 강한 몬스터 훨씬 빨리 등장, 시간에 따른 강화 폭도 더 큼 (대신 내공 +30%, 경험치 +15%)"
	else:
		difficulty_desc.text = "기본 난이도"

func _refresh_all() -> void:
	for c in grid.get_children():
		c.queue_free()
	for char_data in GameState.CHARACTERS:
		if not char_data.get("playable", true):
			continue
		grid.add_child(_build_card(char_data))
	_refresh_shop()

func _build_card(data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 270)
	var unlocked: bool = GameState.is_character_unlocked(data.id)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.16, 0.08, 0.06, 0.88) if unlocked else Color(0.1, 0.08, 0.07, 0.8)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color(0.78, 0.6, 0.28, 1) if unlocked else Color(0.35, 0.3, 0.25, 1)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_right = 12
	card_style.corner_radius_bottom_left = 12
	panel.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var portrait := TextureRect.new()
	portrait.texture = load(data.portrait)
	portrait.custom_minimum_size = Vector2(88, 88)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not unlocked:
		portrait.modulate = Color(0.45, 0.43, 0.4, 1)
	vbox.add_child(portrait)

	var name_label := Label.new()
	name_label.text = data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)

	var weapon_row := HBoxContainer.new()
	weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	weapon_row.add_theme_constant_override("separation", 4)
	vbox.add_child(weapon_row)

	var wid: String = data.get("weapon", "")
	var weapon_icon_path: String = Guide.WEAPON_ICONS.get(wid, "")
	if weapon_icon_path != "":
		var weapon_icon := TextureRect.new()
		weapon_icon.texture = load(weapon_icon_path)
		weapon_icon.custom_minimum_size = Vector2(20, 20)
		weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not unlocked:
			weapon_icon.modulate = Color(0.5, 0.48, 0.45, 1)
		weapon_row.add_child(weapon_icon)

	var weapon_label := Label.new()
	weapon_label.text = GameState.WEAPON_NAMES.get(wid, "")
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.add_theme_font_size_override("font_size", 15)
	weapon_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.85, 1))
	weapon_row.add_child(weapon_label)

	var status_label := Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(status_label)

	if unlocked:
		status_label.text = "선택 가능"
		status_label.add_theme_color_override("font_color", Color(0.91, 0.64, 0.24, 1))

		var play_btn := Button.new()
		play_btn.flat = true
		play_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		play_btn.pressed.connect(_on_card_pressed.bind(data.id))
		panel.add_child(play_btn)
	else:
		var cost: int = int(data.get("unlock_cost", 0))
		status_label.text = "내공 %d 필요" % cost
		status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

		var unlock_btn := Button.new()
		unlock_btn.text = "해금 (%d)" % cost
		unlock_btn.disabled = not GameState.can_unlock_character(data.id)
		unlock_btn.pressed.connect(_on_unlock_pressed.bind(data.id))
		vbox.add_child(unlock_btn)

	return panel

func _on_card_pressed(id: String) -> void:
	SoundManager.play("click")
	GameState.selected_character = id
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_unlock_pressed(id: String) -> void:
	SoundManager.play("click")
	if GameState.unlock_character(id):
		_refresh_all()

func _on_shop_toggle() -> void:
	SoundManager.play("click")
	shop_panel.visible = not shop_panel.visible
	if shop_panel.visible:
		guide_panel.visible = false

func _on_guide_toggle() -> void:
	SoundManager.play("click")
	guide_panel.visible = not guide_panel.visible
	if guide_panel.visible:
		shop_panel.visible = false

func _build_guide() -> void:
	_add_guide_header("기본 무기")
	for entry in Guide.BASE_WEAPON_GUIDE:
		_add_guide_weapon_row(entry[0], entry[1], entry[2], Color(0.91, 0.71, 0.24, 1))

	_add_guide_header("무기 진화 — 무기 만렙(8) + 대응 비급 보유 시 진화")
	for entry in Guide.EVOLUTION_GUIDE:
		var pname: String = entry[0]
		var effect: String = entry[1]
		var mapping: String = entry[2]
		_add_guide_text_row(pname, effect, mapping, Color(0.47, 0.82, 0.51, 1))

	_add_guide_header("무기 융합 (보너스) — 몰라도 무방한 히든 콘텐츠")
	for entry in Guide.FUSION_GUIDE:
		var wid: String = entry[0]
		var name_txt: String = entry[1]
		var pair_txt: String = entry[2]
		var desc_txt: String = entry[3]
		_add_guide_weapon_row(wid, name_txt, "%s\n%s" % [pair_txt, desc_txt], Color(0.82, 0.59, 0.92, 1))

	_add_guide_note()

func _add_guide_header(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.93, 0.89, 0.81, 1))
	guide_list.add_child(label)

func _add_guide_weapon_row(wid: String, name_txt: String, desc_txt: String, name_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	guide_list.add_child(row)

	var icon := TextureRect.new()
	if Guide.WEAPON_ICONS.has(wid):
		icon.texture = load(Guide.WEAPON_ICONS[wid])
	icon.custom_minimum_size = Vector2(48, 48)
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

	var desc_label := Label.new()
	desc_label.text = desc_txt
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65, 1))
	info.add_child(desc_label)

func _add_guide_text_row(name_txt: String, effect_txt: String, mapping_txt: String, name_color: Color) -> void:
	var box := VBoxContainer.new()
	guide_list.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)

	var name_label := Label.new()
	name_label.text = name_txt
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", name_color)
	header.add_child(name_label)

	var effect_label := Label.new()
	effect_label.text = effect_txt
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6, 1))
	header.add_child(effect_label)

	var mapping_label := Label.new()
	mapping_label.text = mapping_txt
	mapping_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	mapping_label.add_theme_font_size_override("font_size", 13)
	mapping_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65, 1))
	box.add_child(mapping_label)

func _add_guide_note() -> void:
	var box := VBoxContainer.new()
	guide_list.add_child(box)

	var title := Label.new()
	title.text = "융합, 진짜 무조건 더 강해짐?"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.91, 0.71, 0.24, 1))
	box.add_child(title)

	var body := Label.new()
	body.text = "진화는 즉시 순수 강화라 무조건 이득입니다. 융합은 만렙 무기 2개를 지우고 레벨 5짜리 새 무기로 교체하는 거라, 조건이 되면 게임이 먼저 '합치시겠습니까?' 하고 물어봐요 - 원치 않으면 거절하고 두 무기를 그대로 유지할 수 있고, 나중에 보유 무기 화면에서 언제든 다시 합칠 수 있습니다."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72, 1))
	box.add_child(body)

func _refresh_shop() -> void:
	coins_label.text = "내공 %d" % GameState.total_coins
	for c in shop_list.get_children():
		c.queue_free()
	for id in GameState.META_DEFS.keys():
		shop_list.add_child(_build_shop_row(id))

func _build_shop_row(id: String) -> Control:
	var def: Dictionary = GameState.META_DEFS[id]
	var lvl: int = GameState.meta_upgrades[id]
	var maxed: bool = lvl >= int(def.max_level)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = "%s (Lv.%d/%d)" % [def.name, lvl, def.max_level]
	name_label.add_theme_font_size_override("font_size", 19)
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = def.desc
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6, 1))
	info.add_child(desc_label)

	if lvl > 0:
		var bonus_label := Label.new()
		bonus_label.text = "현재 적용중: %s" % _current_bonus_text(id, lvl)
		bonus_label.add_theme_font_size_override("font_size", 13)
		bonus_label.add_theme_color_override("font_color", Color(0.45, 0.85, 0.5, 1))
		info.add_child(bonus_label)

	var buy_btn := Button.new()
	if maxed:
		buy_btn.text = "MAX"
		buy_btn.disabled = true
	else:
		buy_btn.text = "%d 구매" % GameState.upgrade_cost(id)
		buy_btn.disabled = not GameState.can_upgrade(id)
	buy_btn.pressed.connect(_on_buy_pressed.bind(id))
	row.add_child(buy_btn)

	return row

func _current_bonus_text(id: String, lvl: int) -> String:
	match id:
		"hp":
			return "체력 +%d" % (15 * lvl)
		"dmg":
			return "공격력 +%d%%" % (7 * lvl)
		"move":
			return "이동속도 +%d%%" % (6 * lvl)
		"pickup":
			return "수집 반경 +%d%%" % (10 * lvl)
		"revive_slots":
			return "판당 계속하기 %d회 가능" % (1 + lvl)
		_:
			return ""

func _show_admin_prompt() -> void:
	if GameState.dev_mode:
		return
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-140, -70)
	box.custom_minimum_size = Vector2(280, 140)
	overlay.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var title := Label.new()
	title.text = "관리자 비밀번호"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var input := LineEdit.new()
	input.secret = true
	input.custom_minimum_size = Vector2(0, 44)
	vbox.add_child(input)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	var confirm_btn := Button.new()
	confirm_btn.text = "확인"
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "취소"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cancel_btn)

	cancel_btn.pressed.connect(func() -> void:
		SoundManager.play("click")
		overlay.queue_free())
	var try_submit := func() -> void:
		SoundManager.play("click")
		if input.text.strip_edges().to_lower() == GameState.DEV_KEY.to_lower():
			GameState.dev_mode = true
			if OS.has_feature("web"):
				JavaScriptBridge.eval("try { localStorage.setItem('chwiholok_admin_v2', '1'); } catch(e) {}", true)
			overlay.queue_free()
			_refresh_all()
			_show_toast("관리자 모드 활성화됨")
		else:
			_show_toast("비밀번호가 틀렸습니다")
	confirm_btn.pressed.connect(try_submit)
	input.text_submitted.connect(func(_t: String) -> void: try_submit.call())
	input.grab_focus()

func _on_buy_pressed(id: String) -> void:
	SoundManager.play("click")
	if GameState.buy_upgrade(id):
		var def: Dictionary = GameState.META_DEFS[id]
		_show_toast("%s! %s" % [def.name, def.desc])
		_refresh_all()

func _show_toast(text: String) -> void:
	var toast := Label.new()
	toast.text = text
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2(-140, 90)
	toast.custom_minimum_size = Vector2(280, 0)
	toast.add_theme_font_size_override("font_size", 20)
	toast.add_theme_color_override("font_color", Color(0.45, 0.9, 0.5, 1))
	toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	toast.add_theme_constant_override("outline_size", 6)
	add_child(toast)
	var tween := create_tween()
	tween.tween_property(toast, "position:y", 40, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(toast, "modulate:a", 0.0, 0.9).set_delay(0.5)
	tween.tween_callback(toast.queue_free)
