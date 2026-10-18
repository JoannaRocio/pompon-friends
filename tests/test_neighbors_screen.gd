extends SceneTree
## Pantallas de vecinos y visita: tarjetas, actividad del dia y botones que se apagan.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.coins = 3
	gs.neighbors_met = []
	gs.friend_points = {}
	gs.friend_actions = {}
	var nb: GDScript = load("res://scripts/neighbors.gd")

	var list: Control = load("res://scenes/neighbors.tscn").instantiate()
	root.add_child(list)
	await process_frame
	await process_frame
	print("tarjetas=", list._list.get_child_count(), " (esperado ", nb.all().size(), ")")
	list.queue_free()

	nb.current = "luna"
	var visit: Control = load("res://scenes/visit.tscn").instantiate()
	root.add_child(visit)
	await process_frame
	await process_frame
	# primera vez: presentacion (botones apagados mientras dura)
	print("presentacion en curso=", visit._busy, " botones apagados=", visit._buttons["pet"].disabled)
	await create_timer(14.0).timeout
	print("ya se conocen=", gs.has_met("luna"), " punto por visitar=", gs.friend_points.get("luna", 0), " (esperado 1) libre=", not visit._busy)
	visit._on_action("pet")
	print("acariciando: ocupado=", visit._busy)
	await create_timer(5.0).timeout
	print("tras acariciar: tilde=", visit._done["pet"], " puntos=", gs.friend_points["luna"], " (esperado 2) acariciar descansa=", visit._rest.has("pet"), " apagado=", visit._buttons["pet"].disabled, " jugar libre=", not visit._buttons["play"].disabled)
	visit._on_action("pet")
	print("acariciar durante su descanso no hace nada: ocupado=", visit._busy, " (esperado false)")
	visit._on_action("play")
	print("jugar si se puede: ocupado=", visit._busy, " (esperado true)")
	await create_timer(nb.REST_SECONDS + 1.5).timeout
	print("monedas por mirar (ya pasaron 20 s): ", gs.friend_done_today("luna", "watch"), " monedas=", gs.coins, " (3 + 20) socializar=", gs.pompon.stats["amistad"], " (esperado 100) barra=", visit._social_bar.value)
	gs.coins = 0
	visit._on_action("gift")
	print("regalo sin monedas: msg='", visit._message.text, "' monedas=", gs.coins)
	visit.queue_free()
	await process_frame
	quit()
