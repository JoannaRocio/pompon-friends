extends SceneTree
## Herramienta de desarrollo: prueba contra el Supabase real (CloudConfig) las denuncias y el bloqueo.
## Dos jugadores inventados se hacen amigos, A denuncia a B (por un dibujo y por el nombre), se prueban
## un motivo y un dibujo invalidos y una clave falsa, y A bloquea a B.
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Deja en el servidor dos perfiles de prueba y sus denuncias (se pueden borrar desde Table Editor).
## Uso: godot --headless --path . --script tools/report_check.gd

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
	gs.blocked_codes = []
	gs.pending_art = []
	gs.age_group = "adult"


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	friends = root.get_node("Friends")
	var cloud := root.get_node("Cloud")
	print("configurado: ", friends.is_available())
	_be("DenunciaA", "Prueba A")
	var a: Dictionary = await friends.activate()
	if not a["ok"]:
		print("no se pudo registrar: ", a["error"])
		quit()
		return
	var code_a: String = gs.friend_code
	var secret_a: String = gs.friend_secret
	_be("DenunciaB", "Prueba B")
	await friends.activate()
	var code_b: String = gs.friend_code
	await friends.request(code_a)
	_be("DenunciaA", "Prueba A", code_a, secret_a)
	await friends.refresh()
	await friends.answer(code_b, true)
	print("1) son amigos: ", gs.friends.size() == 1, " (", CloudCode.format_code(code_a), " y ", CloudCode.format_code(code_b), ")")

	var art := PixelArt.blank()
	for i in 16:
		art = PixelArt.set_pixel(art, i, 15 - i, 1)
	var r1: Dictionary = await friends.report(code_b, "art", art)
	var r2: Dictionary = await friends.report(code_b, "name")
	print("2) denunciar por un dibujo: ", r1["result"], " | por el nombre: ", r2["result"])
	var bad_reason: Dictionary = await cloud.server_call("pompon_friend_report", {"p_code": code_a, "p_secret": secret_a, "p_about": code_b, "p_reason": "spam", "p_art": ""})
	var bad_art: Dictionary = await cloud.server_call("pompon_friend_report", {"p_code": code_a, "p_secret": secret_a, "p_about": code_b, "p_reason": "art", "p_art": "zz"})
	var fake: Dictionary = await cloud.server_call("pompon_friend_report", {"p_code": code_a, "p_secret": "clave-falsa-0000000000000000", "p_about": code_b, "p_reason": "art", "p_art": ""})
	print("3) motivo invalido: ok=", bad_reason["ok"], " | dibujo invalido: ok=", bad_art["ok"], " | clave falsa: ok=", fake["ok"], " (esperado false en los tres)")
	await friends.block(code_b)
	print("4) A bloquea a B: amigos=", gs.friends.size(), " | bloqueados=", gs.blocked_codes.size())
	var after: Dictionary = await cloud.server_call("pompon_friend_visit", {"p_code": code_a, "p_secret": secret_a, "p_to": code_b, "p_kind": "visit"})
	print("5) ya no son amigos en el servidor: '", after.get("value", after.get("error")), "' (esperado not_friends)")
	print("revisar en Supabase > Table Editor > friend_reports: 2 filas de ", CloudCode.format_code(code_a), " sobre ", CloudCode.format_code(code_b))
	quit()
