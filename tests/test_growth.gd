extends SceneTree
## Calidad de crecimiento, palabras y rasgos, Socializar (mitad cuidador / mitad otros Pompons), vecino NPC y fisico.

const DAY := 86400


func _baby(t0: int) -> Pompon:
	var p := Pompon.generate("Conejo", "Hembra")
	p.hatched = true
	p.born_at = t0
	for s in Pompon.STAT_NAMES:
		p.stats[s] = 100.0
	return p


## Un dia de cuidado: `level` 0 = nada, 1 = lo basico, 2 = perfecto, 3 = perfecto con mucho cariño, 4 = perfecto con mucha vida social.
func _care_day(p: Pompon, t0: int, day: int, level: int, bad_stats := false) -> void:
	var t := t0 + day * DAY + 100
	if level <= 0 and not bad_stats:
		return
	if bad_stats:
		p.stats["alimentacion"] = 10.0
	else:
		p.stats["alimentacion"] = 100.0
	PomponGrowth.sample_needs(p, t)
	if level >= 1:
		PomponGrowth.record_event(p, "fed", t)
		PomponGrowth.record_event(p, "fed", t)
	if level >= 2:
		PomponGrowth.record_event(p, "drank", t)
		PomponGrowth.record_event(p, "bathed", t)
		PomponGrowth.record_event(p, "petted", t)
		PomponGrowth.record_event(p, "petted", t)
		PomponGrowth.record_event(p, "played", t)
		PomponGrowth.record_event(p, "played", t)
		PomponGrowth.record_event(p, "visited", t)
	if level >= 3:
		for i in 4:
			PomponGrowth.record_event(p, "petted", t)
	if level == 4:
		for i in 4:
			PomponGrowth.record_event(p, "visited", t)
			PomponGrowth.record_event(p, "played", t)
	if level == 5:
		for i in 3:
			PomponGrowth.record_event(p, "gifted", t)


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var t0 := int(Time.get_unix_time_from_system()) - 20 * DAY

	var weights := 0.0
	for t in PomponGrowth.TASKS:
		weights += float(t["weight"])
	print("las tareas del dia suman: ", snappedf(weights, 0.001), " (esperado 1.0)")
	print("duracion: bebe ", PomponGrowth.stage_days(1), " dias, niño ", PomponGrowth.stage_days(2), ", adolescente ", PomponGrowth.stage_days(3), ", adulto ", PomponGrowth.stage_days(4))

	# --- cuidado perfecto durante los 7 dias: maximo, 5 palabras, rasgo muy positivo
	var perfect := _baby(t0)
	for d in 7:
		_care_day(perfect, t0, d, 2)
	var q_mid := PomponGrowth.quality(perfect, t0 + 6 * DAY + 5000)
	print("cuidado perfecto: calidad antes del ultimo dia termina=", snappedf(q_mid, 0.1), " | al final=", snappedf(PomponGrowth.quality_for_stage(perfect, 1), 0.1))
	var news := PomponGrowth.finish_stage(perfect, 1, t0 + 7 * DAY)
	var h: Dictionary = perfect.growth["history"]["1"]
	print("perfecto: nivel ", h["tier"], " | rasgo: ", h["trait"], " | palabras: ", h["words"].size(), " ", h["words"], " | avisos: ", news.size())
	print("rasgo muy positivo: ", PomponGrowth.TRAITS_EXCELLENT.values().has(h["trait"]))
	print("no se cierra dos veces: ", PomponGrowth.finish_stage(perfect, 1, t0 + 7 * DAY).is_empty())

	# --- cuidado normal: rasgos normales
	var normal := _baby(t0)
	for d in 7:
		_care_day(normal, t0, d, 1)
	PomponGrowth.finish_stage(normal, 1, t0 + 7 * DAY)
	var hn: Dictionary = normal.growth["history"]["1"]
	print("cuidado basico: calidad=", snappedf(float(hn["quality"]), 0.1), " nivel ", hn["tier"], " | rasgo: ", hn["trait"], " | palabras: ", hn["words"].size(), " | normal=", PomponGrowth.TRAITS_NORMAL.values().has(hn["trait"]))

	# --- mal cuidado: rasgos timido / miedoso / solitario
	var poor := _baby(t0)
	for d in 7:
		_care_day(poor, t0, d, 0, true)
	PomponGrowth.finish_stage(poor, 1, t0 + 7 * DAY)
	var hp: Dictionary = poor.growth["history"]["1"]
	print("mal cuidado: calidad=", snappedf(float(hp["quality"]), 0.1), " nivel ", hp["tier"], " | rasgo: ", hp["trait"], " | palabras: ", hp["words"].size(), " | negativo=", PomponGrowth.TRAITS_POOR.values().has(hp["trait"]))

	# --- faltar dias baja la calidad aunque cuides bien los otros
	var skipper := _baby(t0)
	for d in [0, 1, 2, 3]:
		_care_day(skipper, t0, d, 2)
	print("cuida 4 de 7 dias: ", snappedf(PomponGrowth.quality_for_stage(skipper, 1), 0.1), " (esperado ~57)")

	# --- el rasgo depende de lo que mas hizo
	var social := _baby(t0)
	for d in 7:
		_care_day(social, t0, d, 4)
	PomponGrowth.finish_stage(social, 1, t0 + 7 * DAY)
	var cuddly := _baby(t0)
	for d in 7:
		_care_day(cuddly, t0, d, 3)
	PomponGrowth.finish_stage(cuddly, 1, t0 + 7 * DAY)
	var generous := _baby(t0)
	for d in 7:
		_care_day(generous, t0, d, 5)
	PomponGrowth.finish_stage(generous, 1, t0 + 7 * DAY)
	print("mucha vida social -> ", social.growth["history"]["1"]["trait"], " | mucho cariño -> ", cuddly.growth["history"]["1"]["trait"], " | regalos -> ", generous.growth["history"]["1"]["trait"])

	# --- habla mas rapido cuanto mejor lo cuidas
	var talker := _baby(t0)
	for d in 3:
		_care_day(talker, t0, d, 2)
	var words_day3 := PomponGrowth.live_words(talker, t0 + 3 * DAY - 10)
	print("a los 3 dias de buen cuidado ya dice palabras: ", words_day3, " | avisos nuevos: ", PomponGrowth.check_words(talker, t0 + 3 * DAY - 10).size(), " luego: ", PomponGrowth.check_words(talker, t0 + 3 * DAY - 10).size())
	var neglected := _baby(t0)
	print("sin cuidado no dice nada: ", PomponGrowth.live_words(neglected, t0 + 3 * DAY - 10).is_empty())

	# --- lista del dia
	var today := _baby(t0)
	_care_day(today, t0, 0, 1)
	var list := PomponGrowth.checklist(today, t0 + 500)
	var done := list.filter(func(i): return i["done"] >= 0.999).map(func(i): return i["label"])
	print("hoy hizo: ", done)

	# --- Socializar: la mitad con el cuidador, la otra mitad con otros Pompons
	var s := _baby(t0)
	s.stats["amistad"] = 0.0
	for i in 20:
		s.add_social(10.0, true)
	print("solo con el cuidador: ", s.stats["amistad"], " (tope 50)")
	s.add_social(30.0, false)
	print("con otros Pompons pasa de la mitad: ", s.stats["amistad"])
	s.stats["amistad"] = 80.0
	s.add_social(10.0, true)
	print("el cuidador no baja ni sube lo que ya tiene: ", s.stats["amistad"])

	# --- fisico: caminar solo lleva hasta el nivel 3
	var f := _baby(t0)
	for i in 400:
		PomponSkills.add_walk_xp(f, 1.0)
	print("caminar por la casa: fisico nivel ", PomponSkills.level(f, "fisico"), " (tope 3), xp=", PomponSkills.xp(f, "fisico"))
	PomponSkills.add_xp(f, "fisico", 100.0)
	print("con objetos sigue subiendo: nivel ", PomponSkills.level(f, "fisico"))

	# --- vecino NPC de la misma edad
	gs.buddy = {}
	gs.new_pompon("Ave", "Macho")
	print("vecino creado: ", gs.buddy.get("name", "-"), " ", gs.buddy.get("species", "-"), " | primero en la lista: ", Neighbors.all()[0]["id"], " | total vecinos: ", Neighbors.all().size())
	gs.pompon.hatched = true
	gs.pompon.born_at = t0 + 15 * DAY
	gs._sync_buddy()
	var built := Neighbors.build(Neighbors.get_entry("buddy"))
	print("misma edad: ", built["pompon"].born_at == gs.pompon.born_at, " | etapa igual: ", built["pompon"].stage_index(t0 + 17 * DAY) == gs.pompon.stage_index(t0 + 17 * DAY))
	var name_before: String = gs.buddy["name"]
	gs.save_game()
	gs.buddy = {}
	Neighbors.buddy = {}
	gs.load_game()
	print("el vecino se conserva al recargar: ", gs.buddy.get("name", "-") == name_before)

	# --- el juego anota todo solo
	gs.pompon.hatched = true
	gs.pompon.born_at = int(Time.get_unix_time_from_system()) - 100
	gs.pompon.growth = {}
	gs.note_event("fed")
	gs.note_event("fed")
	gs.note_event("petted")
	var now := int(Time.get_unix_time_from_system())
	print("note_event suma al dia: comer=", PomponGrowth.checklist(gs.pompon, now).filter(func(i): return i["label"].begins_with("Darle de comer"))[0]["done"], " (esperado 1.0)")
	gs.reward_minigame(4, "math", 1.0)
	print("un minijuego hace crecer la barra: +", snappedf(gs.last_minigame_gain, 0.01))
	gs.reward_minigame(4, "math", 1.0)
	var second: float = gs.last_minigame_gain
	gs.reward_minigame(4, "math", 1.0)
	print("el 3ro ya no suma (el dia se completo): ", gs.last_minigame_gain < second, " (", snappedf(gs.last_minigame_gain, 0.01), ")")
	var visited_before: float = PomponGrowth.quality(gs.pompon, now)
	gs.coins = 100
	gs.friend_action("buddy", "pet")
	print("visitar al vecino suma: ", PomponGrowth.quality(gs.pompon, now) > visited_before, " | socializar=", gs.pompon.stats["amistad"])

	# --- la etapa termina sola y avisa
	gs.pompon.born_at = int(Time.get_unix_time_from_system()) - 8 * DAY
	gs.pompon.growth = {}
	for d in 7:
		_care_day(gs.pompon, gs.pompon.born_at, d, 2)
	gs.last_stage = 1
	gs.pending_thoughts = []
	gs._stage_check = 0.0
	gs._check_stage(1.0)
	print("al pasar a niño: avisos=", gs.pending_thoughts.size(), " | ", gs.pending_thoughts.map(func(e): return e["text"]))
	print("rasgos y palabras guardados: ", gs.pompon.growth["traits"].size(), " ", gs.pompon.growth["words"].size())

	# --- palabras: la primera llega recien con buen cuidado y no al nacer
	print("umbrales de palabras: ", PomponGrowth.words_for(24.9), PomponGrowth.words_for(25.0), PomponGrowth.words_for(54.9), PomponGrowth.words_for(90.0), " (esperado 0 1 2 5)")
	var day1 := _baby(t0)
	_care_day(day1, t0, 0, 2)
	print("tras un dia perfecto todavia no habla: ", PomponGrowth.live_words(day1, t0 + 5000).is_empty(), " (calidad ", snappedf(PomponGrowth.quality(day1, t0 + 5000), 0.1), ")")
	var birth_texts := [1, 2, 3].map(func(i): return PomponThoughts.birth(day1, i))
	var said: Dictionary = birth_texts[2]
	print("al nacer lo que 'dice' son sonidos: [", said["kind"], "] ", said["text"], " | sin palabras de adulto: ", not said["text"].to_lower().contains("hola") and not said["text"].to_lower().contains("mundo"))

	# --- solo se toca al personaje, no el espacio alrededor
	var view := PomponView.new()
	view.size = Vector2(400, 400)
	var kid := _baby(t0)
	kid.born_at = int(Time.get_unix_time_from_system()) - 10 * DAY
	view.pompon = kid
	print("niño: encima del cuerpo=", view._has_point(Vector2(200, 300)), " cabeza=", view._has_point(Vector2(200, 215)), " | pared arriba=", view._has_point(Vector2(200, 20)), " | costado=", view._has_point(Vector2(15, 250)), " | esquina=", view._has_point(Vector2(390, 390)))
	var egg_p := Pompon.generate("Felino", "Macho")
	view.pompon = egg_p
	print("huevo: encima=", view._has_point(Vector2(200, 320)), " | lejos=", view._has_point(Vector2(30, 60)))
	view.free()

	# --- guardado
	gs.save_game()
	gs.pompon = null
	gs.load_game()
	print("tras recargar: rasgos=", gs.pompon.growth.get("traits", []).size(), " palabras=", gs.pompon.growth.get("words", []).size(), " historial=", gs.pompon.growth.get("history", {}).keys())
	var f2 := FileAccess.open("user://save.json", FileAccess.WRITE)
	f2.store_string("{}")
	f2.close()
	quit()
