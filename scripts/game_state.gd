extends Node

const SAVE_PATH := "user://save.json"
const ARENA_HALF_SIZE := 1800.0
const VERSION := "v0.17.2 · 2026-09-09"

const CHARACTERS := [
	{"id": "ipopol", "name": "이포폴", "weapon": "slash", "unlock_cost": 0, "tier": 0, "portrait": "res://assets/sprites/portraits/ipopol.png", "walk_sheet": "res://assets/sprites/ipopol_walk.png"},
	{"id": "jeonghyeong", "name": "정형", "weapon": "aura", "unlock_cost": 30, "tier": 1, "portrait": "res://assets/sprites/portraits/jeonghyeong.png", "walk_sheet": "res://assets/sprites/jeonghyeong_walk.png"},
	{"id": "igyeong", "name": "이경", "weapon": "shuriken", "unlock_cost": 80, "tier": 2, "portrait": "res://assets/sprites/portraits/igyeong.png", "walk_sheet": "res://assets/sprites/igyeong_walk.png"},
	{"id": "seongjuchang", "name": "성주창", "weapon": "pierce", "unlock_cost": 150, "tier": 3, "portrait": "res://assets/sprites/portraits/seongjuchang.png", "walk_sheet": "res://assets/sprites/seongjuchang_walk.png"},
	{"id": "simjangbeopsa", "name": "심장법사", "weapon": "fireball", "unlock_cost": 250, "tier": 4, "portrait": "res://assets/sprites/portraits/simjangbeopsa.png", "walk_sheet": "res://assets/sprites/simjangbeopsa_walk.png"},
	{"id": "eungduni", "name": "응두니", "weapon": "orbit", "unlock_cost": 350, "tier": 5, "portrait": "res://assets/sprites/portraits/eungduni.png", "walk_sheet": "res://assets/sprites/eungduni_walk.png"},
]

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
}

const META_DEFS := {
	"hp": {"name": "체력 강화", "desc": "최대체력 +15", "base_cost": 15, "max_level": 10},
	"dmg": {"name": "공격력 강화", "desc": "전체 공격력 +7%", "base_cost": 18, "max_level": 10},
	"move": {"name": "이동속도 강화", "desc": "이동속도 +6%", "base_cost": 15, "max_level": 8},
	"pickup": {"name": "수집 반경 강화", "desc": "픽업 반경 +10%", "base_cost": 12, "max_level": 8},
}

const CONTINUE_COST := 300

var selected_character: String = "ipopol"
var hard_mode: bool = false
var dev_mode: bool = false
var total_coins: int = 0
var meta_upgrades: Dictionary = {"hp": 0, "dmg": 0, "move": 0, "pickup": 0}
var unlocked_characters: Dictionary = {}
var sfx_enabled: bool = true
var music_enabled: bool = true

func _ready() -> void:
	_load_data()
	_check_dev_mode()

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
	if int(c.get("unlock_cost", 0)) <= 0:
		return true
	return unlocked_characters.get(id, false)

func can_unlock_character(id: String) -> bool:
	if is_character_unlocked(id):
		return false
	var c := get_character(id)
	return total_coins >= int(c.get("unlock_cost", 0))

func unlock_character(id: String) -> bool:
	if not can_unlock_character(id):
		return false
	var c := get_character(id)
	total_coins -= int(c.get("unlock_cost", 0))
	unlocked_characters[id] = true
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
		sfx_enabled = bool(parsed.get("sfx_enabled", true))
		music_enabled = bool(parsed.get("music_enabled", true))

func _save_data() -> void:
	if dev_mode:
		return
	var data := {
		"total_coins": total_coins,
		"meta_upgrades": meta_upgrades,
		"unlocked_characters": unlocked_characters,
		"sfx_enabled": sfx_enabled,
		"music_enabled": music_enabled,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
