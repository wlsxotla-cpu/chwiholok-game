extends Area2D

signal altar_used

const COST := 150

@onready var sprite: Sprite2D = $Sprite2D

var used: bool = false
var glow_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	glow_time = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	glow_time += delta * 1.5
	var t: float = (sin(glow_time) + 1.0) / 2.0
	sprite.modulate = Color(1, 1, 1, 1).lerp(Color(1.5, 1.15, 0.5, 1.0), t)

func _on_body_entered(body: Node) -> void:
	if used or not body.is_in_group("player"):
		return
	if not body.has_method("_offer_level_up"):
		return
	var available: int = GameState.total_coins + body.coins
	if available < COST:
		return
	used = true
	if body.coins >= COST:
		body.coins -= COST
	else:
		var remainder: int = COST - body.coins
		body.coins = 0
		GameState.spend_coins(remainder)
	SoundManager.play("levelup", 4.0, 0.8)
	var spark := preload("res://scenes/HitSpark.tscn").instantiate()
	get_parent().add_child(spark)
	spark.global_position = global_position
	spark.modulate = Color(1.4, 1.0, 0.4, 1.0)
	spark.scale *= 1.6
	body.heal(body.max_health * 0.3)
	altar_used.emit()
	body._offer_level_up()
	queue_free()
