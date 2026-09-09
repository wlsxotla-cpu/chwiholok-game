extends Control

@onready var grid: GridContainer = $Margin/VBox/Grid
@onready var coins_label: Label = $Margin/VBox/CoinsRow/CoinsLabel
@onready var shop_toggle: Button = $Margin/VBox/CoinsRow/ShopToggle
@onready var shop_panel: PanelContainer = $Margin/VBox/ShopPanel
@onready var shop_list: VBoxContainer = $Margin/VBox/ShopPanel/ShopList
@onready var normal_button: Button = $Margin/VBox/DifficultyRow/NormalButton
@onready var hard_button: Button = $Margin/VBox/DifficultyRow/HardButton
@onready var difficulty_desc: Label = $Margin/VBox/DifficultyDesc

func _ready() -> void:
	var version_label := Label.new()
	version_label.text = GameState.VERSION
	version_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	version_label.position = Vector2(6, 4)
	version_label.add_theme_font_size_override("font_size", 11)
	version_label.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55, 0.7))
	add_child(version_label)
	if GameState.dev_mode:
		var dev_label := Label.new()
		dev_label.text = "개발자 모드 — 모든 캐릭터 해금됨"
		dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dev_label.add_theme_font_size_override("font_size", 16)
		dev_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1))
		$Margin/VBox.add_child(dev_label)
		$Margin/VBox.move_child(dev_label, 1)
	shop_toggle.pressed.connect(_on_shop_toggle)
	shop_panel.visible = false
	normal_button.pressed.connect(_on_difficulty_pressed.bind(false))
	hard_button.pressed.connect(_on_difficulty_pressed.bind(true))
	_refresh_difficulty_buttons()
	_refresh_all()

func _on_difficulty_pressed(hard: bool) -> void:
	SoundManager.play("click")
	GameState.hard_mode = hard
	_refresh_difficulty_buttons()

func _refresh_difficulty_buttons() -> void:
	normal_button.button_pressed = not GameState.hard_mode
	hard_button.button_pressed = GameState.hard_mode
	normal_button.modulate = Color(1.3, 1.15, 0.7, 1) if not GameState.hard_mode else Color(0.6, 0.58, 0.55, 1)
	hard_button.modulate = Color(1.4, 0.55, 0.5, 1) if GameState.hard_mode else Color(0.6, 0.58, 0.55, 1)
	if GameState.hard_mode:
		difficulty_desc.text = "몬스터 스폰 속도·최대 마릿수 증가, 강한 몬스터 훨씬 빨리 등장, 시간에 따른 강화 폭도 더 큼"
	else:
		difficulty_desc.text = "기본 난이도"

func _refresh_all() -> void:
	for c in grid.get_children():
		c.queue_free()
	for char_data in GameState.CHARACTERS:
		grid.add_child(_build_card(char_data))
	_refresh_shop()

func _build_card(data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 270)

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
	var unlocked: bool = GameState.is_character_unlocked(data.id)
	if not unlocked:
		portrait.modulate = Color(0.45, 0.43, 0.4, 1)
	vbox.add_child(portrait)

	var name_label := Label.new()
	name_label.text = data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)

	var weapon_label := Label.new()
	weapon_label.text = GameState.WEAPON_NAMES.get(data.get("weapon", ""), "")
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.add_theme_font_size_override("font_size", 15)
	weapon_label.add_theme_color_override("font_color", Color(0.75, 0.7, 0.85, 1))
	vbox.add_child(weapon_label)

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

func _on_buy_pressed(id: String) -> void:
	SoundManager.play("click")
	if GameState.buy_upgrade(id):
		_refresh_all()
