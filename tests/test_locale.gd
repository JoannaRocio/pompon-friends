extends SceneTree
## Idiomas (T y locale/textos.csv): cambiar de idioma, que las pantallas de entrada (menú, bienvenida,
## edad, nombre, casa y tutorial) muestren el texto correcto y que una partida vieja sin idioma use el
## del celular.

var gs: Node


func _texts(node: Node) -> Array:
	var out := []
	for c in node.find_children("*", "", true, false):
		if c is Label or c is Button:
			if c.text != "" and not c.is_queued_for_deletion():
				out.append(c.atr(c.text))   # (lo que se ve: Godot traduce solo los textos que son clave del CSV)
			elif c is Button and c.tooltip_text != "" and not c.is_queued_for_deletion():
				out.append(c.tooltip_text)   # boton de solo icono (ActionButton sin etiqueta): su nombre va en la ayuda
		elif c is RichTextLabel:
			out.append(c.get_parsed_text())
		elif c is Control and "text" in c and typeof(c.get("text")) == TYPE_STRING and c.get("text") != "":   # barras dibujadas (StatBar)
			out.append(c.get("text"))
	return out


func _notice(parent: Node) -> Node:
	var found: Node = null
	for c in parent.get_children():
		if c is BigNotice and not c.is_queued_for_deletion():
			found = c
	return found


## Claves sin traducir que se verian en pantalla ("menu.play", "tip.egg1"...).
func _raw_keys(texts: Array) -> Array:
	var re := RegEx.create_from_string("^(common|ui|menu|age|profile|names|welcome|home|tip|tut)\\.[A-Za-z_.0-9]+$")
	return texts.filter(func(s): return re.search(str(s)) != null)


## Textos en español del CSV que en inglés cambian: si alguno se ve tal cual en inglés, falta traducirlo.
var _spanish_only := {}


func _load_spanish_only() -> void:
	var f := FileAccess.open("res://locale/textos.csv", FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3 and row[1] != row[2]:
			_spanish_only[row[1]] = true


## Lo que se ve en inglés pero sigue en español: textos exactos del CSV o con letras del español.
func _spanish_left(texts: Array, allow: Array = []) -> Array:
	var re := RegEx.create_from_string("[áéíóúñ¿¡]")
	return texts.filter(func(s): return not s in allow and (_spanish_only.has(s) or re.search(s) != null))


## Todos los T.s("..."), T.t("...") y T.label("...") del codigo tienen su texto en inglés.
func _code_check(t: GDScript) -> void:
	var re := RegEx.create_from_string("T\\.(s|t|g|n|label)\\(\"((?:[^\"\\\\]|\\\\.)*)\"")
	var missing := []
	var count := 0
	for dir in ["res://scripts"]:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd"):
				continue
			var src := FileAccess.get_file_as_string(dir.path_join(file))
			for m in re.search_all(src):
				var kind := m.get_string(1)
				var lit := m.get_string(2).c_unescape()
				var key: String = {"s": "s:", "label": "ui."}.get(kind, "") + lit
				if kind == "g" or kind == "n" or (kind == "t" and lit.contains("%")):
					continue   # (variantes y claves armadas con % se prueban aparte)
				count += 1
				var en_obj := TranslationServer.get_translation_object("en")
				if String(en_obj.get_message(key)) == "" and (kind != "s" or String(en_obj.get_message(lit)) == ""):
					missing.append("%s: %s" % [file, key])
	print("codigo: ", count, " textos con T.s/T.t/T.label | sin ingles: ", missing)


## Area 1: tienda, vestidor, catalogo y comidas.
func _area_shop(t: GDScript) -> void:
	var Catalog: GDScript = load("res://scripts/catalog.gd")
	var PomponTastes: GDScript = load("res://scripts/pompon_tastes.gd")
	var Rooms: GDScript = load("res://scripts/rooms.gd")
	var en := TranslationServer.get_translation_object("en")
	var no_item: Array = Catalog.ITEMS.filter(func(i): return String(en.get_message("item." + i["id"])) == "").map(func(i): return i["id"])
	var no_food: Array = PomponTastes.FOODS.filter(func(f): return String(en.get_message("food." + f["id"])) == "").map(func(f): return f["id"])
	print("catalogo: ", Catalog.ITEMS.size(), " objetos | sin ingles: ", no_item, " | comidas sin ingles: ", no_food, " | ej: ", Catalog.item_name("hat_bow"), ", ", PomponTastes.food_name("torta"), ", ", Rooms.room_name(1))
	var now := int(Time.get_unix_time_from_system())
	gs.reset_game()
	gs.set_language("en")
	gs.age_group = "adult"
	gs.set_profile("Ana", "f")
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.born_at = now - 3 * 86400
	gs.pompon.nickname = "Mochi"
	gs.coins = 30
	gs.daily_gift_day = Missions.today(now)
	gs.owned = ["hat_bow", "shirt_dress", "furn_sofa", "wall_stars"]
	for key in ["all", "special"]:
		var shop: Control = load("res://scenes/shop.tscn").instantiate()
		root.add_child(shop)
		await process_frame
		if key == "special":
			shop._filter = "special"
			shop._rebuild()
			await process_frame
		var st := _texts(shop)
		print("tienda (en, ", key, "): ", st.filter(func(s): return s in ["Shop", "All", "Clothes", "Furniture", "Bowls", "Special", "Yours", "Unlocks as you level up"] or s.begins_with("Level") or s.begins_with("New shop in")).slice(0, 12))
		print("  sigue en español: ", _spanish_left(st, ["Mochi"]), " | claves sueltas: ", _raw_keys(st))
		shop.queue_free()
		await process_frame
	var wd: Control = load("res://scenes/wardrobe.tscn").instantiate()
	root.add_child(wd)
	await process_frame
	var wt := _texts(wd)
	print("vestidor (en): ", wt.filter(func(s): return s in ["Closet", "Clothes", "Room", "Bowls", "Pink bow", "Pink dress"]), " | sigue en español: ", _spanish_left(wt, ["Mochi"]))
	wd.queue_free()
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.6).timeout
	h._show_food_menu()
	await process_frame
	var ft := _texts(h._food_panel) if h._food_panel != null else []
	print("comida (en): ", ft.filter(func(s): return s.begins_with("What should") or s in ["Toast", "Baby mush", "free", "New!"]).slice(0, 6), " | sigue en español: ", _spanish_left(ft, ["Mochi"]))
	h.queue_free()
	await process_frame


## Area 2: trabajo (periodico, aula, turno), Matematicas y Geografia (pistas por primera letra).
func _area_jobs(t: GDScript) -> void:
	var Geo: GDScript = load("res://scripts/geography_problems.gd")
	var Math: GDScript = load("res://scripts/math_problems.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for lg in ["es", "en"]:
		gs.set_language(lg)
		var bad := []
		var nohint := []
		var total := 0
		for level in range(1, 6):
			for c in Geo.items("geo_capitals", level):
				for kind in ["capital", "flag_to_country", "capital_to_country"]:
					for i in 3:
						var p: Dictionary = Geo.build_problem("geo_capitals", level, c, rng, kind)
						total += 1
						var letter: String = Geo.initial(str(p["answer"]))
						if p["hint"] == "":
							if not nohint.has(str(p["answer"])):
								nohint.append(str(p["answer"]))
						elif not p["options"].all(func(o): return Geo.initial(str(o)) == letter):
							var tag := "%s (%s)" % [p["answer"], kind]
							if not bad.has(tag):
								bad.append(tag)
		var sample: Dictionary = Geo.build_problem("geo_capitals", 1, Geo.items("geo_capitals", 1)[1], rng, "capital")
		print("geografia (", lg, "): ", total, " preguntas | con pista y opciones que NO empiezan igual: ", bad, " | sin pista (no hay 3 con esa letra): ", nohint, " | ej: '", sample["ask"], "' ", sample["options"], " pista ", sample["hint"])
	gs.set_language("en")
	print("matematicas (en): ", Math.track_label("mul"), " | ", Math.level_name("addsub", 7), " | ", Math.lesson("mul", 1)["lines"][0].replace("
", " / "))
	print("  explicacion: ", Math.explanation({"op": "add", "a": 8, "b": 5, "answer": 13}).replace("
", " / "))
	print("  nota: ", Math.grade(9, 10)["title"], " ", Math.grade(9, 10)["message"], " | sube: ", Math.judge(5.0, 3, [{"c": true, "t": 1.0}, {"c": true, "t": 1.0}, {"c": true, "t": 1.0}, {"c": true, "t": 1.0}, {"c": true, "t": 1.0}, {"c": true, "t": 1.0}, {"c": true, "t": 1.0}, {"c": true, "t": 1.0}, {"c": true, "t": 1.0}, {"c": true, "t": 1.0}], "cuentas")["reason"])
	print("geografia (en): ", Geo.level_name("geo_flags", 2), " | ", Geo.explanation({"kind": "capital", "country": "Japan", "capital": "Tokyo"}), " | ", Geo.lesson("geo_capitals", 3)["lines"][0].replace("
", " / "))
	# pantallas: periodico, aula y el turno
	var now := int(Time.get_unix_time_from_system())
	gs.reset_game()
	gs.set_language("en")
	gs.set_profile("Ana", "f")
	gs.age_group = "adult"
	gs.jobs_done = 3
	gs.tips_seen = ["job_intro", "job_hired", "job_first_shift"]
	for scene in ["job_board", "job_menu"]:
		var sc: Control = load("res://scenes/%s.tscn" % scene).instantiate()
		root.add_child(sc)
		await create_timer(0.3).timeout
		var tx := _texts(sc)
		print(scene, " (en): ", tx.slice(0, 14), " | sigue en español: ", _spanish_left(tx, ["Ana"]), " | claves sueltas: ", _raw_keys(tx))
		if scene == "job_menu":
			sc._show_lesson("mul", 2)
			await process_frame
			var lt := _texts(sc)
			print("  leccion: ", lt.filter(func(s): return s.begins_with("Times") or s.begins_with("Level")), " | sigue en español: ", _spanish_left(lt, ["Ana"]))
		sc.queue_free()
		await process_frame
	for subject in ["math", "geography"]:
		var Jobs: GDScript = load("res://scripts/jobs.gd")
		Jobs.current = subject
		Jobs.set_track("addsub" if subject == "math" else "geo_capitals")
		var game: Control = load("res://scenes/job_game.tscn").instantiate()
		root.add_child(game)
		await create_timer(0.3).timeout
		var it := _texts(game)
		print("turno ", subject, " (en): ", it.filter(func(s): return s.begins_with("Welcome") or s in ["Tidy up the things", "Check the test when a hand goes up", "Let's teach!"]), " | sigue en español: ", _spanish_left(it, ["Ana"]))
		game._close_layer()
		game.state = game.State.PLAY
		game._open_question()
		await process_frame
		var qt := _texts(game)
		print("  examen: ", qt.filter(func(s): return s.ends_with("test") or s.begins_with("What") or s.begins_with("Which") or s.begins_with("Hint") or s.begins_with("This")), " | sigue en español: ", _spanish_left(qt.filter(func(s): return not s.ends_with("'s test")), ["Ana"]))   # (el nombre del alumno queda en español, como los de los vecinos)
		game._finish(true)
		await create_timer(0.3).timeout
		var et := _texts(game)
		for i in 4:   # recorre los carteles en fila hasta la nota
			if et.any(func(s): return s == "End of shift!"):
				break
			game._next_step()
			await process_frame
			et = _texts(game)
		print("  final: ", et.filter(func(s): return s == "End of shift!" or s.begins_with("Grade") or s in ["Again!", "Classroom", "Home"]), " | sigue en español: ", _spanish_left(et, ["Ana"]))
		game.queue_free()
		await process_frame


## Area 3: en inglés, la clase de Inglés pasa a ser clase de Español (caminos es_*, aparte de en_*).
func _area_spanish_class(t: GDScript) -> void:
	var Jobs: GDScript = load("res://scripts/jobs.gd")
	var Es: GDScript = load("res://scripts/spanish_problems.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	gs.reset_game()
	gs.set_language("es")
	print("en español: materia='", Jobs.subject_name("english"), "' | puesto='", Jobs.title("english", "f"), "' | caminos=", Jobs.problems("english").TRACKS)
	gs.set_language("en")
	print("en ingles: materia='", Jobs.subject_name("english"), "' | puesto='", Jobs.title("english", "f"), "' | aviso='", Jobs.blurb(Jobs.get_job("english")), "' | caminos=", Jobs.problems("english").TRACKS)
	for track in Es.TRACKS:
		var ok := true
		for level in range(1, 11):
			for it in Es.items(track, level):
				var p: Dictionary = Es.build_problem(track, level, it, rng)
				ok = ok and p["options"].size() == 3 and p["options"].has(p["answer"]) and p["say"] == "" and p["speak_lang"] == "es"
		var sample: Dictionary = Es.build_problem(track, 3, Es.items(track, 3)[0], rng)
		print("  ", track, " (", Es.track_label(track), "): todas bien=", ok, " | ej: '", sample["prompt"], "' -> ", sample["options"], " respuesta '", sample["answer"], "' | ", sample["ask"], " | voz: '", sample["speak"], "'")
	print("  explicacion: ", Es.explanation(Es.build_problem("es_words", 1, Es.items("es_words", 1)[0], rng)), " | ", Es.explanation(Es.build_problem("es_phrases", 2, Es.items("es_phrases", 2)[0], rng)))
	print("  leccion: ", Es.lesson("es_meaning", 1)["title"], " | ", Es.lesson("es_meaning", 1)["lines"][0].replace("
", " / "))
	# progreso aparte: es_* no toca en_*
	var p1: Dictionary = Es.build_problem("es_words", 1, Es.items("es_words", 1)[0], rng)
	gs.record_answer("es_words", p1, false, 3.0)
	gs.finish_job("es_words", 0, 1, false)
	gs.save_game()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
	gs.apply_save(saved)
	print("progreso: es_words respondidas=", gs.math_state("es_words")["answered"], " | en_words=", gs.math_progress.has("en_words"), " | repaso es_words=", gs.weak_facts("es_words").size(), " | dio la clase (en)=", gs.taught("english"))
	gs.set_language("es")
	print("  en español (clase de Inglés): dio la clase=", gs.taught("english"), " | camino=", Jobs.current_track("english"))
	gs.set_language("en")
	print("  en ingles: camino=", Jobs.current_track("english"))
	# pantallas
	gs.set_profile("Ana", "f")
	gs.age_group = "adult"
	gs.tips_seen.append_array(["job_intro", "job_hired", "job_first_shift", "job_english"])
	var board: Control = load("res://scenes/job_board.tscn").instantiate()
	root.add_child(board)
	await create_timer(0.3).timeout
	print("periodico (en): ", _texts(board).filter(func(s): return "Spanish" in s))
	board.queue_free()
	Jobs.current = "english"
	var office: Control = load("res://scenes/job_menu.tscn").instantiate()
	root.add_child(office)
	await create_timer(0.3).timeout
	var ot := _texts(office)
	print("aula (en): ", ot.filter(func(s): return s in ["Spanish classroom", "Words", "What does it mean?", "Sentences", "Colors", "Greetings", "I am, you are"]), " | sigue en español: ", _spanish_left(ot, ["Ana", "¿?", "¡Hola!"]))
	office.queue_free()
	for track in Es.TRACKS:
		Jobs.set_track(track)
		var game: Control = load("res://scenes/job_game.tscn").instantiate()
		root.add_child(game)
		await create_timer(0.3).timeout
		game._close_layer()
		game.state = game.State.PLAY
		game._open_question()
		await process_frame
		var qt := _texts(game)
		print("  examen ", track, ": ", qt.filter(func(s): return s.ends_with("?") or s.ends_with("test")), " | sigue en español (sin contar las opciones): ", _spanish_left(qt.filter(func(s): return not s.ends_with("'s test")), game._problem["options"] + [game._problem["prompt"], "Ana"]))
		game.queue_free()
		await process_frame
	Jobs.current = "math"


## Area 4: diario, primeras veces, juegos con objetos, actividad, gustos, animo, album y ficha (en inglés,
## he/she segun el Pompon). Junta cientos de frases generadas y busca español o marcadores sin completar.
func _area_diary(t: GDScript) -> void:
	var Thoughts: GDScript = load("res://scripts/pompon_thoughts.gd")
	var Activity: GDScript = load("res://scripts/pompon_activity.gd")
	var Firsts: GDScript = load("res://scripts/pompon_firsts.gd")
	var Play: GDScript = load("res://scripts/pompon_play.gd")
	var Tastes: GDScript = load("res://scripts/pompon_tastes.gd")
	var Mood: GDScript = load("res://scripts/pompon_mood.gd")
	var PSpeech: GDScript = load("res://scripts/pompon_speech.gd")
	var Growth: GDScript = load("res://scripts/pompon_growth.gd")
	var Album: GDScript = load("res://scripts/pompon_album.gd")
	var Skills: GDScript = load("res://scripts/pompon_skills.gd")
	var Catalog: GDScript = load("res://scripts/catalog.gd")
	var now := int(Time.get_unix_time_from_system())
	gs.reset_game()
	gs.set_language("en")
	var all := []
	for sex in ["Hembra", "Macho"]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		gs.new_pompon("Conejo", sex)
		var p = gs.pompon
		p.hatched = true
		p.nickname = "Mochi"
		p.born_at = now - 12 * 86400
		var items := ["furn_sofa", "furn_piano", "toy_blocks", "deco_window", "furn_bookshelf", "hat_bow"]
		for stat_v in [10.0, 45.0, 95.0]:
			for k in p.stats:
				p.stats[k] = stat_v
			for hour in [8.0, 15.0, 23.0]:
				for room in 6:
					var ctx := {"now": now, "hour": hour, "room": room, "items": items, "on_pairs": [["toy_blocks", "furn_bookshelf"]],
						"equipped": {"hat": "hat_bow"}, "events": {"fed": now - 30, "played": now - 30, "worked": now - 60, "visited": now - 60, "bought": now - 60, "petted": now - 60},
						"jobs_done": 4, "level": 9}
					for i in 6:
						var e: Dictionary = Thoughts.spontaneous(p, ctx, [], rng)
						if not e.is_empty():
							all.append(e["text"])
						all.append(Activity.idle(p, ctx, rng))
					all.append(Activity.walking(p, ctx, rng))
					ctx["sleeping"] = true
					var d: Dictionary = Thoughts.spontaneous(p, ctx, [], rng)
					if not d.is_empty():
						all.append(d["text"])
			for ev in Thoughts.REACTIONS:
				var r: Dictionary = Thoughts.reaction(ev, p, {"now": now, "room": 2}, rng)
				all.append(r.get("text", ""))
			for st in Thoughts.NEED_TEXT:
				all.append(Thoughts.urgent(p, st, now, rng).get("text", ""))
			for m in Mood.messages(p):
				all.append(m["text"])
			for i in 8:
				all.append(PSpeech.line(p, now, i))
		for step in [1, 2, 3]:
			all.append(Thoughts.birth(p, step).get("text", ""))
		all.append(Thoughts.welcome_back(p, now, 30 * 3600, rng).get("text", ""))
		for kind in ["bath", "drink", "pet", "sleep"]:
			for i in 3:
				p.tastes["firsts_last"] = 0
				all.append(Firsts.experience(p, kind, "", "", now + i * 1000, rng).get("text", ""))
		all.append(Firsts.experience(p, "game", "simon", Tastes.game_name("simon"), now, rng).get("text", ""))
		all.append(Firsts.experience(p, "room", "2", Firsts.room_label(2), now, rng).get("text", ""))
		all.append(Firsts.experience(p, "wear", "hat_bow", Thoughts._poss("hat_bow"), now, rng).get("text", ""))
		all.append(Firsts.experience(p, "friend", "luna", "Luna", now, rng).get("text", ""))
		all.append(Firsts.experience(p, "item", "furn_piano", Thoughts._poss("furn_piano"), now, rng).get("text", ""))
		for f in Tastes.FOODS:
			all.append(Firsts.experience(p, "food", f["id"], Tastes.food_name(f["id"]).to_lower(), now, rng, rng.randi_range(-1, 1)).get("text", ""))
			for i in 4:
				all.append(Tastes.eat(p, f["id"], now)["text"])
		for e2 in Tastes.new_favorites(p, now):
			all.append(e2["text"])
		for id in Play.PLAYS:
			all.append(Play.activity_text(p, id))
			all.append(Play.comment(id, rng))
		all.append(Play.activity_text(p, "deco_shelf"))
		all.append(Play.comment("furn_piano_gold", rng))
		for sk in Skills.SKILLS:
			all.append(Skills.add_xp(p, sk, 500.0).get("text", ""))
		for e3 in Growth.finish_stage(p, 1, now):
			all.append(e3["text"])
		for e4 in Growth.check_words(p, now):
			all.append(e4["text"])
		if sex == "Hembra":
			print("diario (en, hembra): ", [Activity.idle(p, {"now": now, "hour": 12.0, "room": 1, "items": [], "events": {}}, rng),
				Play.activity_text(p, "toy_robot"), Mood.messages(p)[0]["text"]])
		else:
			print("diario (en, macho): ", [Play.activity_text(p, "toy_robot"), Play.activity_text(p, "deco_shelf")])
	for s in Album.stickers():   # (el album completa {his} con el sexo del Pompon al mostrarlas)
		all.append(t.with_pron(s["title"], "Macho"))
		all.append(t.with_pron(s["hint"], "Hembra"))
	all = all.filter(func(x): return str(x) != "")
	var leftover := all.filter(func(x): return str(x).contains("{") or str(x).contains("%"))
	var uniq := {}
	for x in all:
		uniq[x] = true
	print("frases generadas: ", all.size(), " (", uniq.size(), " distintas) | sigue en español: ", _spanish_left(uniq.keys(), ["Mochi"]).slice(0, 20), " | marcadores sin completar: ", leftover.slice(0, 10))
	print("  ej: ", uniq.keys().slice(0, 6))
	# pantallas: diario, ficha y album
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.pompon.born_at = now - 3 * 86400
	gs.hatch_anim_pending = false
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "notify_ask", "night1"]
	gs.tutorial = {"chapter": 0, "step": 0, "off": true, "done_at": 0, "done_day": -1}
	gs.journal = [{"t": now - 30, "kind": "frase", "text": "Yum! That was delicious", "stat": "alimentacion"}]
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.6).timeout
	h._show_journal()
	await process_frame
	var jt := _texts(h._journal_panel)
	print("diario (en): ", jt.slice(0, 6), " | sigue en español: ", _spanish_left(jt, ["Mochi"]))
	h._journal_panel.queue_free()
	h._journal_panel = null
	h._show_profile()
	await process_frame
	var pt := _texts(h._profile_panel)
	print("ficha (en): ", pt.slice(0, 8), " | sigue en español: ", _spanish_left(pt, ["Mochi"]))
	h._profile_panel.queue_free()
	h._profile_panel = null
	h._show_album() if h.has_method("_show_album") else null
	await process_frame
	if h._album_panel != null:
		var at := _texts(h._album_panel)
		print("album (en): ", at.slice(0, 6), " | sigue en español: ", _spanish_left(at, ["Mochi"]))
	h.queue_free()
	await process_frame


## Area 5: minijuegos, misiones, vecinos, visitas, pueblo, cine, nube, amigos, seguridad y avisos.
func _area_rest(t: GDScript) -> void:
	var now := int(Time.get_unix_time_from_system())
	var names := ["Mochi", "Ana", "Luna", "Nube", "Bruno", "Pipo", "Chispa", "Tobi", "Bimba", "Fresa", "Mota", "Pipa", "Canelo", "Rulo", "Lunita", "Chicle", "Maní"]
	gs.reset_game()
	gs.set_language("en")
	gs.set_profile("Ana", "f")
	gs.age_group = "adult"
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.pompon.born_at = now - 10 * 86400
	gs.hatch_anim_pending = false
	gs.coins = 200
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "notify_ask", "night1", "town1"]
	gs.tutorial = {"chapter": 0, "step": 0, "off": true, "done_at": 0, "done_day": -1}
	var left_all := {}
	for scene in ["minigames", "simon_game", "pattern_game", "math_game", "jump_game", "paint_game", "music_game", "missions", "neighbors", "town", "cinema"]:
		var sc: Control = load("res://scenes/%s.tscn" % scene).instantiate()
		root.add_child(sc)
		await create_timer(1.2).timeout
		var tx := _texts(sc)
		var left := _spanish_left(tx, names)
		print(scene, " (en): ", tx.filter(func(s): return s.length() > 3).slice(0, 7), " | sigue en español: ", left, " | claves sueltas: ", _raw_keys(tx))
		if scene == "missions":
			for tab in sc.find_children("*", "Button", true, false):
				if tab.atr(tab.text) in ["Achievements", "This week"]:
					tab.pressed.emit()
					await process_frame
					print("  ", tab.atr(tab.text), ": sigue en español: ", _spanish_left(_texts(sc), names))
		if scene == "cinema":
			sc._start_movie()
			await create_timer(0.3).timeout
			print("  pelicula: ", _texts(sc).filter(func(s): return s.length() > 20).slice(0, 2))
			sc._end_movie()
			await create_timer(0.3).timeout
			var ct := _texts(sc)
			print("  final: ", ct.filter(func(s): return s.length() > 3).slice(0, 5), " | sigue en español: ", _spanish_left(ct, names))
		sc.queue_free()
		await process_frame
	# visita a un vecino
	var Neighbors: GDScript = load("res://scripts/neighbors.gd")
	Neighbors.current = "luna"
	var vs: Control = load("res://scenes/visit.tscn").instantiate()
	root.add_child(vs)
	await create_timer(1.5).timeout
	var vt := _texts(vs)
	print("visita (en): ", vt.filter(func(s): return s.length() > 3).slice(0, 8), " | sigue en español: ", _spanish_left(vt, names))
	vs.queue_free()
	# carteles de seguridad y nube
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(720, 1280)
	root.add_child(holder)
	var safety: GDScript = load("res://scripts/friend_safety.gd")
	safety.parental_gate(holder, func(_ok): pass)
	safety.friend_options(holder, {"code": "ABCDEFGH", "name": "Luna"})
	safety.report(holder, "ABCDEFGH", "Luna", "")
	gs.pending_art = [{"code": "ABCDEFGH", "who": "Luna", "px": "0".repeat(256)}]
	safety.show_received_art(holder)
	holder.add_child(load("res://scripts/cloud_panel.gd").new())
	await process_frame
	var ht := _texts(holder)
	print("seguridad y nube (en): ", ht.filter(func(s): return s.length() > 12).slice(0, 6), " | sigue en español: ", _spanish_left(ht, names))
	holder.queue_free()
	# textos que arma el juego
	var Notifier: GDScript = load("res://scripts/notifier.gd")
	var made := []
	for d in range(0, 21, 7):
		var m: Dictionary = Notifier.message(now + d * 86400, "Mochi", true)
		made.append(m["title"])
		made.append(m["text"])
	made.append(Notifier.message(now, "Mochi", false)["text"])
	gs.friend_actions = {}
	made.append(gs.friend_action("luna", "pet").get("msg", ""))
	made.append(gs.friend_action("luna", "pet").get("msg", ""))
	made.append(gs.watch_movie("colina", {"name": "Luna"})["reaction"])
	var Friends: Node = root.get_node("Friends")
	gs.pending_thoughts = []
	for kind in ["visit", "pet", "play", "gift"]:
		Friends._on_event({"kind": kind, "from": "ABCDEFGH"})
	made.append_array(gs.pending_thoughts.map(func(e): return e["text"]))
	made = made.filter(func(x): return str(x) != "")
	print("textos armados (en): ", made.slice(0, 8), " | sigue en español: ", _spanish_left(made, names))


func _initialize() -> void:
	_load_spanish_only()
	await process_frame
	gs = root.get_node("GameState")
	var t: GDScript = load("res://scripts/t.gd")

	# ---------- el CSV: todas las claves en los dos idiomas
	var f := FileAccess.open("res://locale/textos.csv", FileAccess.READ)
	f.get_csv_line()
	var keys := []
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3 and row[0] != "":
			keys.append(row[0])
	var missing := {"es": [], "en": []}
	for lg in ["es", "en"]:
		t.apply(lg)
		for k in keys:
			if t.t(k) == k or t.t(k) == "":
				missing[lg].append(k)
	print("textos.csv: ", keys.size(), " claves | sin traducir en es: ", missing["es"], " | en en: ", missing["en"])

	# ---------- cambiar de idioma
	gs.reset_game()
	gs.set_language("en")
	print("en ingles: T.lang=", t.lang(), " | menu.play='", t.t("menu.play"), "' | ui.Comer='", t.label("Comer"), "' | sin clave queda igual: '", t.label("Sofá"), "'")
	print("  con datos: '", t.t("home.egg_of", {"species": "bunny"}), "' | plural: '", t.n("home.in_days", 1), "' / '", t.n("home.in_days", 3), "' | genero: '", t.g("menu.reset_sure", "f"), "'")
	gs.set_language("es")
	print("en español: menu.play='", t.t("menu.play"), "' | genero f/m/n: '", t.g("menu.reset_sure", "f"), "' '", t.g("menu.reset_sure", "m"), "' '", t.g("menu.reset_sure", "n"), "'")
	gs.set_language("en")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
	print("se guarda en la partida: language=", saved.get("language", "?"))
	gs.reset_game()
	print("empezar de nuevo conserva el idioma: ", gs.language, " | T.lang=", t.lang())

	# ---------- partida vieja sin idioma: usa el del celular
	gs.language = ""
	gs.apply_save({"coins": 5, "player_name": "Ana", "player_title": "f"})
	t.apply(gs.language)
	print("partida vieja sin idioma: language='", gs.language, "' | usa el del celular: ", t.lang() == t.device_lang(), " (celular=", t.device_lang(), ")")
	gs.apply_save({"coins": 5, "language": "marciano"})
	print("  idioma invalido se ignora: language='", gs.language, "'")

	# ---------- menú en inglés y botón de idioma
	gs.reset_game()
	gs.set_language("en")
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var mt := _texts(menu)
	print("menu (en): ", mt.filter(func(s): return s in ["Play!", "Take care of your Pompon and learn as you play", "No ads · Made with love"]), " | claves sueltas: ", _raw_keys(mt))
	menu._toggle_language()
	await process_frame
	var mt2 := _texts(menu)
	print("boton de idioma -> ", gs.language, " | menu (es): ", mt2.filter(func(s): return s in ["¡Jugar!", "Cuida a tu Pompon y aprende jugando", "Sin anuncios · Hecho con cariño"]))
	menu._toggle_language()
	await process_frame
	print("  y vuelve: ", gs.language, " | ", menu._play.text)

	# edad y nombre en inglés
	menu._on_play()
	await process_frame
	var age: Node = _notice(menu)
	var at := _texts(age)
	print("edad (en): ", at.slice(0, 3), " ... ", at[-1], " | claves sueltas: ", _raw_keys(at))
	for b in age.find_children("*", "Button", true, false):
		if b.text == "9":
			b.pressed.emit()
	await process_frame
	var dlg = menu._profile
	dlg.accepted.disconnect(menu._enter_game)
	var dt := _texts(dlg)
	print("nombre, menor de 13 (en): ", dt.filter(func(s): return s in ["What's your name?", "More names", "Pronouns", "She / her", "He / him", "Done!"]), " | claves sueltas: ", _raw_keys(dt))
	menu.queue_free()
	await process_frame
	gs.age_group = "adult"
	var dlg2: Control = load("res://scripts/profile_dialog.gd").new()
	root.add_child(dlg2)
	dlg2.setup(true)
	print("nombre, adulto (en): placeholder='", dlg2._edit.placeholder_text, "' | ", _texts(dlg2).filter(func(s): return s in ["Make up a name", "Cancel"]))
	dlg2.queue_free()

	# ---------- bienvenida en inglés
	gs.player_name = "Ana"
	gs.player_title = "f"
	var w: Control = load("res://scenes/welcome.tscn").instantiate()
	root.add_child(w)
	await process_frame
	var wt := _texts(w)
	print("bienvenida (en): ", wt.filter(func(s): return s.begins_with("Hi,") or s.begins_with("Today") or s == "Adopt a Pompon"))
	w._choose_species()
	await process_frame
	var st := _texts(w._step)
	print("  especie: ", st.filter(func(s): return s in ["Pick a kind", "Its colors will be a surprise", "Bunny", "Kitty", "Dragon", "Surprise"]))
	w._pick_species("Conejo")
	await process_frame
	var sx := _texts(w._step)
	print("  sexo: ", sx.filter(func(s): return s in ["Girl or boy?", "Girl", "Boy"]), " | claves sueltas: ", _raw_keys(wt + st + sx))
	w.queue_free()
	await process_frame

	# ---------- casa en inglés: huevo, aviso y tutorial
	var now := int(Time.get_unix_time_from_system())
	gs.reset_game()
	gs.set_language("en")
	gs.set_profile("Ana", "f")
	gs.age_group = "adult"
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = false
	gs.daily_gift_day = Missions.today(now)
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(2.2).timeout
	var ht := _texts(h)
	print("casa con huevo (en): ", ht.filter(func(s): return s in ["Your bunny egg", "Menu", "Missions", "Neighbors", "Work", "Diary", "Shop"] or s.begins_with("Your egg is here!") or s.begins_with("Crib")), " | claves sueltas: ", _raw_keys(ht))
	h.queue_free()
	await process_frame
	gs.pompon.hatched = true
	gs.pompon.born_at = now - 3600
	gs.pompon.nickname = "Mochi"
	gs.hatch_anim_pending = false
	gs.tips_seen = ["egg1", "job1", "shopcrib", "notify_ask"]
	var h2: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h2)
	await create_timer(2.0).timeout
	var tt: Array = _texts(h2._tut) if h2._tut != null else []
	var h2t := _texts(h2)
	print("casa con Pompon (en): ", h2t.filter(func(s): return s in ["Eat", "Drink", "Bath", "Cuddle", "Games", "Pompon", "Home", "Food", "Water", "Clean", "Fun", "Comfort", "Sleep", "Trust", "Social"] or s == "Mochi" or s.begins_with("Growth") or s.begins_with("Day 1 of 7")))
	print("  tutorial (en): ", tt.filter(func(s): return s.begins_with("Hi!") or s in ["Skip tutorial", "Got it!"]), " | claves sueltas: ", _raw_keys(h2t))
	h2.queue_free()
	await process_frame

	# ---------- lo mismo en español (no cambia nada para quien juega en español)
	gs.set_language("es")
	var h3: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h3)
	await create_timer(2.0).timeout
	var h3t := _texts(h3)
	var tt3: Array = _texts(h3._tut) if h3._tut != null else []
	print("casa con Pompon (es): ", h3t.filter(func(s): return s in ["Comer", "Caricia", "Casa", "Comida", "Sueño"] or s == "Mochi" or s.begins_with("Día 1 de 7")), " | tutorial: ", tt3.filter(func(s): return s.begins_with("¡Hola!") or s == "Saltar tutorial"))
	h3.queue_free()

	gs.set_language("en")
	await _code_check(t)
	await _area_shop(t)
	await _area_jobs(t)
	await _area_spanish_class(t)
	await _area_diary(t)
	await _area_rest(t)

	gs.language = ""
	gs.reset_game()
	t.apply("")
	print("FIN test_locale")
	quit()
