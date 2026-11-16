extends SceneTree
## Herramienta de desarrollo: prueba contra el Supabase REAL (CloudConfig) los limites del bloque
## "LIMITES EN EL SERVIDOR" de server/supabase.sql:
##   - con 10 lugares ocupados (amigos + solicitudes enviadas) el servidor dice 'full' al pedir y al aceptar;
##   - el 4.o dibujo del dia al mismo amigo da 'limit';
##   - la 11.a denuncia del dia da 'limit'.
## Usa 10 perfiles nuevos (A, B, Q y 7 que solo reciben solicitudes) y los 2 de prueba que ya habia
## (LRLD-VLKW y BV5V-PJVQ) como destinos. Al final A quita todas sus amistades y solicitudes.
## Quedan en el servidor los perfiles nuevos y las 10 denuncias de A (borrarlos en Table Editor).
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Uso: godot --headless --path . --script tools/limits_check.gd

const OLD_TEST_PROFILES := ["LRLDVLKW", "BV5VPJVQ"]

var gs: Node
var friends: Node
var cloud: Node
var created := []   # codigos nuevos (para anotarlos y borrarlos despues)


func _be(name: String, code := "", secret := "") -> void:
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = name
	gs.player_name = "Prueba " + name
	gs.player_title = "n"
	gs.age_group = "adult"
	gs.friend_code = code
	gs.friend_secret = secret
	gs.friends = []
	gs.friend_requests = []
	gs.friend_sent = []
	gs.blocked_codes = []
	gs.pending_art = []


## Un jugador nuevo en el servidor: devuelve [codigo, clave].
func _register(name: String) -> Array:
	_be(name)
	var r: Dictionary = await friends.activate()
	if not r["ok"]:
		print("FALLA: no se pudo registrar ", name, ": ", r["error"])
		return ["", ""]
	created.append(gs.friend_code)
	return [gs.friend_code, gs.friend_secret]


func _rpc(fn: String, who: Array, extra: Dictionary) -> String:
	var body := {"p_code": who[0], "p_secret": who[1]}
	body.merge(extra)
	var res: Dictionary = await cloud.server_call(fn, body)
	return str(res["value"]) if res["ok"] else "ERROR " + str(res["error"])


func _check(what: String, got: String, want: String) -> void:
	print(what, ": ", got, " (esperado ", want, ")")
	if got != want:
		print("FALLA: ", what)


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	friends = root.get_node("Friends")
	cloud = root.get_node("Cloud")
	print("servidor configurado: ", friends.is_available())
	if not friends.is_available():
		quit()
		return
	var a := await _register("A")
	var b := await _register("B")
	var q := await _register("Q")
	var targets := []
	for i in 7:
		targets.append((await _register("T%d" % (i + 1)))[0])
	print("perfiles nuevos: ", created.map(func(c): return CloudCode.format_code(c)))

	# A llena su lista: B (aceptado) + 7 nuevos + 2 perfiles de prueba viejos = 10 lugares
	print("A pide a B: ", await _rpc("pompon_friend_request", a, {"p_to": b[0]}))
	print("B acepta: ", await _rpc("pompon_friend_answer", b, {"p_from": a[0], "p_accept": true}))
	var sent := []
	for t in targets + OLD_TEST_PROFILES:
		sent.append(await _rpc("pompon_friend_request", a, {"p_to": t}))
	print("A pide a 9 mas: ", sent)
	_be("A", a[0], a[1])
	await friends.refresh()
	print("A ve: amigos=", gs.friends.size(), " enviadas=", gs.friend_sent.size(), " lugares libres=", friends.room_left())

	# lista llena: pedir (camino normal), recibir una solicitud y aceptarla, y pedir a quien ya le pidio a A
	_check("A pide a Q con la lista llena", await _rpc("pompon_friend_request", a, {"p_to": q[0]}), "full")
	print("Q pide a A (la lista de Q no esta llena): ", await _rpc("pompon_friend_request", q, {"p_to": a[0]}))
	_check("A acepta a Q con la lista llena", await _rpc("pompon_friend_answer", a, {"p_from": q[0], "p_accept": true}), "full")
	_check("A le pide a Q (que ya le habia pedido) con la lista llena", await _rpc("pompon_friend_request", a, {"p_to": q[0]}), "full")
	_be("A", a[0], a[1])
	await friends.refresh()
	print("la solicitud de Q sigue esperando: ", gs.friend_requests.any(func(r): return r["code"] == q[0]), " | amigos de A=", gs.friends.size())
	var via_game: Dictionary = await friends.answer(q[0], true)
	print("desde el juego (Friends.answer): ", via_game, " -> aviso: '", friends.limit_text("accept", via_game["result"]), "'")

	# dibujos: 3 por dia al mismo amigo
	var px := "0123456789abcdef".repeat(16)
	var arts := []
	for i in 4:
		arts.append((await friends.send_art(b[0], px))["result"])
	print("dibujos de A a B: ", arts)
	_check("4.o dibujo del dia", arts[3], "limit")

	# denuncias: 10 por dia
	var reports := []
	for i in 11:
		reports.append((await friends.report(b[0], "other"))["result"])
	print("denuncias de A: ", reports)
	_check("11.a denuncia del dia", reports[10], "limit")

	# limpieza: A rechaza a Q y quita a todos (amigos y solicitudes enviadas)
	print("A rechaza a Q: ", await _rpc("pompon_friend_answer", a, {"p_from": q[0], "p_accept": false}))
	var removed := []
	for t in [b[0]] + targets + OLD_TEST_PROFILES:
		removed.append(await _rpc("pompon_friend_remove", a, {"p_other": t}))
	print("A quita a todos: ", removed)
	_be("A", a[0], a[1])
	await friends.refresh()
	print("A queda sin nada: amigos=", gs.friends.size(), " enviadas=", gs.friend_sent.size(), " recibidas=", gs.friend_requests.size())
	print("perfiles de prueba que quedan (borrar en Table Editor > friend_profiles): ", created.map(func(c): return CloudCode.format_code(c)))
	print("denuncias que quedan (friend_reports con from_code = ", a[0], "): ", reports.count("ok"))
	quit()
