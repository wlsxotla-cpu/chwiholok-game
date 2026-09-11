extends Node2D

const ATTACK_INTERVAL := 2.2
const DAMAGE := 9.0
const RANGE := 240.0
const EXECUTE_CHANCE := 0.1
const BONUS_COIN_CHANCE := 0.25

var pet_id: String = "green_spirit"
var main_ref: Node = null
var attack_timer: float = 0.0
var bob_time: float = 0.0
var base_offset: Vector2 = Vector2(18.0, -34.0)

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	var def: Dictionary = GameState.PET_DEFS.get(pet_id, {})
	if def.has("sprite"):
		sprite.texture = load(def.sprite)
	if def.has("offset"):
		base_offset = def.offset
	position = base_offset
	attack_timer = randf_range(0.4, ATTACK_INTERVAL)
	bob_time = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	bob_time += delta * 2.4
	position = base_offset + Vector2(0.0, sin(bob_time) * 4.0)

	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = ATTACK_INTERVAL
		_attack()

func _attack() -> void:
	var nearest: Node = null
	var nearest_dist: float = RANGE
	for e in get_tree().get_nodes_in_group("enemies"):
		var d: float = global_position.distance_to(e.global_position)
		if d <= nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest == null:
		return
	var container: Node = main_ref if main_ref != null else get_parent()
	if container == null:
		return

	var is_tough: bool = nearest is Enemy and (nearest.type == Enemy.Type.BOSS or nearest.type == Enemy.Type.OVERLORD)
	var executed: bool = not is_tough and randf() < EXECUTE_CHANCE
	nearest.take_damage(99999.0 if executed else DAMAGE)

	SoundManager.play("hit", 2.0, 1.3)
	var fx := preload("res://scenes/SlashEffect.tscn").instantiate()
	container.add_child(fx)
	fx.global_position = nearest.global_position
	fx.modulate = Color(0.5, 2.2, 0.75, 1.0)
	fx.set_radius(30.0, executed)

	if randf() < BONUS_COIN_CHANCE:
		var coin := preload("res://scenes/Pickup.tscn").instantiate()
		container.add_child(coin)
		coin.type = coin.Type.COIN
		coin.value = 1.0
		coin.global_position = nearest.global_position
