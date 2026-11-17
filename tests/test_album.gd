extends SceneTree
## Album de recuerdos: figuritas que se ganan con las primeras veces y al crecer, y el aviso de nueva.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var album: GDScript = load("res://scripts/pompon_album.gd")
	var firsts: GDScript = load("res://scripts/pompon_firsts.gd")
	var tastes: GDScript = load("res://scripts/pompon_tastes.gd")
	var rng := RandomNumberGenerator.new()
	gs.new_pompon()
	var p: Pompon = gs.pompon
	p.hatched = true
	var now := int(Time.get_unix_time_from_system())
	p.born_at = now - 3600
	gs.friend_points = {}
	gs.friends = []
	var prog: Dictionary = album.progress(p, now)
	print("recien nacido: ", prog["won"], " de ", prog["total"], " figuritas (solo ¡Nació!)")
	print("primera vez que mira: no avisa nada (partidas viejas): ", album.new_ones(p, now).size() == 0)

	firsts.experience(p, "bath", "", "", now, rng)
	var news: Array = album.new_ones(p, now)
	print("primer baño -> figurita nueva: ", news.map(func(s): return s["title"]), " | no se repite: ", album.new_ones(p, now).is_empty())
	print("  dia en que la gano: ", album.day_won(p, "bath"))
	tastes.eat(p, "pizza", now)   # (como en partidas de antes del album: solo queda en sus gustos)
	print("comio pizza: ", album.unlocked(p, "food:pizza", now), " | helado todavia no: ", not album.unlocked(p, "food:helado", now))
	firsts.experience(p, "game", "simon", "Memoria", now, rng)
	firsts.experience(p, "friend", "luna", "Luna", now, rng)
	firsts.experience(p, "friend", "f:ABCDEFGH", "Mochi", now, rng)
	print("jugo a Memoria: ", album.unlocked(p, "game:simon", now), " | primer vecino: ", album.unlocked(p, "neighbor", now), " | amigo de verdad: ", album.unlocked(p, "real_friend", now))
	p.born_at = now - 30 * 86400
	print("con 30 dias: niño=", album.unlocked(p, "stage:2", now), " adolescente=", album.unlocked(p, "stage:3", now), " grande=", album.unlocked(p, "stage:4", now))
	prog = album.progress(p, now)
	print("progreso: ", prog["won"], " de ", prog["total"])

	# en la casa: el album se abre y una figurita nueva se festeja
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "growth", "night1"]
	gs.tutorial["off"] = true   # (con un paso del tutorial en pantalla los avisos esperan su turno)
	gs.level_seen = 999   # (sin el aviso de nivel ni el de ponerle nombre: la figurita espera a que no haya otro cartel)
	p.nickname = "Mochi"
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.5).timeout
	h._on_action("Bañar")   # (ya se baño: no es nueva)
	h._on_action("Caricia")  # primer mimo: figurita nueva
	h._album_check = 0.0
	await process_frame
	await process_frame
	var toast := false
	for c in h.get_children():
		if c is PanelContainer and c.get_child_count() > 0 and c.get_child(0) is HBoxContainer:
			for l in c.find_children("*", "Label", true, false):
				toast = toast or l.text == "¡Figurita nueva!"
	print("en la casa, primer mimo -> aviso de figurita nueva: ", toast)
	h._show_album()
	await process_frame
	print("album abierto: ", h._album_panel != null, " | bloquea otras ventanas: ", h._any_modal())
	h._album_panel.closed.emit()
	await process_frame
	print("album cerrado: ", h._album_panel == null)
	h.queue_free()
	await process_frame
	quit()
