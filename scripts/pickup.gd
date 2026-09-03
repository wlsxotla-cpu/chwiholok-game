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

var player: Node2D
var attracting: bool = false
var speed: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = TEXTURES[type]
	player = get_tree().get_first_node_in_group("player")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
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
