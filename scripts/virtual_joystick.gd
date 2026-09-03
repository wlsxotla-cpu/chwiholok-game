extends Control

@export var max_distance: float = 130.0
@export var dead_zone: float = 0.15
@export var bottom_margin: float = 280.0

var direction: Vector2 = Vector2.ZERO
var touch_index: int = -2
var base_pos: Vector2 = Vector2.ZERO
var last_update_time: float = 0.0

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob

func _ready() -> void:
	add_to_group("joystick")
	base.visible = true
	_place_base()
	resized.connect(_place_base)

func _place_base() -> void:
	var vp: Vector2 = get_viewport_rect().size
	base_pos = Vector2(vp.x / 2.0, vp.y - bottom_margin)
	base.global_position = base_pos - base.size / 2.0
	knob.position = base.size / 2.0 - knob.size / 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_index == -2 and _in_grab_range(event.position):
				touch_index = event.index
				_update(event.position)
		else:
			if event.index == touch_index:
				_reset()
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_index == -2 and _in_grab_range(event.position):
				touch_index = -1
				_update(event.position)
			elif not event.pressed and touch_index == -1:
				_reset()
	elif event is InputEventMouseMotion:
		if touch_index == -1:
			_update(event.position)

func _process(_delta: float) -> void:
	if touch_index != -2:
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - last_update_time > 2.5:
			_reset()

func _in_grab_range(pos: Vector2) -> bool:
	return pos.distance_to(base_pos) <= max_distance * 1.6

func _update(pos: Vector2) -> void:
	last_update_time = Time.get_ticks_msec() / 1000.0
	var offset: Vector2 = pos - base_pos
	var dist: float = offset.length()
	if dist > max_distance:
		offset = offset.normalized() * max_distance
		dist = max_distance
	knob.position = base.size / 2.0 - knob.size / 2.0 + offset

	var mag: float = dist / max_distance
	if mag < dead_zone:
		direction = Vector2.ZERO
	else:
		direction = offset.normalized() * ((mag - dead_zone) / (1.0 - dead_zone))

func _reset() -> void:
	touch_index = -2
	direction = Vector2.ZERO
	knob.position = base.size / 2.0 - knob.size / 2.0
