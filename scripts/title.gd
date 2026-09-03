extends Control

@onready var prompt: Label = $Center/VBox/Prompt
@onready var title_label: Label = $Center/VBox/TitleLabel
@onready var eyebrow: Label = $Center/VBox/Eyebrow
@onready var portrait_row: HBoxContainer = $PortraitRow
@onready var embers: Node2D = $Embers

var going: bool = false
var ember_timer: float = 0.0

func _ready() -> void:
	_build_portraits()
	_animate_intro()
	$TapCatcher.pressed.connect(_go)

	var blink := create_tween().set_loops()
	blink.tween_property(prompt, "modulate:a", 0.25, 0.8).set_trans(Tween.TRANS_SINE)
	blink.tween_property(prompt, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

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
	if going:
		return
	if event is InputEventKey and event.pressed:
		_go()

func _go() -> void:
	if going:
		return
	going = true
	SoundManager.play("click")
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")
