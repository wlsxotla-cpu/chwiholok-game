extends Area2D

const DAMAGE_PER_TICK := 8.0
const TICK_INTERVAL := 0.5

@onready var sprite: Sprite2D = $Sprite2D

var glow_time: float = 0.0
var tick_timer: float = 0.0
var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	glow_time = randf_range(0.0, TAU)

func _process(delta: float) -> void:
	glow_time += delta * 2.2
	var t: float = (sin(glow_time) + 1.0) / 2.0
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0).lerp(Color(1.6, 0.35, 0.35, 1.0), t * 0.6)
	if player_inside:
		tick_timer -= delta
		if tick_timer <= 0.0:
			tick_timer = TICK_INTERVAL
			var player := get_tree().get_first_node_in_group("player")
			if player and player.has_method("take_damage"):
				player.take_damage(DAMAGE_PER_TICK)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		tick_timer = 0.0

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
