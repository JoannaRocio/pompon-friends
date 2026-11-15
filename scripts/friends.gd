extends Node
## Amigos de verdad por codigo (autoload "Friends"). Usa el mismo servidor que la nube (server/supabase.sql).
##  - "Activar amigos": el juego se registra con una clave secreta propia y recibe un codigo de amigo
##    (8 caracteres, ej. K7F3-QW2M). Tu "tarjeta" (Pompon, su casa y tu nombre) se publica y se actualiza sola.
##  - Agregar amigo = mandar una solicitud con su codigo; el otro la acepta o la rechaza.
##  - Los amigos aceptados aparecen en Vecinos y se visitan igual que los vecinos del barrio. Cada visita,
##    caricia, juego o regalo le llega como aviso (una por tipo cada 20 h): va a su diario y suma Social.
## Sin mensajes ni texto libre entre jugadores. Lo que se guarda localmente esta en GameState (friend_*).

signal changed   # cambiaron los amigos, las solicitudes o el estado (la pantalla se redibuja)

const CODE_LEN := 8
const MAX_FRIENDS := 10         # amigos de verdad como maximo (contando las solicitudes que mandaste)
const REFRESH_EVERY := 300.0   # mira el buzon cada 5 minutos
const EVENT_SOCIAL := 5.0      # Social que suma cada aviso de un amigo
const EVENT_TEXT := {
	"visit": "{n} vino a visitarme",
	"pet": "{n} vino y me hizo mimos",
	"play": "¡Jugué a la pelota con {n}!",
	"gift": "¡{n} me dejó un regalo!",
	"art": "¡{n} me mandó un dibujo! ¿Lo guardamos?",
}
const ART_PER_DAY := 3         # dibujos que se le pueden regalar a un mismo amigo por dia

var busy := false
var last_error := ""
var _refresh_t := 3.0          # el primer vistazo al buzon, apenas abre el juego
var _published_count := -1     # GameState.save_count de la ultima tarjeta publicada


func is_available() -> bool:
	return Cloud.is_configured()


func is_active() -> bool:
	return GameState.friend_code != "" and GameState.friend_secret != ""


static func clean_code(text: String) -> String:
	return CloudCode.clean_friend(text)


# ------------------------------------------------------------------ registrarse y tarjeta

## Activa los amigos: crea la clave secreta, pide un codigo y publica la tarjeta. Devuelve {"ok", "error"}.
func activate() -> Dictionary:
	if is_active():
		return {"ok": true, "error": ""}
	if not is_available():
		return _fail("off")
	if busy:
		return {"ok": false, "error": "busy"}
	busy = true
	if GameState.friend_secret == "":
		GameState.friend_secret = Crypto.new().generate_random_bytes(24).hex_encode()
	var res: Dictionary = await Cloud.server_call("pompon_friend_register", {"p_secret": GameState.friend_secret})
	busy = false
	if not res["ok"] or typeof(res["value"]) != TYPE_STRING:
		return _fail(res.get("error", "server"))
	GameState.friend_code = str(res["value"])
	GameState.save_game()
	await publish()
	changed.emit()
	return {"ok": true, "error": ""}


## Lo que ven tus amigos: tu Pompon, su habitacion actual y tu nombre (si es menor de 13, sin nombre).
func snapshot() -> Dictionary:
	var p: Pompon = GameState.pompon
	var pompon := {}
	if p != null:
		var d := p.to_dict()
		for k in ["nickname", "hatched", "species", "sex", "personality", "color_primary", "color_secondary", "eyes", "mouth", "face", "born_at"]:
			pompon[k] = d[k]
		pompon["nickname"] = GameState.shareable_pompon_name()   # (menor de 13: solo nombres de la lista)
	var wear := {}
	for cat in Catalog.WEARABLE:
		if GameState.equipped.has(cat):
			wear[cat] = GameState.equipped[cat]
	var placed := []
	for item in GameState.placed:
		if int(item.get("room", 0)) == GameState.current_room:
			var e := {"id": item["id"], "x": snappedf(item["x"], 0.001), "y": snappedf(item["y"], 0.001)}
			if item.has("on"):
				e["on"] = item["on"]
				e["ox"] = snappedf(float(item.get("ox", 0.0)), 0.1)
			placed.append(e)
	return {"v": 1, "player": "" if GameState.kids_mode() else GameState.shareable_player_name(), "title": GameState.player_title, "pompon": pompon, "equipped": wear,
		"wall": GameState.equipped.get("wall", ""), "floor": GameState.equipped.get("floor", ""), "placed": placed,
		"room": GameState.current_room}


func publish() -> Dictionary:
	if not is_active() or not is_available():
		return {"ok": false, "error": "off"}
	var res: Dictionary = await Cloud.server_call("pompon_friend_update", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret, "p_snapshot": snapshot()})
	if res["ok"]:
		_published_count = GameState.save_count
	return res


# ------------------------------------------------------------------ solicitudes y amigos

## Lugares libres en la lista (amigos + solicitudes enviadas, hasta MAX_FRIENDS).
func room_left() -> int:
	return maxi(0, MAX_FRIENDS - GameState.friends.size() - GameState.friend_sent.size())


## Lista llena: no se puede pedir ni aceptar otro amigo (el servidor cuenta igual: amigos + solicitudes enviadas).
func is_full() -> bool:
	return room_left() <= 0


## Avisos amables cuando el juego o el servidor dicen que no (lista llena, demasiados por hoy).
## `what`: "request" (pedir), "accept" (aceptar), "art" (regalar dibujo), "report" (denunciar).
static func limit_text(what: String, result: String, who := "") -> String:
	if result == "full":
		if what == "accept":
			return T.s("Tu lista ya está llena (%d, contando las solicitudes que mandaste). Para aceptar a otro amigo, primero quita uno.") % MAX_FRIENDS
		return T.s("Ya tienes %d amigos (contando las solicitudes que mandaste). Para agregar otro, quita uno.") % MAX_FRIENDS
	if result == "limit":
		match what:
			"request":
				return T.s("Ya mandaste muchas solicitudes hoy. Prueba mañana.")
			"art":
				return T.s("Hoy ya le regalaste muchos dibujos a %s. ¡Prueba mañana!") % who
			"report":
				return T.s("Hoy ya nos avisaste muchas veces. Vamos a revisar todo. Si quieres, puedes bloquear a %s.") % who
	return ""


## Manda una solicitud. Devuelve {"ok", "result"}: "sent", "accepted", "friends", "self", "not_found",
## "limit", "full" (ya tiene 10 amigos), "code" (mal escrito) o el error de red.
func request(text: String) -> Dictionary:
	var code := clean_code(text)
	if code == "":
		return {"ok": false, "result": "code"}
	if not is_active():
		return {"ok": false, "result": "off"}
	if GameState.friends.any(func(f): return f.get("code", "") == code):
		return {"ok": true, "result": "friends"}
	if room_left() <= 0:
		return {"ok": false, "result": "full"}
	var res: Dictionary = await Cloud.server_call("pompon_friend_request", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret, "p_to": code})
	if not res["ok"]:
		return {"ok": false, "result": res["error"]}
	var result := str(res["value"])
	await refresh()
	return {"ok": result in ["sent", "accepted", "friends"], "result": result}


## Acepta o rechaza una solicitud. Devuelve {"ok", "result"}: "ok", "full" (lista llena: lo dice el juego
## o el servidor, y la solicitud sigue esperando) o el error de red.
func answer(code: String, accept: bool) -> Dictionary:
	if accept and is_full():   # con la lista llena hay que quitar uno antes de aceptar otro
		return {"ok": false, "result": "full"}
	var res: Dictionary = await Cloud.server_call("pompon_friend_answer", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret, "p_from": code, "p_accept": accept})
	await refresh()
	if not res["ok"]:
		return {"ok": false, "result": str(res["error"])}
	var result := "full" if str(res["value"]) == "full" else "ok"   # (el servidor viejo devuelve "ok" o nada)
	return {"ok": result == "ok", "result": result}


func remove(code: String) -> Dictionary:
	var res: Dictionary = await Cloud.server_call("pompon_friend_remove", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret, "p_other": code})
	await refresh()
	return res


## Bloquea a alguien: deja de ser amigo (si lo era) y no le llegan mas solicitudes, visitas ni dibujos.
func block(code: String) -> void:
	code = clean_code(code)
	if code == "" or GameState.blocked_codes.has(code):
		return
	GameState.blocked_codes.append(code)
	GameState.pending_art = GameState.pending_art.filter(func(a): return a["code"] != code)
	GameState.save_game()
	if is_active() and is_available():
		await Cloud.server_call("pompon_friend_remove", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret, "p_other": code})
		await refresh()
	else:
		GameState.friends = GameState.friends.filter(func(f): return f["code"] != code)
		Neighbors.set_friends(GameState.friends)
		changed.emit()


const REPORT_REASONS := {"art": "Un dibujo feo o que me hizo sentir mal", "name": "Un nombre feo", "other": "Otra cosa"}


## Denuncia a alguien (con el dibujo, si es por un dibujo): queda anotado en el servidor para revisarlo.
## Devuelve {"ok", "result"}: "ok", "limit" (demasiadas hoy) u "off".
func report(code: String, reason: String, art := "") -> Dictionary:
	if not is_active() or not is_available():
		return {"ok": false, "result": "off"}
	if not REPORT_REASONS.has(reason):
		reason = "other"
	var res: Dictionary = await Cloud.server_call("pompon_friend_report", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret,
		"p_about": clean_code(code), "p_reason": reason, "p_art": art if PixelArt.valid(art) else ""})
	if not res["ok"]:
		return {"ok": false, "result": res["error"]}
	return {"ok": str(res["value"]) == "ok", "result": str(res["value"])}


## Avisa a un amigo que lo visitaste (o lo acariciaste, jugaron o le dejaste un regalo).
func send_event(code: String, kind: String) -> void:
	if not is_active() or not is_available():
		return
	await Cloud.server_call("pompon_friend_visit", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret, "p_to": code, "p_kind": kind})


## Le regala un dibujo de pixel art a un amigo de verdad: le llega a su juego como un cuadro para
## colgar. Devuelve {"ok", "result"}: "ok", "limit" (ya le regalaste muchos hoy), "not_friends" u "off".
func send_art(code: String, px: String) -> Dictionary:
	if not is_active() or not is_available():
		return {"ok": false, "result": "off"}
	if not PixelArt.valid(px):
		return {"ok": false, "result": "art"}
	var res: Dictionary = await Cloud.server_call("pompon_friend_gift_art", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret, "p_to": code, "p_art": px})
	if not res["ok"]:
		return {"ok": false, "result": res["error"]}
	var result := str(res["value"])
	return {"ok": result == "ok", "result": result}


## Mira el buzon: solicitudes, amigos (con su tarjeta) y avisos nuevos (al diario y a Social).
func refresh() -> Dictionary:
	if not is_active() or not is_available():
		return {"ok": false, "error": "off"}
	if GameState.save_count != _published_count:
		await publish()
	var res: Dictionary = await Cloud.server_call("pompon_friend_inbox", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret})
	if not res["ok"] or typeof(res["value"]) != TYPE_DICTIONARY:
		last_error = res.get("error", "server")
		return {"ok": false, "error": last_error}
	var box: Dictionary = res["value"]
	var requests := _entries(box.get("requests", []))
	for r in requests:   # las solicitudes de alguien bloqueado se rechazan solas, sin avisar
		if GameState.is_blocked(r["code"]):
			await Cloud.server_call("pompon_friend_answer", {"p_code": GameState.friend_code, "p_secret": GameState.friend_secret, "p_from": r["code"], "p_accept": false})
	GameState.friend_requests = requests.filter(func(r): return not GameState.is_blocked(r["code"]))
	GameState.friend_sent = _entries(box.get("sent", []))
	GameState.friends = _entries(box.get("friends", [])).filter(func(f): return not GameState.is_blocked(f["code"]))
	Neighbors.set_friends(GameState.friends)
	for e in box.get("events", []):
		_on_event(e)
	GameState.save_game()
	_published_count = GameState.save_count
	last_error = ""
	changed.emit()
	return {"ok": true, "error": ""}


func _entries(list) -> Array:
	var out := []
	if typeof(list) != TYPE_ARRAY:
		return out
	for e in list:
		if typeof(e) == TYPE_DICTIONARY and clean_code(str(e.get("code", ""))) != "":
			var snap = e.get("snapshot", {})
			out.append({"code": str(e["code"]), "snapshot": snap if typeof(snap) == TYPE_DICTIONARY else {}})
	return out


## Un amigo te visito: lo anota el diario de tu Pompon y suma Social.
func _on_event(e) -> void:
	if typeof(e) != TYPE_DICTIONARY:
		return
	var kind := str(e.get("kind", ""))
	if not EVENT_TEXT.has(kind) or GameState.is_blocked(str(e.get("from", ""))):
		return
	var who := T.s("Un amigo")
	for f in GameState.friends:
		if f["code"] == str(e.get("from", "")):
			who = display_name(f)
	if kind == "art":   # un dibujo de regalo: queda guardado para colgarlo (en Decorar), aunque el huevo no nacio
		var px := str(e.get("data", ""))
		if not PixelArt.valid(px):
			return
		GameState.receive_art(str(e.get("from", "")), who, px)   # espera que lo acepte
	if GameState.pompon == null or not GameState.pompon.hatched:
		return
	GameState.pompon.add_social(EVENT_SOCIAL, false)
	GameState.pending_thoughts.append({"kind": "sentimiento", "text": T.s(String(EVENT_TEXT[kind])).replace("{n}", who), "stat": "amistad", "key": "friend:" + kind})


## "Mochi (de Ana)" para mostrar a un amigo.
static func display_name(f: Dictionary) -> String:
	var snap: Dictionary = f.get("snapshot", {})
	var pompon = snap.get("pompon", {})
	var name := str(pompon.get("nickname", "")) if typeof(pompon) == TYPE_DICTIONARY else ""
	name = name.strip_edges().left(14)
	if name == "":
		name = "Pompon"
	var player := str(snap.get("player", "")).strip_edges().left(14)
	return name if player == "" else T.s("%s (de %s)") % [name, player]


func _fail(error: String) -> Dictionary:
	last_error = error
	changed.emit()
	return {"ok": false, "error": error}


# ------------------------------------------------------------------ cada tanto

func _process(delta: float) -> void:
	if not is_active() or busy or not is_available():
		return
	_refresh_t -= delta
	if _refresh_t <= 0.0:
		_refresh_t = REFRESH_EVERY
		refresh()


# ------------------------------------------------------------------ servidor de mentira (pruebas)

## Lo mismo que las funciones pompon_friend_* de server/supabase.sql, en memoria.
func fake_rpc(store: Dictionary, fn: String, body: Dictionary) -> Dictionary:
	if not store.has("profiles"):
		store["profiles"] = {}
		store["links"] = {}     # "DE>A" -> "pending" | "accepted"
		store["events"] = []    # {to, from, kind, seen, t}
		store["clock"] = 0
	store["clock"] = int(store["clock"]) + 1
	var profiles: Dictionary = store["profiles"]
	var links: Dictionary = store["links"]
	if fn == "pompon_friend_register":
		var code := CloudCode.new_code().left(CODE_LEN)
		profiles[code] = {"secret": body["p_secret"], "snapshot": {}}
		return _ok(code)
	var me: String = body.get("p_code", "")
	if not profiles.has(me) or profiles[me]["secret"] != body.get("p_secret", ""):
		return {"ok": false, "value": null, "error": "server"}
	var linked := func(a: String, b: String) -> bool:
		return links.get(a + ">" + b, "") == "accepted" or links.get(b + ">" + a, "") == "accepted"
	var count := func(c: String) -> int:   # pompon_friend_count: amigos + solicitudes enviadas esperando
		var n := 0
		for k in links:
			var ends: PackedStringArray = k.split(">")
			if (links[k] == "accepted" and c in ends) or (links[k] == "pending" and ends[0] == c):
				n += 1
		return n
	match fn:
		"pompon_friend_update":
			profiles[me]["snapshot"] = JSON.parse_string(JSON.stringify(body["p_snapshot"]))
			return _ok(true)
		"pompon_friend_request":
			var to := str(body["p_to"]).to_upper()
			if to == me:
				return _ok("self")
			if not profiles.has(to):
				return _ok("not_found")
			if linked.call(me, to):
				return _ok("friends")
			if links.get(to + ">" + me, "") == "pending":
				if count.call(me) >= MAX_FRIENDS:
					return _ok("full")
				links[to + ">" + me] = "accepted"
				return _ok("accepted")
			if links.has(me + ">" + to):
				return _ok("sent")
			if count.call(me) >= MAX_FRIENDS:
				return _ok("full")
			links[me + ">" + to] = "pending"
			return _ok("sent")
		"pompon_friend_answer":
			var key := str(body["p_from"]) + ">" + me
			if links.get(key, "") == "pending":
				if body["p_accept"]:
					if count.call(me) >= MAX_FRIENDS:
						return _ok("full")
					links[key] = "accepted"
				else:
					links.erase(key)
			return _ok("ok")
		"pompon_friend_remove":
			links.erase(me + ">" + str(body["p_other"]))
			links.erase(str(body["p_other"]) + ">" + me)
			return _ok("ok")
		"pompon_friend_report":
			if not store.has("reports"):
				store["reports"] = []
			if store["reports"].filter(func(r): return r["from"] == me).size() >= 10:
				return _ok("limit")
			store["reports"].append({"from": me, "about": str(body["p_about"]), "reason": str(body["p_reason"]), "art": str(body["p_art"])})
			return _ok("ok")
		"pompon_friend_visit":
			var to2 := str(body["p_to"])
			if not linked.call(me, to2):
				return _ok("not_friends")
			for ev in store["events"]:
				if ev["from"] == me and ev["to"] == to2 and ev["kind"] == body["p_kind"]:
					return _ok("already")   # (en el servidor real: dentro de las ultimas 20 horas)
			store["events"].append({"to": to2, "from": me, "kind": body["p_kind"], "seen": false})
			return _ok("ok")
		"pompon_friend_gift_art":
			var to3 := str(body["p_to"])
			if not PixelArt.valid(str(body["p_art"])):
				return {"ok": false, "value": null, "error": "server"}
			if not linked.call(me, to3):
				return _ok("not_friends")
			var sent_today: int = store["events"].filter(func(ev): return ev["from"] == me and ev["to"] == to3 and ev["kind"] == "art").size()
			if sent_today >= ART_PER_DAY:
				return _ok("limit")
			store["events"].append({"to": to3, "from": me, "kind": "art", "seen": false, "data": str(body["p_art"])})
			return _ok("ok")
		"pompon_friend_inbox":
			var card := func(code: String) -> Dictionary:
				return {"code": code, "snapshot": profiles[code]["snapshot"]}
			var requests := []
			var sent := []
			var friends := []
			for k in links:
				var parts: PackedStringArray = k.split(">")
				if links[k] == "pending" and parts[1] == me:
					requests.append(card.call(parts[0]))
				elif links[k] == "pending" and parts[0] == me:
					sent.append({"code": parts[1], "snapshot": {}})   # su tarjeta se ve recien cuando acepta
				elif links[k] == "accepted" and (parts[0] == me or parts[1] == me):
					friends.append(card.call(parts[1] if parts[0] == me else parts[0]))
			var events := []
			for ev in store["events"]:
				if ev["to"] == me and not ev["seen"]:
					events.append({"from": ev["from"], "kind": ev["kind"], "data": ev.get("data", null)})
					ev["seen"] = true
			return _ok(JSON.parse_string(JSON.stringify({"requests": requests, "sent": sent, "friends": friends, "events": events})))
	return {"ok": false, "value": null, "error": "server"}


func _ok(value) -> Dictionary:
	return {"ok": true, "value": value, "error": ""}
