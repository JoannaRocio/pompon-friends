extends SceneTree
## Herramienta de desarrollo: prueba los amigos contra el Supabase real (CloudConfig) con dos jugadores
## inventados ("Prueba A" y "Prueba B"): registrarse, solicitud, aceptar, avisos de visita, limite y quitar.
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Deja en el servidor dos perfiles de prueba (se pueden borrar desde Supabase > Table Editor).
## Uso: godot --headless --path . --script tools/friends_check.gd

var gs: Node
var friends: Node


func _be(pompon: String, player: String, code := "", secret := "") -> void:
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = pompon
	gs.player_name = player
	gs.player_title = "n"
	gs.friend_code = code
	gs.friend_secret = secret
	gs.friends = []
	gs.friend_requests = []
	gs.friend_sent = []
	gs.pending_thoughts = []


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	friends = root.get_node("Friends")
	print("configurado: ", friends.is_available())
	_be("PruebaA", "Prueba A")
	var a: Dictionary = await friends.activate()
	print("1) A se registra: ok=", a["ok"], " error='", a["error"], "' codigo=", CloudCode.format_code(gs.friend_code))
	if not a["ok"]:
		quit()
		return
	var code_a: String = gs.friend_code
	var secret_a: String = gs.friend_secret
	_be("PruebaB", "Prueba B")
	await friends.activate()
	var code_b: String = gs.friend_code
	var secret_b: String = gs.friend_secret
	print("2) B se registra: codigo=", CloudCode.format_code(code_b))
	var r: Dictionary = await friends.request(code_a)
	var r_self: Dictionary = await friends.request(code_b)
	var r_none: Dictionary = await friends.request("ZZZZ-ZZZZ")
	print("3) B pide a A: ", r["result"], " | a si mismo: ", r_self["result"], " | codigo inexistente: ", r_none["result"],
		" | B espera sin ver la tarjeta de A: ", gs.friend_sent.size() == 1 and gs.friend_sent[0]["snapshot"].is_empty())
	_be("PruebaA", "Prueba A", code_a, secret_a)
	await friends.refresh()
	print("4) A ve la solicitud: ", gs.friend_requests.size(), " de '", friends.display_name(gs.friend_requests[0]) if gs.friend_requests.size() > 0 else "", "'")
	await friends.answer(code_b, true)
	print("5) A acepta: amigos=", gs.friends.size(), " -> '", friends.display_name(gs.friends[0]) if gs.friends.size() > 0 else "", "'")
	await friends.send_event(code_b, "visit")
	await friends.send_event(code_b, "gift")
	var again: Dictionary = await root.get_node("Cloud").server_call("pompon_friend_visit", {"p_code": code_a, "p_secret": secret_a, "p_to": code_b, "p_kind": "visit"})
	print("6) A visita y deja un regalo; la segunda visita del dia: '", again.get("value", again.get("error")), "' (esperado already)")
	var bad: Dictionary = await root.get_node("Cloud").server_call("pompon_friend_inbox", {"p_code": code_a, "p_secret": "clave-falsa-0000000000000000"})
	print("7) clave falsa: ok=", bad["ok"], " (esperado false)")
	_be("PruebaB", "Prueba B", code_b, secret_b)
	await friends.refresh()
	print("8) B recibe los avisos: ", gs.pending_thoughts.map(func(e): return e["text"]), " | amigos=", gs.friends.size())
	await friends.refresh()
	print("   no se repiten: ", gs.pending_thoughts.size() == 2)
	await friends.remove(code_a)
	print("9) B quita a A: amigos=", gs.friends.size())
	print("perfiles de prueba en el servidor: ", CloudCode.format_code(code_a), " y ", CloudCode.format_code(code_b))
	quit()
