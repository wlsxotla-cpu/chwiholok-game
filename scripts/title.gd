extends Control

@onready var prompt: Label = $Center/VBox/Prompt
@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var eyebrow: Label = $Center/VBox/Eyebrow
@onready var portrait_row: HBoxContainer = $PortraitRow
@onready var embers: Node2D = $Embers

const Changelog = preload("res://scripts/changelog_data.gd")

var going: bool = false
var ember_timer: float = 0.0
var pending_update: bool = false

func _ready() -> void:
	_build_portraits()
	_animate_intro()
	$TapCatcher.pressed.connect(_go)

	var blink := create_tween().set_loops()
	blink.tween_property(prompt, "modulate:a", 0.25, 0.8).set_trans(Tween.TRANS_SINE)
	blink.tween_property(prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	var log_btn := Button.new()
	log_btn.text = "업데이트 기록"
	log_btn.flat = true
	log_btn.focus_mode = Control.FOCUS_NONE
	log_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	log_btn.position = Vector2(-118, -34)
	log_btn.size = Vector2(110, 28)
	log_btn.add_theme_font_size_override("font_size", 12)
	log_btn.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55, 0.7))
	log_btn.add_theme_color_override("font_hover_color", Color(0.6, 0.58, 0.55, 0.7))
	log_btn.pressed.connect(func() -> void: _show_changelog_popup(true))
	add_child(log_btn)

	if GameState.has_run_save():
		_build_resume_button()

	_check_update_notice()

func _build_resume_button() -> void:
	var resume_btn := Button.new()
	resume_btn.text = "이어하기"
	resume_btn.focus_mode = Control.FOCUS_NONE
	resume_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	resume_btn.position = Vector2(-90, 90)
	resume_btn.size = Vector2(180, 46)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.add_theme_color_override("font_color", Color(0.93, 0.89, 0.81, 1))
	resume_btn.pressed.connect(_on_resume_pressed)
	add_child(resume_btn)

func _on_resume_pressed() -> void:
	if going or pending_update:
		return
	var data: Dictionary = GameState.load_run_state()
	if data.is_empty():
		return
	going = true
	SoundManager.play("click")
	GameState.selected_character = String(data.get("character", GameState.selected_character))
	GameState.selected_map = String(data.get("map", GameState.selected_map))
	GameState.hard_mode = bool(data.get("hard_mode", false))
	GameState.fast_mode = bool(data.get("fast_mode", false))
	GameState.pending_run_data = data
	GameState.resuming_run = true
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _check_update_notice() -> void:
	_show_changelog_popup(false)

func _show_changelog_popup(show_all: bool) -> void:
	pending_update = not show_all
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(320, 60)
	box.position = Vector2(-160, -220)
	overlay.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "업데이트 기록" if show_all else ("버전 업데이트: %s" % GameState.VERSION)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.91, 0.71, 0.24, 1))
	vbox.add_child(title_lbl)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var entries: Array = Changelog.ENTRIES if show_all else [Changelog.ENTRIES[0]]
	for entry in entries:
		var ver_lbl := Label.new()
		ver_lbl.text = "%s (%s)" % [entry.version, entry.date]
		ver_lbl.add_theme_font_size_override("font_size", 15)
		ver_lbl.add_theme_color_override("font_color", Color(0.93, 0.89, 0.81, 1))
		list.add_child(ver_lbl)
		for change in entry.changes:
			var line := Label.new()
			line.text = "· %s" % change
			line.autowrap_mode = TextServer.AUTOWRAP_WORD
			line.add_theme_font_size_override("font_size", 13)
			line.add_theme_color_override("font_color", Color(0.8, 0.76, 0.7, 1))
			list.add_child(line)

	var close_btn := Button.new()
	close_btn.text = "확인"
	close_btn.custom_minimum_size = Vector2(0, 52)
	close_btn.pressed.connect(func() -> void:
		SoundManager.play("click")
		if not show_all and OS.has_feature("web"):
			JavaScriptBridge.eval("try { localStorage.setItem('chwiholok_last_seen_version', %s); } catch(e) {}" % JSON.stringify(GameState.VERSION), true)
		pending_update = false
		overlay.queue_free())
	vbox.add_child(close_btn)

func _animate_intro() -> void:
	title_label.modulate.a = 0.0
	title_label.pivot_offset = title_label.size / 2.0
	title_label.scale = Vector2(0.85, 0.85)
	eyebrow.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(title_label, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(eyebrow, "modulate:a", 1.0, 0.4)

func _build_portraits() -> void:
	for char_data in GameState.CHARACTERS:
		var tex := TextureRect.new()
		tex.texture = load(char_data.portrait)
		tex.custom_minimum_size = Vector2(40, 40)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex.modulate = Color(1, 0.94, 0.86, 0.55)
		portrait_row.add_child(tex)

func _process(delta: float) -> void:
	ember_timer -= delta
	if ember_timer <= 0.0:
		ember_timer = randf_range(0.4, 0.8)
		_spawn_ember()

func _spawn_ember() -> void:
	var spr := Sprite2D.new()
	spr.texture = preload("res://assets/sprites/ember.png")
	var s: float = randf_range(0.12, 0.22)
	spr.scale = Vector2(s, s)
	spr.modulate = Color(1, 1, 1, 0.0)
	embers.add_child(spr)

	var vp: Vector2 = get_viewport_rect().size
	spr.position = Vector2(randf_range(0.0, vp.x), vp.y + 20.0)
	var dur: float = randf_range(4.5, 7.5)
	var drift: float = randf_range(-50.0, 50.0)

	var move_tween := create_tween()
	move_tween.tween_property(spr, "position", spr.position + Vector2(drift, -vp.y - 80.0), dur).set_trans(Tween.TRANS_SINE)

	var fade_tween := create_tween()
	fade_tween.tween_property(spr, "modulate:a", 0.8, dur * 0.2)
	fade_tween.tween_interval(dur * 0.5)
	fade_tween.tween_property(spr, "modulate:a", 0.0, dur * 0.3)
	fade_tween.tween_callback(spr.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if going or pending_update:
		return
	if event is InputEventKey and event.pressed:
		_go()

func _go() -> void:
	if going or pending_update:
		return
	if GameState.has_run_save():
		_show_new_game_confirm()
		return
	going = true
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _show_new_game_confirm() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(300, 60)
	box.position = Vector2(-150, -100)
	overlay.add_child(box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	box.add_child(vbox)

	var msg := Label.new()
	msg.text = "진행 중인 게임이 있습니다.\n새로 시작하면 기존 진행 상황이 사라집니다."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg.add_theme_font_size_override("font_size", 15)
	msg.add_theme_color_override("font_color", Color(0.9, 0.86, 0.8, 1))
	vbox.add_child(msg)

	var resume_btn := Button.new()
	resume_btn.text = "이어하기"
	resume_btn.custom_minimum_size = Vector2(0, 48)
	resume_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		_on_resume_pressed())
	vbox.add_child(resume_btn)

	var new_btn := Button.new()
	new_btn.text = "새로 시작 (기존 기록 삭제)"
	new_btn.custom_minimum_size = Vector2(0, 48)
	new_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		GameState.clear_run_state()
		going = true
		SoundManager.play("click")
		get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn"))
	vbox.add_child(new_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "취소"
	cancel_btn.flat = true
	cancel_btn.pressed.connect(func() -> void: overlay.queue_free())
	vbox.add_child(cancel_btn)
