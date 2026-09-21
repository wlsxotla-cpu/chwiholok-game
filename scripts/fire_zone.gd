extends Area2D

# Many bolts can each leave a zone in quick succession (e.g. flame_guard firing
# 8 bolts per volley); without a cap the screen fills with overlapping circles
# and hides the player/enemies. Keep only the newest few alive at once.
const MAX_ACTIVE_ZONES := 6
static var active_zones: Array = []

const SLOW_DURATION := 0.6
const SLOW_MULT := 0.6

var damage: float = 4.0
var duration: float = 2.0
var tick_interval: float = 0.5
var tick_timer: float = 0.0
var ember_timer: float = 0.0
var radius: float = 40.0

const FIRE_TEXTURE_OUTER_RADIUS_PX := 27.5

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	active_zones.append(self)
	while active_zones.size() > MAX_ACTIVE_ZONES:
		var oldest = active_zones.pop_front()
		if is_instance_valid(oldest) and oldest != self:
			oldest.queue_free()

func _exit_tree() -> void:
	active_zones.erase(self)

func setup(dmg: float, dur: float, r: float, maxed: bool = false) -> void:
	damage = dmg
	duration = dur
	radius = r
	var shape := CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape

	if maxed:
		sprite.modulate = Color(1.25, 0.95, 0.8, 1.0)
	sprite.scale = Vector2(0.15, 0.15)
	var base_scale: float = radius / FIRE_TEXTURE_OUTER_RADIUS_PX
	var land_tween := create_tween()
	land_tween.tween_property(sprite, "scale", Vector2(base_scale, base_scale), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var burst := preload("res://scenes/HitSpark.tscn").instantiate()
	get_parent().add_child(burst)
	burst.global_position = global_position
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.65, 0.25, 0.65), 3.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.15, 0.05, 0.0, 0.5), 1.0, true)

func _physics_process(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		queue_free()
		return

	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = tick_interval
		for body in get_overlapping_bodies():
			if body.is_in_group("enemies") and body.has_method("take_damage"):
				body.take_damage(damage)
				if body.has_method("apply_slow"):
					body.apply_slow(SLOW_DURATION, SLOW_MULT)

	ember_timer -= delta
	if ember_timer <= 0.0:
		ember_timer = 0.45
		_spawn_ember()

func _spawn_ember() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var ember := preload("res://scenes/Ember.tscn").instantiate()
	parent.add_child(ember)
	var offset: Vector2 = Vector2(randf_range(-radius, radius), randf_range(-radius, radius)) * 0.7
	ember.global_position = global_position + offset
