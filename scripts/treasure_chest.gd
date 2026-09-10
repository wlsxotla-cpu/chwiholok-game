extends Area2D

signal chest_opened

@onready var sprite: Sprite2D = $Sprite2D

var opened: bool = false
var bob_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	bob_time = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	bob_time += delta * 2.0
	sprite.position.y = sin(bob_time) * 3.0

func _on_body_entered(body: Node) -> void:
	if opened or not body.is_in_group("player"):
		return
	if not body.has_method("_offer_level_up"):
		return
	opened = true
	SoundManager.play("levelup", 2.0, 1.1)
	var spark := preload("res://scenes/HitSpark.tscn").instantiate()
	get_parent().add_child(spark)
	spark.global_position = global_position
	spark.modulate = Color(1.0, 0.85, 0.3, 1.0)
	chest_opened.emit()
	body._offer_level_up()
	queue_free()
