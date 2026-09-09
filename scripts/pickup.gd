extends Area2D

enum Type { XP, MAGNET, HEAL, COIN }

const TEXTURES := {
	Type.XP: preload("res://assets/sprites/pickup_xp.png"),
	Type.MAGNET: preload("res://assets/sprites/pickup_magnet.png"),
	Type.HEAL: preload("res://assets/sprites/pickup_heal.png"),
	Type.COIN: preload("res://assets/sprites/pickup_coin.png"),
}

@export var type: Type = Type.XP
@export var value: float = 1.0

const MAX_LIFETIME := 40.0

var player: Node2D
var attracting: bool = false
var speed: float = 0.0
var lifetime: float = MAX_LIFETIME

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = TEXTURES[type]
	player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if lifetime <= 3.0:
		sprite.modulate.a = 0.4 + 0.6 * absf(sin(lifetime * 12.0))
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if not attracting and dist <= player.pickup_radius:
		attracting = true
	if attracting:
		speed = min(speed + 1000.0 * delta, 560.0)
		var dir: Vector2 = (player.global_position - global_position).normalized()
		global_position += dir * speed * delta

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match type:
		Type.XP:
			body.gain_xp(value)
			SoundManager.play("pickup", -6.0)
		Type.MAGNET:
			body.activate_magnet(6.0)
			SoundManager.play("pickup", -3.0, 0.8)
		Type.HEAL:
			body.heal(value)
			SoundManager.play("pickup", -3.0, 1.2)
		Type.COIN:
			body.add_coins(int(value))
			SoundManager.play("coin", -6.0)
	queue_free()
