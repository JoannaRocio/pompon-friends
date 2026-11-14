extends SceneTree
## Trabajo de profesor/a de geografia: banderas dibujadas, capitales con pista (primera letra y las
## tres opciones empiezan igual) en los niveles 1-5 y sin pista despues, preguntas de banderas, el aula,
## un turno completo y el repaso guardado.


func _labels(node: Node) -> String:
	var texts := ""
	for lbl in node.find_children("*", "Label", true, false):
		texts += lbl.text + " | "
	return texts


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var geo: GDScript = load("res://scripts/geography_problems.gd")
	var flags: GDScript = load("res://scripts/flag_art.gd")
	var jobs: GDScript = load("res://scripts/jobs.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11

	# ---------- contenido
	var all: Array = geo.all_countries()
	var no_flag := all.filter(func(c): return not flags.has_flag(c["id"])).map(func(c): return c["id"])
	print("paises: ", all.size(), " | todos con bandera: ", no_flag.is_empty(), " ", no_flag)
	var hint_ok := true
	var hard_ok := true
	var flags_ok := true
	var kinds := {}
	for level in range(1, 11):
		for it in geo.items("geo_capitals", level):
			for track in geo.TRACKS:
				for k in 3:
					var p: Dictionary = geo.build_problem(track, level, it, rng)
					kinds[p["kind"]] = true
					var opts: Array = p["options"]
					if opts.size() != 3 or not opts.has(p["answer"]):
						flags_ok = false
					if p["option_flags"]:
						flags_ok = flags_ok and opts.all(func(o): return flags.has_flag(o))
					elif level <= geo.HINT_LEVELS:
						var letter: String = geo.initial(p["answer"])
						var same: int = opts.filter(func(o): return geo.initial(o) == letter).size()
						# con pista, las tres empiezan igual; si en el mundo casi no hay capitales con esa letra
						# (Quito, Ottawa), esa pregunta va sin pista
						hint_ok = hint_ok and ((p["hint"] != "" and same == 3) or (p["hint"] == "" and letter in ["Q", "O"]))
					else:
						hard_ok = hard_ok and p["hint"] == ""
	print("tipos de pregunta: ", kinds.keys())
	print("con pista: las 3 opciones empiezan con la misma letra: ", hint_ok, " | sin pista despues del nivel 5: ", hard_ok, " | opciones bien: ", flags_ok)
	var japan: Dictionary = geo.find_country("japon")
	var q: Dictionary = geo.build_problem("geo_capitals", 4, japan, rng)
	print("ejemplo nivel 4: ", q["ask"], " ", q["hint"], " ", q["options"], " -> ", q["answer"])
	var q2: Dictionary = geo.build_problem("geo_capitals", 9, japan, rng)
	print("ejemplo nivel 9: ", q2["ask"], " '", q2["hint"], "' ", q2["options"])
	var q3: Dictionary = geo.build_problem("geo_flags", 4, japan, rng, "country_to_flag")
	print("elegir bandera: ", q3["ask"], " ", q3["prompt"], " ", q3["options"])
	print("nombres de nivel: ", geo.level_name("geo_capitals", 1), " / ", geo.level_name("geo_capitals", 6))
	print("si se falla: ", geo.explanation(q))
	print("materia: ", jobs.subject_of("geo_mix"), " | disponible: ", jobs.get_job("geography")["available"])

	# todas las banderas se dibujan
	var holder := Control.new()
	root.add_child(holder)
	for c in all:
		var f: Control = flags.new()
		f.size = Vector2(120, 80)
		f.show_flag(c["id"])
		holder.add_child(f)
	await process_frame
	await process_frame
	print("se dibujaron ", holder.get_child_count(), " banderas")
	holder.queue_free()

	# ---------- el periodico y el aula
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.jobs_done = 5
	gs.math_progress = {}
	gs.math_weak = {}
	gs.set_profile("Ana", "f")
	gs.tips_seen = ["job_intro", "job_hired", "job_first_shift"]
	gs.math_state("addsub")["answered"] = 4
	gs.math_state("en_words")["answered"] = 4
	var board: Control = load("res://scenes/job_board.tscn").instantiate()
	root.add_child(board)
	await process_frame
	board._open("geography")
	await process_frame
	print("cartel nuevo puesto: ", _labels(board._layer).contains("también enseñas Geografía"))
	board.queue_free()
	await process_frame
	var office: Control = load("res://scenes/job_menu.tscn").instantiate()
	root.add_child(office)
	await create_timer(0.2).timeout
	var ot := _labels(office)
	print("aula: ", ot.contains("Aula de Geografía"), " | caminos: ", ot.contains("Capitales") and ot.contains("Banderas"), " | nivel 1 con pista: ", ot.contains("Sudamérica (con pista)"))
	office._show_lesson("geo_capitals", 1)
	await process_frame
	print("leccion con banderas: ", office._layer.find_children("*", "FlagArt", true, false).size(), " | ", _labels(office._layer).contains("Argentina: Buenos Aires"))
	office.queue_free()
	await process_frame

	# ---------- un turno con dos errores (capitales y banderas)
	Engine.time_scale = 6.0
	for track in ["geo_capitals", "geo_flags"]:
		jobs.set_track(track)
		var job: Control = load("res://scenes/job_game.tscn").instantiate()
		root.add_child(job)
		await create_timer(0.3).timeout
		if job.state == 0:
			job._layer.get_child(1).get_child(0).closed.emit()
			await process_frame
		var question := 0
		var seen := []
		var guard := 0
		while job.state != 3 and guard < 30000:
			guard += 1
			await process_frame
			if job.state == 1 and job.exam_ready:
				job._on_exam_tapped()
			elif job.state == 2 and job._layer != null and not job._answered:
				var box: Node = job._layer.get_child(1).get_child(0)
				seen.append("%s%s" % [job._problem["kind"], " (pista %s)" % job._problem["hint"] if job._problem["hint"] != "" else ""])
				var want_wrong := question in [0, 2]
				for b in box.get_node("Options").get_children():
					if (str(b.get_meta("value")) == str(job._problem["answer"])) != want_wrong:
						b.pressed.emit()
						break
				question += 1
				await process_frame
				if want_wrong:
					var info: Node = box.get_node("Info")
					info.get_child(info.get_child_count() - 1).pressed.emit()
		var t := _labels(job._layer)
		print(track, ": materia=", job.subject, " | aciertos=", job.correct, " de 5 | preguntas: ", seen)
		print("  cartel: nota=", t.contains("Nota:"), " | repaso: ", job.mistakes.map(func(m): return m["review"]))
		job.queue_free()
		await process_frame
	Engine.time_scale = 1.0
	print("para repasar: ", gs.weak_facts("geo_capitals").size() + gs.weak_facts("geo_flags").size(), " | ficha: ", load("res://scripts/teacher_card.gd").subjects())
	var saved: Dictionary = JSON.parse_string(JSON.stringify(gs.save_dict()))
	gs._load_math(saved)
	print("tras cargar: respondidas=", gs.math_state("geo_capitals")["answered"], " | repaso=", gs.weak_facts("geo_capitals").size() + gs.weak_facts("geo_flags").size())
	quit()
