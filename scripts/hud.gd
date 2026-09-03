extends CanvasLayer

signal upgrade_chosen(id: String)
signal restart_pressed
signal menu_pressed

@onready var xp_bar: ProgressBar = $XPBar
@onready var timer_label: Label = $TopRightInfo/TimerLabel
@onready var level_label: Label = $Margin/VBox/CharInfo/NameRow/LevelLabel
@onready var coin_label: Label = $TopRightInfo/CoinLabel
@onready var level_up_panel: Panel = $LevelUpPanel
@onready var option_buttons: Array = [
	$LevelUpPanel/VBox/Option1,
	$LevelUpPanel/VBox/Option2,
	$LevelUpPanel/VBox/Option3,
]
@onready var end_label: Label = $EndLabel
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
@onready var weapon_row: HBoxContainer = $Margin/VBox/WeaponRow
@onready var passive_row: HBoxContainer = $Margin/VBox/PassiveRow
@onready var evolve_label: Label = $EvolveLabel

const MAX_WEAPON_LEVEL := 8

const WEAPON_ICONS := {
	"slash": "res://assets/ui/weapon_icons/slash.png",
	"aura": "res://assets/ui/weapon_icons/aura.png",
	"pierce": "res://assets/ui/weapon_icons/pierce.png",
	"shuriken": "res://assets/ui/weapon_icons/shuriken.png",
	"fireball": "res://assets/ui/weapon_icons/fireball.png",
	"orbit": "res://assets/ui/weapon_icons/orbit.png",
	"boomerang": "res://assets/ui/weapon_icons/boomerang.png",
	"beam": "res://assets/ui/weapon_icons/beam.png",
	"lightning": "res://assets/ui/weapon_icons/lightning.png",
	"heaven_blade": "res://assets/ui/weapon_icons/heaven_blade.png",
	"piercing_calamity": "res://assets/ui/weapon_icons/piercing_calamity.png",
	"whirl_storm": "res://assets/ui/weapon_icons/whirl_storm.png",
	"thunder_formation": "res://assets/ui/weapon_icons/thunder_formation.png",
}

const PASSIVE_ICONS := {
	"power_scroll": "res://assets/ui/passive_icons/power_scroll.png",
	"body_scroll": "res://assets/ui/passive_icons/body_scroll.png",
	"agility_scroll": "res://assets/ui/passive_icons/agility_scroll.png",
	"haste_scroll": "res://assets/ui/passive_icons/haste_scroll.png",
	"gather_scroll": "res://assets/ui/passive_icons/gather_scroll.png",
}

func _ready() -> void:
	level_up_panel.visible = false
	end_label.visible = false
	restart_button.visible = false
	menu_button.visible = false
	pause_panel.visible = false
	restart_button.pressed.connect(func() -> void: SoundManager.play("click"); restart_pressed.emit())
	menu_button.pressed.connect(func() -> void: SoundManager.play("click"); menu_pressed.emit())
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_menu_button.pressed.connect(func() -> void: SoundManager.play("click"); menu_pressed.emit())
	sfx_button.pressed.connect(_on_sfx_toggle)
	music_button.pressed.connect(_on_music_toggle)
	_refresh_sound_buttons()

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

func _on_pause_pressed() -> void:
	SoundManager.play("click")
	get_tree().paused = true
	pause_panel.visible = true

func _on_resume_pressed() -> void:
	SoundManager.play("click")
	get_tree().paused = false
	pause_panel.visible = false

func set_xp(cur: float, needed: float, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = cur
	level_label.text = "Lv. %d" % level

func set_coins(amount: int) -> void:
	coin_label.text = "내공 %d" % amount

func set_character_name(n: String) -> void:
	char_name_label.text = n

func set_stats(max_hp: float, dmg_mult: float) -> void:
	char_stats_label.text = "HP %d · 공격 x%.2f" % [int(max_hp), dmg_mult]

func set_weapons(weapons: Array) -> void:
	for c in weapon_row.get_children():
		c.queue_free()
	for w in weapons:
		var icon_path: String = WEAPON_ICONS.get(w.id, "")
		if icon_path == "":
			continue
		var slot := VBoxContainer.new()
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_theme_constant_override("separation", 0)

		var evolved: bool = w.get("evolved", false)

		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if evolved:
			icon.modulate = Color(1.5, 1.25, 0.6, 1.0)
		slot.add_child(icon)

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

func set_passives(owned_passives: Dictionary) -> void:
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

func show_boss_warning() -> void:
	_show_banner("보스 출현!", Color(1.0, 0.4, 0.35, 1))

func show_horde_warning() -> void:
	_show_banner("몬스터 웨이브!", Color(1.0, 0.65, 0.3, 1))

func show_overlord_warning() -> void:
	_show_banner("천마 강림!!", Color(0.85, 0.4, 1.0, 1))

func _show_banner(text: String, color: Color) -> void:
	evolve_label.text = text
	evolve_label.add_theme_color_override("font_color", color)
	evolve_label.visible = true
	evolve_label.modulate.a = 0.0
	evolve_label.scale = Vector2(0.8, 0.8)
	evolve_label.pivot_offset = evolve_label.size / 2.0
	var tween := create_tween()
	tween.tween_property(evolve_label, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(evolve_label, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.2)
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
	for i in range(3):
		var opt: Dictionary = options[i]
		var btn: Button = option_buttons[i]
		btn.text = "%s\n%s" % [opt["name"], opt["desc"]]
		btn.modulate = KIND_TINTS.get(opt.get("kind", "stat"), Color(1, 1, 1, 1))
		for c in btn.pressed.get_connections():
			btn.pressed.disconnect(c["callable"])
		btn.pressed.connect(_on_option_pressed.bind(opt["id"]))
	level_up_panel.visible = true

func _on_option_pressed(id: String) -> void:
	SoundManager.play("click")
	level_up_panel.visible = false
	upgrade_chosen.emit(id)

func show_game_over(t: float) -> void:
	end_label.text = "쓰러졌다...\n생존 시간 %02d:%02d" % [int(t) / 60, int(t) % 60]
	end_label.visible = true
	restart_button.visible = true
	menu_button.visible = true
	pause_button.visible = false
