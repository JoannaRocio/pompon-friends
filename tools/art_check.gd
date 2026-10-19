extends SceneTree
## Herramienta de desarrollo: prueba contra el Supabase real (CloudConfig) que un dibujo de pixel art
## regalado le llegue al amigo. Dos jugadores inventados se hacen amigos, A le regala dibujos a B (hasta 3
## por dia), se prueba un dibujo invalido, B los recibe y al final dejan de ser amigos.
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).
## Deja en el servidor dos perfiles de prueba (se pueden borrar desde Supabase > Table Editor).
## Uso: godot --headless --path . --script tools/art_check.gd

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
	gs.owned = []
	gs.paintings = []
	PixelArt.cache = {}


## La respuesta tal cual del servidor (codigo y texto), para entender un error.
func _raw(fn: String, body: Dictionary) -> String:
	var http := HTTPRequest.new()
	root.add_child(http)
	var headers := PackedStringArray(["apikey: " + CloudConfig.SUPABASE_KEY, "Content-Type: application/json"])
	http.request(CloudConfig.SUPABASE_URL.trim_suffix("/") + "/rest/v1/rpc/" + fn, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	var out: Array = await http.request_completed
	http.queue_free()
	return "%d %s" % [out[1], (out[3] as PackedByteArray).get_string_from_utf8()]


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	friends = root.get_node("Friends")
	var cloud := root.get_node("Cloud")
	print("configurado: ", friends.is_available())
	_be("ArteA", "Arte A")
	var a: Dictionary = await friends.activate()
	if not a["ok"]:
		print("no se pudo registrar: ", a["error"])
		quit()
		return
	var code_a: String = gs.friend_code
	var secret_a: String = gs.friend_secret
	_be("ArteB", "Arte B")
	await friends.activate()
	var code_b: String = gs.friend_code
	var secret_b: String = gs.friend_secret
	await friends.request(code_a)
	_be("ArteA", "Arte A", code_a, secret_a)
	await friends.refresh()
	await friends.answer(code_b, true)
	print("1) son amigos: ", gs.friends.size() == 1, " (", CloudCode.format_code(code_a), " y ", CloudCode.format_code(code_b), ")")

	var heart := PixelArt.blank()
	for y in range(4, 12):
		for x in range(4, 12):
			if absf(x - 7.5) + absf(y - 8.0) < 5.0:
				heart = PixelArt.set_pixel(heart, x, y, 2)
	var r1: Dictionary = await friends.send_art(code_b, heart)
	print("2) A le regala un dibujo a B: ", r1["result"])
	if not r1["ok"]:   # para ver que dice el servidor
		print("   respuesta del servidor: ", await _raw("pompon_friend_gift_art", {"p_code": code_a, "p_secret": secret_a, "p_to": code_b, "p_art": heart}))
	var bad: Dictionary = await cloud.server_call("pompon_friend_gift_art", {"p_code": code_a, "p_secret": secret_a, "p_to": code_b, "p_art": "hola"})
	print("3) dibujo invalido: ok=", bad["ok"], " (esperado false)")
	var fake: Dictionary = await cloud.server_call("pompon_friend_gift_art", {"p_code": code_a, "p_secret": "clave-falsa-0000000000000000", "p_to": code_b, "p_art": heart})
	print("4) clave falsa: ok=", fake["ok"], " (esperado false)")
	var more: Array = []
	for i in 3:
		more.append((await friends.send_art(code_b, PixelArt.set_pixel(heart, i, 0, 6)))["result"])
	print("5) mas regalos el mismo dia: ", more, " (esperado ok, ok, limit)")

	_be("ArteB", "Arte B", code_b, secret_b)
	await friends.refresh()
	var got: Array = gs.paintings.map(func(p): return p["px"])
	print("6) a B le llegaron ", gs.paintings.size(), " dibujos (esperado 3) | el primero es el corazon: ", got.has(heart),
		" | de: '", gs.paintings[0]["from"] if gs.paintings.size() > 0 else "", "' | para colgar: ", gs.paintings.all(func(p): return gs.owned.has(p["id"])))
	print("   en su diario: ", gs.pending_thoughts.filter(func(e): return str(e["text"]).contains("dibujo")).size(), " avisos")
	await friends.refresh()
	print("7) no se repiten: ", gs.paintings.size() == 3)
	await friends.remove(code_a)
	print("8) B quita a A: amigos=", gs.friends.size())
	var after: Dictionary = await cloud.server_call("pompon_friend_gift_art", {"p_code": code_a, "p_secret": secret_a, "p_to": code_b, "p_art": heart})
	print("9) ya no son amigos: '", after.get("value", after.get("error")), "' (esperado not_friends)")
	quit()
