extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var broken: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("breakable_prop")
	rotation = randf_range(-0.15, 0.15)

func take_damage(_amount: float) -> void:
	if broken:
		return
	broken = true
	_break()

func _break() -> void:
	var parent := get_parent()
	if parent == null:
		queue_free()
		return
	SoundManager.play("hit", -6.0, randf_range(0.9, 1.1))
	var spark := preload("res://scenes/HitSpark.tscn").instantiate()
	parent.add_child(spark)
	spark.global_position = global_position
	spark.modulate = Color(0.55, 1.0, 0.5, 1.0)

	if randf() < 0.15:
		var heal := preload("res://scenes/Pickup.tscn").instantiate()
		heal.type = heal.Type.HEAL
		heal.value = 15.0
		heal.global_position = global_position
		parent.add_child(heal)
	else:
		var gem := preload("res://scenes/Pickup.tscn").instantiate()
		gem.type = gem.Type.XP
		gem.value = randf_range(4.0, 8.0)
		gem.global_position = global_position
		parent.add_child(gem)
	queue_free()
