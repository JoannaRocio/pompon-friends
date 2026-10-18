extends SceneTree
## Diario del Pompon: pensamientos, sentimientos y frases coherentes con el juego, sin repetirse ni llenar todo.


func _ctx(now: int, hour: float, room: int, items: Array) -> Dictionary:
	return {"now": now, "hour": hour, "room": room, "items": items, "on_pairs": [], "equipped": {}, "events": {}, "jobs_done": 0, "level": 12}


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var now := int(Time.get_unix_time_from_system())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var p := Pompon.generate("Conejo", "Hembra")
	p.hatched = true
	p.nickname = "Mochi"
	p.born_at = now - 10 * 86400   # nino
	p.personality = "Curioso"

	# --- huevo: no piensa
	var egg := Pompon.generate("Felino", "Macho")
	print("huevo no piensa: ", PomponThoughts.spontaneous(egg, _ctx(now, 12.0, 0, []), [], rng).is_empty(), " ", PomponThoughts.reaction("fed", egg, _ctx(now, 12.0, 0, []), rng).is_empty())

	# --- necesidades: lo que dice coincide con lo que le pasa
	for s in Pompon.STAT_NAMES:
		p.stats[s] = 90.0
	p.stats["alimentacion"] = 10.0
	var hunger := 0
	var other_need := 0
	for i in 40:
		var e := PomponThoughts.spontaneous(p, _ctx(now, 14.0, 0, []), [], rng)
		if e.get("stat", "") == "alimentacion" and e["kind"] == "sentimiento":
			hunger += 1
		if str(e.get("key", "")).begins_with("need:") and e["stat"] != "alimentacion":
			other_need += 1
	print("con hambre, habla de hambre seguido (", hunger, "/40) y no inventa otras necesidades: ", other_need == 0)
	var urgent := PomponThoughts.urgent(p, "alimentacion", now, rng)
	print("urgente: ", urgent["text"], " | ", urgent["kind"])

	# --- contexto real: hora, habitacion, muebles
	for s in Pompon.STAT_NAMES:
		p.stats[s] = 60.0
	var night_ok := true
	var day_night_leak := false
	var seen_room := {}
	for i in 200:
		var n := PomponThoughts.spontaneous(p, _ctx(now, 23.0, 3, ["furn_bookshelf"]), [], rng)
		var d := PomponThoughts.spontaneous(p, _ctx(now, 14.0, 3, ["furn_bookshelf"]), [], rng)
		if d.get("key", "").begins_with("night"):
			day_night_leak = true
		seen_room[str(n.get("key", ""))] = true
		seen_room[str(d.get("key", ""))] = true
	print("de dia no habla de la noche: ", not day_night_leak)
	print("menciona su biblioteca y su mueble: ", seen_room.has("item:furn_bookshelf"), " ", seen_room.keys().any(func(k): return str(k).begins_with("room:3")))
	var no_item := true
	for i in 200:
		var e2 := PomponThoughts.spontaneous(p, _ctx(now, 14.0, 0, []), [], rng)
		if str(e2.get("key", "")).begins_with("item:"):
			no_item = false
	print("no menciona muebles que no tiene: ", no_item)
	# ropa puesta y adornos apoyados
	var ctx := _ctx(now, 14.0, 0, ["toy_vase", "furn_dresser"])
	ctx["on_pairs"] = [["toy_vase", "furn_dresser"]]
	ctx["equipped"] = {"hat": "hat_beanie", "glasses": "glasses_round"}
	var texts := {}
	for i in 300:
		texts[PomponThoughts.spontaneous(p, ctx, [], rng).get("text", "")] = true
	print("cuenta del florero sobre la comoda: ", texts.has("Quedó lindo mi jarrón con flores sobre mi cómoda"))
	print("ropa: ", texts.has("Me siento especial con mi gorro de lana"), " ", texts.has("Me siento especial con mis lentes redondos"))
	# recuerdos recientes
	ctx["events"] = {"worked": now - 3600}
	var remembers := false
	var forgets := false
	for i in 300:
		if PomponThoughts.spontaneous(p, ctx, [], rng).get("key", "") == "ev:worked":
			remembers = true
	ctx["events"] = {"worked": now - 3 * 86400}
	for i in 300:
		if PomponThoughts.spontaneous(p, ctx, [], rng).get("key", "") == "ev:worked":
			forgets = true
	print("recuerda que trabajo hoy: ", remembers, " | no lo recuerda a los 3 dias: ", not forgets)

	# --- no se repite
	var recent: Array = []
	var repeats := 0
	for i in 40:
		var e3 := PomponThoughts.spontaneous(p, _ctx(now, 14.0, 0, ["furn_sofa"]), recent, rng)
		if e3.is_empty():
			break
		if recent.has(e3["text"]):
			repeats += 1
		recent.append(e3["text"])
		if recent.size() > 14:
			recent.pop_front()
	print("sin repetir lo ultimo dicho: repeticiones=", repeats)

	# --- bebe: solo sonidos
	var baby := Pompon.generate("Raton", "Macho")
	baby.hatched = true
	baby.born_at = now - 86400
	baby.stats["alimentacion"] = 5.0
	var be := PomponThoughts.spontaneous(baby, _ctx(now, 14.0, 0, ["furn_sofa"]), [], rng)
	print("bebe: '", be["text"], "' (sonido, no frases largas) largo=", be["text"].length())
	print("reaccion bebe: ", PomponThoughts.reaction("fed", baby, _ctx(now, 14.0, 0, []), rng)["text"])
	var growing_up := PomponThoughts.reaction("room_changed", p, _ctx(now, 14.0, 1, []), rng)
	print("reaccion cambio de cuarto: ", growing_up["text"])
	print("vuelve tras 5 h: ", PomponThoughts.welcome_back(p, now, 5 * 3600, rng).get("text", ""), " | tras 10 min: ", PomponThoughts.welcome_back(p, now, 600, rng).is_empty())

	# --- recien nacido
	for step in [1, 2, 3]:
		var b := PomponThoughts.birth(baby, step)
		print("nacimiento ", step, ": [", b["kind"], "] ", b["text"])
	# --- siempre esta haciendo algo (cuadro de actividad)
	var acts := {}
	var sleepy_day := false
	var sleepy_night := false
	for i in 120:
		acts[PomponActivity.idle(baby, _ctx(now, 14.0, 0, ["furn_sofa"]), rng)] = true
		if PomponActivity.idle(p, _ctx(now, 14.0, 0, []), rng).contains("sueño"):
			sleepy_day = true
		if PomponActivity.idle(p, _ctx(now, 23.0, 0, []), rng).contains("sueño"):
			sleepy_night = true
	print("bebe: actividades distintas=", acts.size(), " | ej: ", acts.keys()[0])
	print("de dia no cabecea de sueño: ", not sleepy_day, " | de noche si: ", sleepy_night)
	print("bebe camina: ", PomponActivity.walking(baby, _ctx(now, 14.0, 1, []), rng), " | nino camina: ", PomponActivity.walking(p, _ctx(now, 14.0, 1, []), rng))
	var ctx_fed := _ctx(now, 14.0, 0, [])
	ctx_fed["events"] = {"fed": now - 30}
	var chews := false
	for i in 80:
		if PomponActivity.idle(p, ctx_fed, rng).contains("mastica"):
			chews = true
	print("recien comio: mastica contento: ", chews)
	var no_repeat := true
	var last := ""
	for i in 60:
		var line := PomponActivity.idle(p, _ctx(now, 14.0, 0, []), rng, last.substr(p.display_name().length() + 1))
		if last != "" and line == last:
			no_repeat = false
		last = line
	print("no repite la misma actividad seguida: ", no_repeat)

	# --- diario: guardado, limite y orden
	gs.new_pompon("Conejo", "Hembra")
	gs.journal = []
	gs.events = {}
	for i in 130:
		gs.add_journal({"kind": ["pensamiento", "sentimiento", "frase"][i % 3], "text": "Entrada %d" % i, "stat": "felicidad"})
	print("el diario guarda como maximo ", gs.JOURNAL_MAX, ": ", gs.journal.size(), " | ultima: ", gs.journal[-1]["text"], " | primera: ", gs.journal[0]["text"])
	gs.add_journal({})
	gs.add_journal({"kind": "frase", "text": ""})
	print("entradas vacias se ignoran: ", gs.journal.size())
	gs.note_event("fed")
	gs.save_game()
	gs.journal = []
	gs.events = {}
	gs.load_game()
	print("tras recargar: diario=", gs.journal.size(), " ultima=", gs.journal[-1]["text"], " evento fed guardado=", gs.events.has("fed"))
	# datos corruptos en el guardado
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 2, "owned": [], "journal": [{"t": 5, "kind": "raro", "text": "x"}, {"t": 5, "kind": "frase", "text": "ok", "stat": "amor"}, 7, {"kind": "frase"}], "events": {"fed": 100, "bad": "x"}}))
	f.close()
	gs.journal = []
	gs.load_game()
	print("guardado con basura: entradas validas=", gs.journal.size(), " (esperado 1)")

	# --- eventos del juego se anotan solos
	gs.new_pompon("Conejo", "Hembra")
	gs.events = {}
	gs.coins = 500
	gs.buy("furn_crib")
	print("comprar anota 'bought': ", gs.events.has("bought"))
	gs.pompon.hatched = true
	gs.pompon.born_at = now - 70 * 86400
	gs.set_room(1)
	print("cambiar de cuarto anota 'room_changed': ", gs.events.has("room_changed"))
	gs.reward_minigame(3)
	print("jugar anota 'played': ", gs.events.has("played"))
	var f2 := FileAccess.open("user://save.json", FileAccess.WRITE)
	f2.store_string("{}")
	f2.close()
	quit()
