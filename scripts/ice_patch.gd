extends Area2D

# A frost boss's dash can leave many patches in quick succession; cap
# concurrent patches so the field doesn't get covered (see fire_zone.gd
# for the same lesson learned from flame_guard's fire zones).
const MAX_ACTIVE_PATCHES := 5
static var active_patches: Array = []

var duration: float = 2.5
var radius: float = 55.0
var slow_duration: float = 0.7
var slow_mult: float = 0.5

func _ready() -> void:
	active_patches.append(self)
	while active_patches.size() > MAX_ACTIVE_PATCHES:
		var oldest = active_patches.pop_front()
		if is_instance_valid(oldest) and oldest != self:
			oldest.queue_free()

func _exit_tree() -> void:
	active_patches.erase(self)

func setup(r: float, dur: float, s_duration: float, s_mult: float) -> void:
	radius = r
	duration = dur
	slow_duration = s_duration
	slow_mult = s_mult
	var shape := CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.85, 1.0, 0.28))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.78, 0.95, 1.0, 0.8), 2.5, true)

func _physics_process(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body.has_method("apply_slow"):
			body.apply_slow(slow_duration, slow_mult)
