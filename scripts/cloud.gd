extends Node
## Partidas en la nube con un codigo de transferencia (autoload "Cloud"). Sin cuentas ni emails:
## la primera vez que se guarda se crea un codigo al azar (ej. ABCD-EFGH-JKLM) y con ese codigo se
## recupera la partida en otro dispositivo. Usa Supabase (server/supabase.sql, datos en CloudConfig).
##
## Despues de la primera vez se sube sola: cada AUTO_EVERY segundos si hubo cambios y al salir del juego.
## Si la misma partida se siguio jugando en otro dispositivo, la subida se rechaza ("conflict") para no
## pisar el progreso mas nuevo: el jugador elige cual se queda (ver la pantalla de nube del menu).

signal status_changed

const AUTO_EVERY := 180.0
const TIMEOUT := 15.0

var fake_server = null        # pruebas: un Dictionary en memoria en lugar de Supabase
var enabled := true           # pruebas: false = como si no hubiera servidor (nunca llama al real)
var busy := false
var conflict := false         # la nube tiene una partida mas nueva que este dispositivo
var last_error := ""
var _auto_t := AUTO_EVERY
var _uploaded_count := -1     # GameState.save_count de la ultima subida (para saber si hay cambios)
var _fake_clock := 0


func is_configured() -> bool:
	if not enabled:
		return false
	return fake_server != null or (CloudConfig.SUPABASE_URL != "" and CloudConfig.SUPABASE_KEY != "")


func has_code() -> bool:
	return GameState.cloud_code != ""


# ------------------------------------------------------------------ subir y bajar

## Sube la partida. La primera vez crea el codigo. `force` pisa la de la nube aunque sea mas nueva.
## Devuelve {"ok", "error"} (error: "off", "busy", "conflict", "network", "server").
func upload(force := false) -> Dictionary:
	if not is_configured():
		return _fail("off")
	if busy:
		return {"ok": false, "error": "busy"}
	busy = true
	status_changed.emit()
	var first := not has_code()
	var code: String = CloudCode.new_code() if first else GameState.cloud_code
	var base = null if first or force or GameState.cloud_synced_at == "" else GameState.cloud_synced_at
	var res := await _rpc("pompon_upload", {"p_code": code, "p_data": GameState.save_dict(), "p_base": base, "p_force": force})
	busy = false
	if res["ok"]:
		GameState.cloud_code = code
		GameState.cloud_synced_at = str(res["value"])
		conflict = false
		last_error = ""
		GameState.save_game()
		_uploaded_count = GameState.save_count
	else:
		last_error = res["error"]
		if res["error"] == "conflict":
			conflict = true
	status_changed.emit()
	return res


## Baja la partida de un codigo y reemplaza la de este dispositivo. Devuelve {"ok", "error"}
## (error: "off", "busy", "code", "not_found", "network", "server").
func restore(text: String) -> Dictionary:
	if not is_configured():
		return _fail("off")
	var code := CloudCode.clean_code(text)
	if code == "":
		return _fail("code")
	if busy:
		return {"ok": false, "error": "busy"}
	busy = true
	status_changed.emit()
	var res := await _rpc("pompon_download", {"p_code": code})
	busy = false
	if res["ok"] and typeof(res["value"]) != TYPE_DICTIONARY:
		res = {"ok": false, "error": "not_found"}
	if not res["ok"]:
		last_error = res["error"]
		status_changed.emit()
		return res
	var data = res["value"].get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return _fail("server")
	GameState.reset_game()   # se empieza limpio: nada de la partida anterior se mezcla
	GameState.apply_save(data)
	GameState.cloud_code = code
	GameState.cloud_synced_at = str(res["value"].get("updated_at", ""))
	GameState.save_game()
	_uploaded_count = GameState.save_count
	conflict = false
	last_error = ""
	status_changed.emit()
	return {"ok": true, "error": ""}


func _fail(error: String) -> Dictionary:
	last_error = error
	status_changed.emit()
	return {"ok": false, "error": error}


# ------------------------------------------------------------------ subida automatica

func _process(delta: float) -> void:
	if not has_code() or busy or conflict or not is_configured():
		return
	_auto_t -= delta
	if _auto_t <= 0.0:
		_auto_t = AUTO_EVERY
		if GameState.save_count != _uploaded_count:
			upload()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if has_code() and not busy and not conflict and is_configured():
			upload()   # lo mejor posible: el sistema puede cortar la app antes de terminar


# ------------------------------------------------------------------ servidor

## Llama a una funcion del servidor (la usan tambien los amigos). Devuelve {"ok", "value", "error"}.
func server_call(fn: String, body: Dictionary) -> Dictionary:
	if not is_configured():
		return {"ok": false, "value": null, "error": "off"}
	return await _rpc(fn, body)


func _rpc(fn: String, body: Dictionary) -> Dictionary:
	if fake_server != null:
		await get_tree().process_frame
		if fn.begins_with("pompon_friend_"):
			return Friends.fake_rpc(fake_server, fn, body)
		return _fake_rpc(fn, body)
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	add_child(http)
	var headers := PackedStringArray(["apikey: " + CloudConfig.SUPABASE_KEY, "Content-Type: application/json"])
	if CloudConfig.SUPABASE_KEY.begins_with("eyJ"):  # clave "anon" vieja (JWT): tambien va como Bearer
		headers.append("Authorization: Bearer " + CloudConfig.SUPABASE_KEY)
	var url := CloudConfig.SUPABASE_URL.trim_suffix("/") + "/rest/v1/rpc/" + fn
	if http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body)) != OK:
		http.queue_free()
		return {"ok": false, "value": null, "error": "network"}
	var out: Array = await http.request_completed
	http.queue_free()
	var result: int = out[0]
	var status: int = out[1]
	var text: String = (out[3] as PackedByteArray).get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "value": null, "error": "network"}
	if status >= 200 and status < 300:
		return {"ok": true, "value": JSON.parse_string(text) if text != "" else null, "error": ""}
	return {"ok": false, "value": null, "error": "conflict" if text.contains("conflict") else "server"}


## Lo mismo que hace server/supabase.sql, en memoria (para las pruebas).
func _fake_rpc(fn: String, body: Dictionary) -> Dictionary:
	var code: String = body["p_code"]
	if fn == "pompon_download":
		var row = fake_server.get(code)
		return {"ok": true, "value": null if row == null else {"data": JSON.parse_string(JSON.stringify(row["data"])), "updated_at": row["updated_at"]}, "error": ""}
	if CloudCode.clean_code(code) != code:
		return {"ok": false, "value": null, "error": "server"}
	if fake_server.has(code) and not body["p_force"]:
		var base = body["p_base"]
		if base == null or int(fake_server[code]["updated_at"]) > int(base):
			return {"ok": false, "value": null, "error": "conflict"}
	_fake_clock += 1
	fake_server[code] = {"data": JSON.parse_string(JSON.stringify(body["p_data"])), "updated_at": str(_fake_clock)}
	return {"ok": true, "value": str(_fake_clock), "error": ""}
