extends Node2D

const HIT_INTERVAL := 0.5
const BLADE_HIT_RADIUS := 20.0

var damage: float = 6.0
var radius: float = 90.0
var count: int = 1
var maxed: bool = false
var angle_offset: float = 0.0
var blade_sprites: Array = []
var hit_cooldowns: Dictionary = {}

func sync(dmg: float, r: float, c: int, is_maxed: bool = false) -> void:
	damage = dmg
	radius = r
	count = max(1, c)
	if is_maxed != maxed:
		maxed = is_maxed
		for spr in blade_sprites:
			spr.modulate = Color(1.5, 1.1, 0.4, 1.0) if maxed else Color(1, 1, 1, 1)
			spr.scale = Vector2(0.54, 0.54) if maxed else Vector2(0.45, 0.45)
	_ensure_blade_count()

func _ensure_blade_count() -> void:
	while blade_sprites.size() < count:
		var spr := Sprite2D.new()
		spr.texture = preload("res://assets/sprites/orbit_blade.png")
		spr.scale = Vector2(0.54, 0.54) if maxed else Vector2(0.45, 0.45)
		spr.modulate = Color(1.5, 1.1, 0.4, 1.0) if maxed else Color(1, 1, 1, 1)
		add_child(spr)
		blade_sprites.append(spr)
	while blade_sprites.size() > count:
		var spr: Sprite2D = blade_sprites.pop_back()
		spr.queue_free()

func _physics_process(delta: float) -> void:
	angle_offset += delta * 2.2
	for i in range(blade_sprites.size()):
		var a: float = angle_offset + TAU * i / float(blade_sprites.size())
		var pos: Vector2 = Vector2(cos(a), sin(a)) * radius
		blade_sprites[i].position = pos
		blade_sprites[i].rotation = a + PI / 2.0

	for k in hit_cooldowns.keys():
		hit_cooldowns[k] -= delta
		if hit_cooldowns[k] <= 0.0:
			hit_cooldowns.erase(k)

	for e in get_tree().get_nodes_in_group("enemies"):
		if hit_cooldowns.has(e):
			continue
		for spr in blade_sprites:
			if spr.global_position.distance_to(e.global_position) <= BLADE_HIT_RADIUS:
				e.take_damage(damage)
				hit_cooldowns[e] = HIT_INTERVAL
				break
