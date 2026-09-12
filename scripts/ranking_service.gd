extends Node

const FIREBASE_PROJECT_ID := "chwiholok"
const FIREBASE_API_KEY := "AIzaSyByP61m-es8wZnxKLYoAbUpoJSVYJDKf7Y"

const MIN_CLEAR_TIME := 20.0
const MAX_CLEAR_TIME := 7200.0
const SURVIVAL_SCORE_OFFSET := 100000.0

signal top_fetched(map_id: String, mode_id: String, entries: Array)
signal submit_finished(success: bool)
signal nickname_claim_result(success: bool, nickname: String, reason: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_configured() -> bool:
	return FIREBASE_PROJECT_ID != "YOUR_PROJECT_ID" and FIREBASE_API_KEY != "YOUR_API_KEY"

func _base_url() -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % FIREBASE_PROJECT_ID

func submit_clear(map_id: String, nickname: String, clear_time: float, character_id: String, mode_id: String = "normal") -> void:
	submit_run(map_id, nickname, clear_time, character_id, mode_id, true)

func submit_run(map_id: String, nickname: String, time_seconds: float, character_id: String, mode_id: String, cleared: bool) -> void:
	if not is_configured():
		return
	if time_seconds < MIN_CLEAR_TIME or time_seconds > MAX_CLEAR_TIME:
		return
	var clean_nick: String = nickname.strip_edges().substr(0, 12)
	if clean_nick.is_empty():
		return

	var score: float = time_seconds if cleared else (SURVIVAL_SCORE_OFFSET - time_seconds)
	var body := {
		"fields": {
			"map": {"stringValue": map_id},
			"mode": {"stringValue": mode_id},
			"nickname": {"stringValue": clean_nick},
			"character": {"stringValue": character_id},
			"cleared": {"booleanValue": cleared},
			"clearTimeSeconds": {"doubleValue": score},
		}
	}
	var req := HTTPRequest.new()
	req.accept_gzip = false
	add_child(req)
	req.request_completed.connect(func(_result: int, code: int, _headers: PackedStringArray, _resp_body: PackedByteArray) -> void:
		submit_finished.emit(code == 200)
		req.queue_free())
	var url: String = "%s/rankings?key=%s" % [_base_url(), FIREBASE_API_KEY]
	req.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))

func claim_nickname(nickname: String) -> void:
	var clean_nick: String = nickname.strip_edges().substr(0, 12)
	if clean_nick.is_empty():
		nickname_claim_result.emit(false, clean_nick, "empty")
		return
	if not is_configured():
		nickname_claim_result.emit(true, clean_nick, "")
		return

	var req := HTTPRequest.new()
	req.accept_gzip = false
	add_child(req)
	req.request_completed.connect(func(_result: int, code: int, _headers: PackedStringArray, _resp_body: PackedByteArray) -> void:
		if code == 200:
			nickname_claim_result.emit(true, clean_nick, "")
		elif code == 409:
			nickname_claim_result.emit(false, clean_nick, "taken")
		else:
			nickname_claim_result.emit(false, clean_nick, "error")
		req.queue_free())
	var url: String = "%s/nicknames?documentId=%s&key=%s" % [_base_url(), clean_nick.uri_encode(), FIREBASE_API_KEY]
	req.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"fields": {}}))

func fetch_top(map_id: String, mode_id: String = "normal", count: int = 10) -> void:
	if not is_configured():
		top_fetched.emit(map_id, mode_id, [])
		return
	var query := {
		"structuredQuery": {
			"from": [{"collectionId": "rankings"}],
			"where": {
				"compositeFilter": {
					"op": "AND",
					"filters": [
						{"fieldFilter": {"field": {"fieldPath": "map"}, "op": "EQUAL", "value": {"stringValue": map_id}}},
						{"fieldFilter": {"field": {"fieldPath": "mode"}, "op": "EQUAL", "value": {"stringValue": mode_id}}},
					]
				}
			},
			"orderBy": [{"field": {"fieldPath": "clearTimeSeconds"}, "direction": "ASCENDING"}],
			"limit": count
		}
	}
	var req := HTTPRequest.new()
	req.accept_gzip = false
	add_child(req)
	req.request_completed.connect(func(_result: int, code: int, _headers: PackedStringArray, resp_body: PackedByteArray) -> void:
		top_fetched.emit(map_id, mode_id, _parse_top_response(code, resp_body))
		req.queue_free())
	var url: String = "%s:runQuery?key=%s" % [_base_url(), FIREBASE_API_KEY]
	req.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(query))

func _parse_top_response(code: int, resp_body: PackedByteArray) -> Array:
	var entries: Array = []
	if code != 200:
		return entries
	var parsed = JSON.parse_string(resp_body.get_string_from_utf8())
	if typeof(parsed) != TYPE_ARRAY:
		return entries
	for row in parsed:
		if typeof(row) != TYPE_DICTIONARY or not row.has("document"):
			continue
		var f: Dictionary = row.document.get("fields", {})
		var cleared: bool = bool(f.get("cleared", {}).get("booleanValue", true))
		var score: float = float(f.get("clearTimeSeconds", {}).get("doubleValue", 0.0))
		var display_time: float = score if cleared else (SURVIVAL_SCORE_OFFSET - score)
		entries.append({
			"nickname": f.get("nickname", {}).get("stringValue", "???"),
			"character": f.get("character", {}).get("stringValue", ""),
			"clearTimeSeconds": display_time,
			"cleared": cleared,
		})
	return entries
