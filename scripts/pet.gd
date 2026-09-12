extends Node2D

const SUPPORT_INTERVAL := 12.0

var pet_id: String = "green_spirit"
var main_ref: Node = null
var pulse_timer: float = 0.0
var bob_time: float = 0.0
var base_offset: Vector2 = Vector2(34.0, -52.0)

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

	var player: Node = get_parent()
	if player.shield_charges >= 1:
		return
	pulse_timer -= delta
	if pulse_timer <= 0.0:
		pulse_timer = SUPPORT_INTERVAL
		_grant_shield(player)

func _grant_shield(player: Node) -> void:
	player.shield_charges += 1
	var container: Node = main_ref if main_ref != null else get_parent()
	SoundManager.play("levelup", 3.0, 1.4)
	var ring := preload("res://scenes/SlashEffect.tscn").instantiate()
	container.add_child(ring)
	ring.global_position = player.global_position
	ring.modulate = Color(0.5, 2.0, 0.8, 1.0)
	ring.set_radius(46.0, false)
