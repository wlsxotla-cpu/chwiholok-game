extends Node

# TODO: Firebase 콘솔(console.firebase.google.com)에서 프로젝트 생성 후
# 프로젝트 설정 > 일반 > 내 앱(웹 앱 추가)에서 확인한 값으로 교체하세요.
const FIREBASE_PROJECT_ID := "YOUR_PROJECT_ID"
const FIREBASE_API_KEY := "YOUR_API_KEY"

const MIN_CLEAR_TIME := 20.0
const MAX_CLEAR_TIME := 7200.0

signal top_fetched(map_id: String, entries: Array)
signal submit_finished(success: bool)

func is_configured() -> bool:
	return FIREBASE_PROJECT_ID != "YOUR_PROJECT_ID" and FIREBASE_API_KEY != "YOUR_API_KEY"

func _base_url() -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents" % FIREBASE_PROJECT_ID

func submit_clear(map_id: String, nickname: String, clear_time: float, character_id: String) -> void:
	if not is_configured():
		return
	if clear_time < MIN_CLEAR_TIME or clear_time > MAX_CLEAR_TIME:
		return
	var clean_nick: String = nickname.strip_edges().substr(0, 12)
	if clean_nick.is_empty():
		return

	var body := {
		"fields": {
			"map": {"stringValue": map_id},
			"nickname": {"stringValue": clean_nick},
			"character": {"stringValue": character_id},
			"clearTimeSeconds": {"doubleValue": clear_time},
		}
	}
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result: int, code: int, _headers: PackedStringArray, _resp_body: PackedByteArray) -> void:
		submit_finished.emit(code == 200)
		req.queue_free())
	var url: String = "%s/rankings?key=%s" % [_base_url(), FIREBASE_API_KEY]
	req.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))

func fetch_top(map_id: String, count: int = 10) -> void:
	if not is_configured():
		top_fetched.emit(map_id, [])
		return
	var query := {
		"structuredQuery": {
			"from": [{"collectionId": "rankings"}],
			"where": {
				"fieldFilter": {
					"field": {"fieldPath": "map"},
					"op": "EQUAL",
					"value": {"stringValue": map_id}
				}
			},
			"orderBy": [{"field": {"fieldPath": "clearTimeSeconds"}, "direction": "ASCENDING"}],
			"limit": count
		}
	}
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result: int, code: int, _headers: PackedStringArray, resp_body: PackedByteArray) -> void:
		top_fetched.emit(map_id, _parse_top_response(code, resp_body))
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
		entries.append({
			"nickname": f.get("nickname", {}).get("stringValue", "???"),
			"character": f.get("character", {}).get("stringValue", ""),
			"clearTimeSeconds": float(f.get("clearTimeSeconds", {}).get("doubleValue", 0.0)),
		})
	return entries
