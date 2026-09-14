extends Node2D

const SUPPORT_INTERVAL := 12.0
const PUSH_RADIUS := 360.0
const PUSH_FORCE := 340.0
const PUSH_COOLDOWN := 30.0

var pet_id: String = "green_spirit"
var main_ref: Node = null
var pulse_timer: float = 0.0
var bob_time: float = 0.0
var base_offset: Vector2 = Vector2(34.0, -52.0)
var push_cooldown_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var def: Dictionary = GameState.PET_DEFS.get(pet_id, {})
	if def.has("sprite"):
		sprite.texture = load(def.sprite)
	if def.has("offset"):
		base_offset = def.offset
	position = base_offset
	pulse_timer = SUPPORT_INTERVAL * 0.4
	bob_time = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	bob_time += delta * 2.4
	position = base_offset + Vector2(0.0, sin(bob_time) * 4.0)

	if pet_id == "push_spirit":
		if push_cooldown_timer > 0.0:
			push_cooldown_timer -= delta
		return

	var player: Node = get_parent()
	if player.shield_charges >= 1:
		return
	pulse_timer -= delta
	if pulse_timer <= 0.0:
		pulse_timer = SUPPORT_INTERVAL
		_grant_shield(player)

func try_trigger_push_skill() -> bool:
	if push_cooldown_timer > 0.0:
		return false
	push_cooldown_timer = PUSH_COOLDOWN
	var player: Node = get_parent()
	var container: Node = main_ref if main_ref != null else player.get_parent()
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		var to_e: Vector2 = e.global_position - player.global_position
		if to_e.length() <= PUSH_RADIUS:
			if e.has_method("apply_knockback") and to_e.length() > 0.001:
				e.apply_knockback(to_e.normalized() * PUSH_FORCE)
				hit_any = true
	SoundManager.play("explosion", 2.0, 0.8)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	container.add_child(fx)
	fx.global_position = player.global_position
	fx.modulate = Color(1.8, 1.0, 0.35, 1.0)
	fx.set_radius(PUSH_RADIUS, true)
	if hit_any:
		player.screen_shake(5.0, 0.2)
	return true

func _grant_shield(player: Node) -> void:
	player.shield_charges += 1
	var container: Node = main_ref if main_ref != null else get_parent()
	SoundManager.play("levelup", 3.0, 1.4)
	var ring := preload("res://scenes/SlashEffect.tscn").instantiate()
	container.add_child(ring)
	ring.global_position = player.global_position
	ring.modulate = Color(0.5, 2.0, 0.8, 1.0)
	ring.set_radius(46.0, false)
