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

	_check_update_notice()

func _check_update_notice() -> void:
	if not OS.has_feature("web"):
		return
	var last_seen: Variant = JavaScriptBridge.eval("(function(){ try { return localStorage.getItem('chwiholok_last_seen_version') || ''; } catch(e) { return ''; } })()", true)
	if typeof(last_seen) != TYPE_STRING:
		return
	if last_seen == "":
		JavaScriptBridge.eval("try { localStorage.setItem('chwiholok_last_seen_version', %s); } catch(e) {}" % JSON.stringify(GameState.VERSION), true)
		return
	if last_seen != GameState.VERSION:
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
	going = true
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
