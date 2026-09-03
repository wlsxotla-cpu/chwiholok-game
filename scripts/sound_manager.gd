extends Node

const POOL_SIZE := 8

const SFX := {
	"hit": preload("res://assets/audio/hit.wav"),
	"hurt": preload("res://assets/audio/hurt.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"coin": preload("res://assets/audio/coin.wav"),
	"levelup": preload("res://assets/audio/levelup.wav"),
	"click": preload("res://assets/audio/click.wav"),
	"death": preload("res://assets/audio/death.wav"),
	"explosion": preload("res://assets/audio/explosion.wav"),
	"attack_melee": preload("res://assets/audio/attack_melee.wav"),
	"attack_ranged": preload("res://assets/audio/attack_ranged.wav"),
	"attack_fireball": preload("res://assets/audio/attack_fireball.wav"),
}

const BGM_TRACKS := [
	preload("res://assets/audio/bgm_wuxia_orchestra.mp3"),
]

var players: Array = []
var next_player: int = 0
var bgm_player: AudioStreamPlayer
var bgm_index: int = 0

var sfx_enabled: bool = true
var music_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		players.append(p)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player.volume_db = -10.0
	add_child(bgm_player)
	bgm_player.finished.connect(_on_bgm_finished)

	sfx_enabled = GameState.sfx_enabled
	music_enabled = GameState.music_enabled
	_play_bgm_track(bgm_index)

func _play_bgm_track(index: int) -> void:
	bgm_index = index
	bgm_player.stream = BGM_TRACKS[bgm_index]
	if music_enabled:
		bgm_player.play()

func _on_bgm_finished() -> void:
	_play_bgm_track((bgm_index + 1) % BGM_TRACKS.size())

func play(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not sfx_enabled or not SFX.has(sfx_name):
		return
	var p: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % POOL_SIZE
	p.stream = SFX[sfx_name]
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func set_sfx_enabled(v: bool) -> void:
	sfx_enabled = v
	GameState.set_sfx_enabled(v)

func set_music_enabled(v: bool) -> void:
	music_enabled = v
	GameState.set_music_enabled(v)
	if music_enabled:
		if not bgm_player.playing:
			bgm_player.play()
	else:
		bgm_player.stop()
