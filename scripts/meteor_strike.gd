extends Node2D

signal struck

const TELEGRAPH_TIME := 1.15
const FALL_TIME := 0.32
const RADIUS := 100.0
const DAMAGE := 42.0
const WARNING_TEXTURE_RADIUS_PX := 96.0
const FALL_START_OFFSET := Vector2(-110.0, -420.0)

@onready var warning: Sprite2D = $Warning
@onready var meteor: Sprite2D = $Meteor

var state: int = 0
var timer: float = 0.0
var damage_mult: float = 1.0

func _ready() -> void:
	timer = TELEGRAPH_TIME
	var target_scale: float = RADIUS / WARNING_TEXTURE_RADIUS_PX
	warning.scale = Vector2(target_scale, target_scale) * 0.3
	warning.modulate.a = 0.0
	meteor.visible = false
	meteor.position = FALL_START_OFFSET
	meteor.rotation = FALL_START_OFFSET.angle() + PI / 2.0

	var warn_tween := create_tween()
	warn_tween.tween_property(warning, "scale", Vector2(target_scale, target_scale), TELEGRAPH_TIME * 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	warn_tween.parallel().tween_property(warning, "modulate:a", 1.0, TELEGRAPH_TIME * 0.3)
	var pulse := create_tween().set_loops()
	pulse.tween_property(warning, "modulate:a", 0.55, 0.22).set_delay(TELEGRAPH_TIME * 0.4)
	pulse.tween_property(warning, "modulate:a", 1.0, 0.22)

func _process(delta: float) -> void:
	timer -= delta
	match state:
		0:
			if timer <= 0.0:
				state = 1
				timer = FALL_TIME
				meteor.visible = true
				var tw := create_tween()
				tw.tween_property(meteor, "position", Vector2.ZERO, FALL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		1:
			if timer <= 0.0:
				_impact()

func _impact() -> void:
	state = 2
	set_process(false)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage") and global_position.distance_to(player.global_position) <= RADIUS:
		player.take_damage(DAMAGE * damage_mult)
	SoundManager.play("explosion", 1.0, 0.7)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position
	fx.modulate = Color(1.8, 0.85, 0.35, 1.0)
	fx.set_radius(RADIUS, true)
	struck.emit()
	queue_free()
