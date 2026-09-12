extends Node

const SAVE_PATH := "user://save.json"
const RUN_SAVE_PATH := "user://run_save.json"
const ARENA_HALF_SIZE := 1800.0
const VERSION := "v0.49.3 · 2026-09-12"

const MODES := [
	{"id": "normal", "name": "일반"},
	{"id": "hard", "name": "하드"},
	{"id": "fast", "name": "패스트"},
]

const CHARACTERS := [
	{"id": "ipopol", "name": "이포폴", "weapon": "slash", "unlock_cost": 0, "tier": 0, "portrait": "res://assets/sprites/portraits/ipopol.png", "walk_sheet": "res://assets/sprites/ipopol_walk.png"},
	{"id": "jeonghyeong", "name": "정형", "weapon": "aura", "unlock_cost": 30, "tier": 1, "portrait": "res://assets/sprites/portraits/jeonghyeong.png", "walk_sheet": "res://assets/sprites/jeonghyeong_walk.png"},
	{"id": "igyeong", "name": "이경", "weapon": "shuriken", "unlock_cost": 80, "tier": 2, "portrait": "res://assets/sprites/portraits/igyeong.png", "walk_sheet": "res://assets/sprites/igyeong_walk.png"},
	{"id": "seongjuchang", "name": "성주창", "weapon": "pierce", "unlock_cost": 150, "tier": 3, "portrait": "res://assets/sprites/portraits/seongjuchang.png", "walk_sheet": "res://assets/sprites/seongjuchang_walk.png"},
	{"id": "simjangbeopsa", "name": "심장법사", "weapon": "fireball", "unlock_cost": 250, "tier": 4, "portrait": "res://assets/sprites/portraits/simjangbeopsa.png", "walk_sheet": "res://assets/sprites/simjangbeopsa_walk.png"},
	{"id": "eungduni", "name": "응두니", "weapon": "orbit", "unlock_cost": 350, "tier": 5, "portrait": "res://assets/sprites/portraits/eungduni.png", "walk_sheet": "res://assets/sprites/eungduni_walk.png"},
	{"id": "soun", "name": "소운", "weapon": "swordshield", "unlock_cost": 500, "tier": 6, "portrait": "res://assets/sprites/portraits/soun.png", "walk_sheet": "res://assets/sprites/soun_walk.png"},
	{"id": "minseo", "name": "민서", "weapon": "rapier", "unlock_cost": 650, "tier": 7, "portrait": "res://assets/sprites/portraits/minseo.png", "walk_sheet": "res://assets/sprites/minseo_walk.png"},
	{"id": "manyang", "name": "만냥", "weapon": "spear", "unlock_cost": 800, "tier": 8, "portrait": "res://assets/sprites/portraits/manyang.png", "walk_sheet": "res://assets/sprites/manyang_walk.png"},
	{"id": "jinak", "name": "진악", "weapon": "halberd", "tier": 9, "portrait": "res://assets/sprites/portraits/jinak.png", "walk_sheet": "res://assets/sprites/jinak_walk.png", "unlock_type": "jinak_clear"},
	{"id": "samahoek", "name": "사마획", "weapon": "curse", "tier": 10, "portrait": "res://assets/sprites/portraits/samahoek.png", "walk_sheet": "res://assets/sprites/samahoek_walk.png", "unlock_type": "samahoek_kills"},
]

const SAMAHOEK_KILL_TARGET := 15
const JINAK_CLEAR_TARGET := 3

const PET_COST := 5000
const PET_DEFS := {
	"green_spirit": {"name": "초록 정령", "sprite": "res://assets/sprites/pet_spirit_green.png", "offset": Vector2(34, -52)},
}

const MAPS := [
	{"id": "plains", "name": "평원", "desc": "흙바닥과 잡초가 있는 평범한 강호의 벌판", "floor": "res://assets/sprites/floor.png", "bg_color": Color(0.055, 0.043, 0.031, 1), "wall_tint": Color(1.0, 1.0, 1.0, 1.0)},
	{"id": "cheonmagung", "name": "천마궁", "desc": "천마가 다스리는 마교의 소굴. 낡은 나무 마루가 깔린 궁 복도", "floor": "res://assets/sprites/floor_cheonmagung.png", "bg_color": Color(0.03, 0.012, 0.012, 1), "wall_tint": Color(1.7, 0.55, 0.4, 1.0)},
	{"id": "ruins", "name": "무너지는 총단", "desc": "천마와의 최후 결전지. 지반이 갈라져 용암이 새어나오고 하늘에서 잔해가 떨어지는 붕괴 직전의 마교 총단", "floor": "res://assets/sprites/floor_ruins.png", "bg_color": Color(0.045, 0.015, 0.01, 1), "wall_tint": Color(1.1, 0.98, 0.82, 1.0)},
]

var selected_map: String = "plains"

func get_map(id: String) -> Dictionary:
	for m in MAPS:
		if m.id == id:
			return m
	return MAPS[0]

func mode_id() -> String:
	if fast_mode:
		return "fast"
	if hard_mode:
		return "hard"
	return "normal"

const WEAPON_NAMES := {
	"slash": "회전베기",
	"pierce": "관통시",
	"fireball": "화염구 장판",
	"aura": "호신강기",
	"shuriken": "표창난사",
	"orbit": "어검비행",
	"boomerang": "회류표",
	"beam": "일자검기",
	"lightning": "뇌전장",
	"halberd": "패왕붕권",
	"swordshield": "호심검방",
	"rapier": "연환자검",
	"spear": "만금창",
	"curse": "귀곡저주",
}

const META_DEFS := {
	"hp": {"name": "체력 강화", "desc": "최대체력 +15", "base_cost": 15, "max_level": 10},
	"dmg": {"name": "공격력 강화", "desc": "전체 공격력 +5%", "base_cost": 18, "max_level": 10},
	"move": {"name": "이동속도 강화", "desc": "이동속도 +3%", "base_cost": 15, "max_level": 8},
	"pickup": {"name": "수집 반경 강화", "desc": "픽업 반경 +10%", "base_cost": 12, "max_level": 8},
	"revive_slots": {"name": "환생술", "desc": "판당 계속하기 가능 횟수 +1 (내공은 그때그때 별도 지불)", "base_cost": 500, "max_level": 3},
}

const CONTINUE_COST := 300

var selected_character: String = "ipopol"
var hard_mode: bool = false
var fast_mode: bool = false
var dev_mode: bool = false
var dev_invincible: bool = false
var total_coins: int = 0
var meta_upgrades: Dictionary = {"hp": 0, "dmg": 0, "move": 0, "pickup": 0, "revive_slots": 0}
var unlocked_characters: Dictionary = {}
var samahoek_kills: int = 0
var jinak_clears: int = 0
var player_nickname: String = ""
var nickname_prompt_shown: bool = false
var owned_pets: Array = []
var sfx_enabled: bool = true
var music_enabled: bool = true
var resuming_run: bool = false
var pending_run_data: Dictionary = {}

func _ready() -> void:
	_load_data()
	_check_dev_mode()
	_trap_back_button()

func _trap_back_button() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		try {
			history.pushState(null, '', location.href);
			window.addEventListener('popstate', function(e) {
				history.pushState(null, '', location.href);
			});
		} catch (e) {}
	""", true)

const DEV_KEY := "1200"

func _check_dev_mode() -> void:
	if not OS.has_feature("web"):
		return
	var query: Variant = JavaScriptBridge.eval("window.location.search", true)
	if typeof(query) == TYPE_STRING and query.find("admin=" + DEV_KEY) != -1:
		dev_mode = true
		JavaScriptBridge.eval("try { localStorage.setItem('chwiholok_admin_v2', '1'); } catch(e) {}", true)
		return
	var stored: Variant = JavaScriptBridge.eval("(function(){ try { return localStorage.getItem('chwiholok_admin_v2') || ''; } catch(e) { return ''; } })()", true)
	if typeof(stored) == TYPE_STRING and stored == "1":
		dev_mode = true

func get_character(id: String) -> Dictionary:
	for c in CHARACTERS:
		if c.id == id:
			return c
	return CHARACTERS[0]

func is_character_unlocked(id: String) -> bool:
	if dev_mode:
		return true
	var c := get_character(id)
	if c.has("unlock_type"):
		return unlocked_characters.get(id, false)
	if int(c.get("unlock_cost", 0)) <= 0:
		return true
	return unlocked_characters.get(id, false)

func can_unlock_character(id: String) -> bool:
	if is_character_unlocked(id):
		return false
	var c := get_character(id)
	if c.has("unlock_type"):
		return false
	return total_coins >= int(c.get("unlock_cost", 0))

func unlock_character(id: String) -> bool:
	if not can_unlock_character(id):
		return false
	var c := get_character(id)
	total_coins -= int(c.get("unlock_cost", 0))
	unlocked_characters[id] = true
	_save_data()
	return true

func record_samahoek_kill() -> void:
	if is_character_unlocked("samahoek"):
		return
	samahoek_kills += 1
	if samahoek_kills >= SAMAHOEK_KILL_TARGET:
		unlocked_characters["samahoek"] = true
	_save_data()

func unlock_jinak_by_clear() -> void:
	if is_character_unlocked("jinak"):
		return
	jinak_clears += 1
	if jinak_clears >= JINAK_CLEAR_TARGET:
		unlocked_characters["jinak"] = true
	_save_data()

func has_pet(id: String) -> bool:
	return owned_pets.has(id)

func can_buy_pet(id: String) -> bool:
	return not has_pet(id) and total_coins >= PET_COST

func buy_pet(id: String) -> bool:
	if not can_buy_pet(id):
		return false
	owned_pets.append(id)
	total_coins -= PET_COST
	_save_data()
	return true

func upgrade_cost(id: String) -> int:
	var def: Dictionary = META_DEFS[id]
	var lvl: int = meta_upgrades[id]
	return int(def.base_cost) * (lvl + 1)

func can_upgrade(id: String) -> bool:
	var def: Dictionary = META_DEFS[id]
	return meta_upgrades[id] < int(def.max_level) and total_coins >= upgrade_cost(id)

func buy_upgrade(id: String) -> bool:
	if not can_upgrade(id):
		return false
	total_coins -= upgrade_cost(id)
	meta_upgrades[id] += 1
	_save_data()
	return true

func add_run_coins(amount: int) -> void:
	total_coins += amount
	_save_data()

func spend_coins(amount: int) -> void:
	total_coins = max(0, total_coins - amount)
	_save_data()

func set_sfx_enabled(v: bool) -> void:
	sfx_enabled = v
	_save_data()

func set_music_enabled(v: bool) -> void:
	music_enabled = v
	_save_data()

func set_nickname(v: String) -> void:
	player_nickname = v.strip_edges().substr(0, 12)
	_save_data()

func mark_nickname_prompt_shown() -> void:
	nickname_prompt_shown = true
	_save_data()

func has_run_save() -> bool:
	if dev_mode:
		return false
	return FileAccess.file_exists(RUN_SAVE_PATH)

func save_run_state(data: Dictionary) -> void:
	if dev_mode:
		return
	var f := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()

func load_run_state() -> Dictionary:
	if not FileAccess.file_exists(RUN_SAVE_PATH):
		return {}
	var f := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}

func clear_run_state() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)

func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		total_coins = int(parsed.get("total_coins", 0))
		var saved_upg: Dictionary = parsed.get("meta_upgrades", {})
		for k in meta_upgrades.keys():
			meta_upgrades[k] = int(saved_upg.get(k, 0))
		var saved_unlocked: Dictionary = parsed.get("unlocked_characters", {})
		unlocked_characters = saved_unlocked.duplicate()
		samahoek_kills = int(parsed.get("samahoek_kills", 0))
		jinak_clears = int(parsed.get("jinak_clears", 0))
		var saved_pets: Array = parsed.get("owned_pets", [])
		owned_pets = saved_pets.duplicate()
		sfx_enabled = bool(parsed.get("sfx_enabled", true))
		music_enabled = bool(parsed.get("music_enabled", true))
		player_nickname = String(parsed.get("player_nickname", ""))
		nickname_prompt_shown = bool(parsed.get("nickname_prompt_shown", false))

func _save_data() -> void:
	if dev_mode:
		return
	var data := {
		"total_coins": total_coins,
		"meta_upgrades": meta_upgrades,
		"unlocked_characters": unlocked_characters,
		"samahoek_kills": samahoek_kills,
		"jinak_clears": jinak_clears,
		"owned_pets": owned_pets,
		"sfx_enabled": sfx_enabled,
		"music_enabled": music_enabled,
		"player_nickname": player_nickname,
		"nickname_prompt_shown": nickname_prompt_shown,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
