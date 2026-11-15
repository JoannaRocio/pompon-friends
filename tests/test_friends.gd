extends SceneTree
## Amigos de verdad con un servidor de mentira (imita server/supabase.sql): dos jugadores, Ana y Leo,
## se agregan, se visitan y se quitan. Nunca usa el servidor real.

var gs: Node
var friends: Node


## Cambia de jugador (como si fuera otro celular): su Pompon, su nombre y su identidad de amigos.
func _be(player: Dictionary) -> void:
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = player["pompon"]
	gs.pompon.species = player["species"]
	gs.player_name = player["name"]
	gs.player_title = "f"
	gs.friend_code = player.get("code", "")
	gs.friend_secret = player.get("secret", "")
	gs.friends = []
	gs.friend_requests = []
	gs.friend_sent = []
	gs.pending_thoughts = []


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	friends = root.get_node("Friends")
	var cloud := root.get_node("Cloud")
	cloud.fake_server = {}
	var nb: GDScript = load("res://scripts/neighbors.gd")

	var ana := {"pompon": "Mochi", "species": "Felino", "name": "Ana"}
	var leo := {"pompon": "Luna", "species": "Conejo", "name": "Leo"}
	_be(ana)
	print("sin activar: ", not friends.is_active())
	var a1: Dictionary = await friends.activate()
	ana["code"] = gs.friend_code
	ana["secret"] = gs.friend_secret
	print("Ana activa amigos: ok=", a1["ok"], " codigo=", CloudCode.format_code(ana["code"]), " (", ana["code"].length(), " letras)")

	_be(leo)
	await friends.activate()
	leo["code"] = gs.friend_code
	leo["secret"] = gs.friend_secret
	print("Leo activa amigos: codigo distinto=", leo["code"] != ana["code"])
	var r1: Dictionary = await friends.request(CloudCode.format_code(ana["code"]).to_lower())
	var r2: Dictionary = await friends.request(ana["code"])
	var r3: Dictionary = await friends.request(leo["code"])
	var r4: Dictionary = await friends.request("ZZZZ-ZZZZ")
	var r5: Dictionary = await friends.request("ABC")
	print("Leo pide a Ana: ", r1["result"], " | otra vez: ", r2["result"], " | a si mismo: ", r3["result"], " | codigo que no existe: ", r4["result"], " | mal escrito: ", r5["result"])
	print("  Leo ve su solicitud esperando: ", gs.friend_sent.size(), " | sin ver la tarjeta de Ana hasta que acepte: ", gs.friend_sent[0]["snapshot"].is_empty() if gs.friend_sent.size() > 0 else false)

	_be(ana)
	await friends.refresh()
	print("Ana recibe la solicitud: ", gs.friend_requests.size(), " de '", friends.display_name(gs.friend_requests[0]) if gs.friend_requests.size() > 0 else "", "'")
	await friends.answer(leo["code"], true)
	print("Ana acepta: amigos=", gs.friends.size(), " solicitudes=", gs.friend_requests.size())
	var entry: Dictionary = nb.get_entry("f:" + leo["code"])
	var data: Dictionary = nb.build(entry)
	print("Leo aparece en sus vecinos: ", not entry.is_empty(), " | su Pompon: ", data["pompon"].nickname, " ", data["pompon"].species, " | dice 'de ", data.get("player", ""), "' | cuarto entero: ", data["screens"])
	friends.send_event(leo["code"], "visit")
	await process_frame
	await process_frame
	friends.send_event(leo["code"], "gift")
	await process_frame
	await process_frame
	friends.send_event(leo["code"], "visit")   # repetida: no se manda dos veces
	await process_frame
	await process_frame

	_be(leo)
	var social_before: float = gs.pompon.stats.get("amistad", 0.0)
	await friends.refresh()
	var texts: Array = gs.pending_thoughts.map(func(e): return e["text"])
	print("Leo ya es amigo de Ana: ", gs.friends.size() == 1, " | avisos en su diario: ", texts)
	print("  Social sube: ", gs.pompon.stats.get("amistad", 0.0) > social_before)
	await friends.refresh()
	print("  los avisos no se repiten: ", gs.pending_thoughts.size() == texts.size())

	# se guarda y se recupera
	gs.save_game()
	gs.friend_code = ""
	gs.friends = []
	gs.load_game()
	print("guardado: codigo=", gs.friend_code == leo["code"], " amigos=", gs.friends.size(), " en vecinos=", not nb.get_entry("f:" + ana["code"]).is_empty())

	# pantallas: vecinos (con la tarjeta de amigos) y visita a un amigo de verdad
	var screen: Control = load("res://scenes/neighbors.tscn").instantiate()
	root.add_child(screen)
	await create_timer(0.3).timeout
	print("pantalla de vecinos: filas=", screen._list.get_child_count(), " (tarjeta de amigos + ", nb.all().size(), " vecinos)")
	screen.queue_free()
	nb.current = "f:" + ana["code"]
	var visit: Control = load("res://scenes/visit.tscn").instantiate()
	root.add_child(visit)
	await create_timer(0.3).timeout
	print("visita a Ana: cuarto de ", visit._room.world_screens, " pantallas | se llama '", visit._data["name"], "'")
	visit.queue_free()
	await process_frame

	# dejar de ser amigos
	await friends.remove(ana["code"])
	print("Leo quita a Ana: amigos=", gs.friends.size(), " en vecinos=", not nb.get_entry("f:" + ana["code"]).is_empty())

	await _limits(cloud, ana, leo)
	cloud.fake_server = null
	cloud.enabled = false
	quit()


## Lo que dice que no el servidor (server/supabase.sql, bloque "LIMITES EN EL SERVIDOR"): lista llena al
## pedir o aceptar, dibujos y denuncias de mas. El juego no se rompe y muestra un aviso amable.
func _limits(cloud: Node, ana: Dictionary, leo: Dictionary) -> void:
	var store: Dictionary = cloud.fake_server
	var mk := func() -> String:   # un jugador mas en el servidor de mentira
		var c: String = CloudCode.new_code().left(friends.CODE_LEN)
		store["profiles"][c] = {"secret": "x", "snapshot": {"pompon": {"nickname": "Bu"}}}
		return c
	var pia: String = mk.call()
	store["links"][pia + ">" + ana["code"]] = "pending"   # Pia le pide a Ana
	var others := []
	for i in 9:   # Ana: 9 amigos + 1 solicitud enviada = lista llena
		var c: String = mk.call()
		others.append(c)
		store["links"][ana["code"] + ">" + c] = "accepted"
	var waiting: String = mk.call()
	store["links"][ana["code"] + ">" + waiting] = "pending"
	_be(ana)
	await friends.refresh()
	print("limites: Ana con la lista llena: amigos=", gs.friends.size(), " enviadas=", gs.friend_sent.size(), " lugares=", friends.room_left(), " llena=", friends.is_full())
	var a1: Dictionary = await friends.answer(pia, true)
	print("  aceptar con la lista llena (lo frena el juego): ", a1["result"], " | sigue esperando: ", gs.friend_requests.size() == 1)
	gs.friends = []   # el juego cree que hay lugar (datos viejos): ahora dice que no el servidor
	gs.friend_sent = []
	var a2: Dictionary = await friends.answer(pia, true)
	print("  aceptar con la lista llena (lo frena el servidor): ", a2["result"], " ok=", a2["ok"], " | la solicitud sigue: ", store["links"].get(pia + ">" + ana["code"], ""), " | amigos=", gs.friends.size())
	gs.friends = []
	gs.friend_sent = []
	var r1: Dictionary = await friends.request(leo["code"])
	print("  pedir con la lista llena (lo frena el servidor): ", r1["result"], " ok=", r1["ok"], " | no se mando: ", not store["links"].has(ana["code"] + ">" + leo["code"]))
	# en la pantalla de Vecinos: aviso amable en lugar de nada
	var screen: Control = load("res://scenes/neighbors.tscn").instantiate()
	root.add_child(screen)
	await create_timer(0.3).timeout
	await screen._accept(pia)
	print("  pantalla: aviso al aceptar=", screen._notice != null)
	await screen._send(leo["code"])
	print("  pantalla: aviso al pedir=", screen._notice != null)
	screen.queue_free()
	await process_frame
	# quitando uno, hay lugar otra vez
	await friends.remove(others[0])
	var a3: Dictionary = await friends.answer(pia, true)
	print("  quita uno y acepta: ", a3["result"], " | amigos=", gs.friends.size(), " lugares=", friends.room_left())

	# dibujos: 3 por dia al mismo amigo; denuncias: 10 por dia
	var px := "0123456789abcdef".repeat(16)
	var arts := []
	for i in 4:
		arts.append((await friends.send_art(others[1], px))["result"])
	print("  dibujos al mismo amigo: ", arts)
	var reports := []
	for i in 11:
		reports.append((await friends.report(others[2], "name"))["result"])
	print("  denuncias: ", reports.count("ok"), " ok y despues ", reports.back())

	# los avisos, en los dos idiomas
	for lang in ["es", "en"]:
		TranslationServer.set_locale(lang)
		print("  avisos (", lang, "): ", [friends.limit_text("accept", "full"), friends.limit_text("request", "full"),
			friends.limit_text("art", "limit", "Bu"), friends.limit_text("report", "limit", "Bu")])
	TranslationServer.set_locale("es")
