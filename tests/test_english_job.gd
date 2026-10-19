extends SceneTree
## Trabajo de profesor/a de ingles: el contenido (palabras, dibujos, frases), el aula, un turno
## completo con errores, el repaso de palabras falladas y la carrera compartida con matematicas.


func _labels(node: Node) -> String:
	var texts := ""
	for lbl in node.find_children("*", "Label", true, false):
		texts += lbl.text + " | "
	return texts


func _play_shift(job: Control, wrong_questions: Array) -> Dictionary:
	var out := {"explanations": 0, "pictures": 0, "said": 0, "prompts": []}
	var question := 0
	var guard := 0
	while job.state != 3 and guard < 30000:
		guard += 1
		await process_frame
		if job.state == 1:
			if job.exam_ready:
				job._on_exam_tapped()
		elif job.state == 2 and job._layer != null and not job._answered:
			var box: Node = job._layer.get_child(1).get_child(0)
			var row: Node = box.get_node("Options")
			out["prompts"].append(box.get_node("Prompt").text)
			if box.find_children("*", "EnglishPicture", true, false).size() > 0:
				out["pictures"] += 1
			var want_wrong: bool = question in wrong_questions
			var pick: Button = null
			for b in row.get_children():
				if (str(b.get_meta("value")) == str(job._problem["answer"])) != want_wrong:
					pick = b
					break
			question += 1
			pick.pressed.emit()
			await process_frame
			if _labels(box).contains("se dice:") or _labels(box).contains("Se dice:"):
				out["said"] += 1
			if want_wrong:
				var info: Node = box.get_node("Info")
				if info.visible:
					out["explanations"] += 1
				info.get_child(info.get_child_count() - 1).pressed.emit()  # "Entendido!"
	return out


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var en: GDScript = load("res://scripts/english_problems.gd")
	var jobs: GDScript = load("res://scripts/jobs.gd")
	var pic_script: GDScript = load("res://scripts/english_picture.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# ---------- contenido
	var ok_options := true
	var ok_unique := true
	var ok_pics := true
	var ok_lookup := true
	var words := 0
	var phrases := 0
	var pictures := []
	for track in en.TRACKS:
		for level in range(1, 11):
			var list: Array = en.items(track, level)
			if list.size() < 8:
				print("  pocas en ", track, " ", level)
				ok_options = false
			var seen_en := {}
			var seen_es := {}
			for it in list:
				if track == "en_phrases":
					phrases += 1
					ok_options = ok_options and it["options"].has(it["answer"]) and String(it["en"]).contains("___")
				else:
					words += 1
					ok_unique = ok_unique and not seen_en.has(it["en"]) and not seen_es.has(it["es"])
					seen_en[it["en"]] = true
					seen_es[it["es"]] = true
					if it["pic"] != "":
						ok_pics = ok_pics and pic_script.has_picture(it["pic"])
						pictures.append(it["pic"])
				var p: Dictionary = en.build_problem(track, level, it, rng)
				var opts: Array = p["options"]
				var distinct := {}
				for o in opts:
					distinct[o] = true
				ok_options = ok_options and opts.has(p["answer"]) and distinct.size() == opts.size() and opts.size() >= 2
				ok_lookup = ok_lookup and en.find_item(track, p["key"]) == it
	print("contenido: ", words, " palabras y ", phrases, " frases | opciones bien armadas: ", ok_options,
		" | sin palabras repetidas en un nivel: ", ok_unique, " | dibujos que existen: ", ok_pics, " (", pictures.size(), ") | claves: ", ok_lookup)
	var p1: Dictionary = en.build_problem("en_words", 1, en.items("en_words", 1)[0], rng)
	print("pregunta de palabras: ", p1["prompt"], " -> ", p1["answer"], " ", p1["options"], " | ", p1["ask"])
	print("  si se falla: ", en.explanation(p1).replace("\n", " / "))
	var p2: Dictionary = en.build_problem("en_meaning", 1, en.items("en_meaning", 1)[0], rng)
	print("pregunta de significado: ", p2["prompt"], " -> ", p2["answer"], " ", p2["options"])
	var p3: Dictionary = en.build_problem("en_phrases", 1, en.items("en_phrases", 1)[0], rng)
	print("frase: ", p3["prompt"], " (", p3["ask"], ") -> ", p3["answer"], " ", p3["options"], " | completa: ", p3["text"])
	print("  si se falla: ", en.explanation(p3).replace("\n", " / "))
	print("leccion de colores: ", String(en.lesson("en_words", 1)["lines"][0]).replace("\n", " / "))
	print("leccion de frases: ", String(en.lesson("en_phrases", 2)["lines"][0]).replace("\n", " / "))
	print("dominio: 8 rapidas -> ", en.evaluate("en_words", 1, Array(range(8)).map(func(_i): return {"c": true, "t": 2.0}))["action"],
		" | 8 lentas -> ", en.evaluate("en_words", 1, Array(range(8)).map(func(_i): return {"c": true, "t": 9.0}))["action"])
	print("materia de cada camino: ", jobs.subject_of("en_phrases"), " / ", jobs.subject_of("mul"))

	# los dibujos se dibujan sin errores
	var holder := Control.new()
	root.add_child(holder)
	for code in pictures:
		var art: Control = pic_script.new()
		art.size = Vector2(220, 190)
		art.show_pic(code)
		holder.add_child(art)
	await process_frame
	await process_frame
	print("se dibujaron ", holder.get_child_count(), " dibujos")
	holder.queue_free()

	# ---------- el periodico: Ingles ya se puede aplicar
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.coins = 0
	gs.jobs_done = 3
	gs.math_progress = {}
	gs.math_weak = {}
	gs.set_profile("Ana", "f")
	gs.tips_seen = ["job_intro", "job_hired", "job_first_shift"]
	gs.math_state("addsub")["answered"] = 5
	var english: Dictionary = jobs.get_job("english")
	print("ingles disponible: ", english["available"], " | ", english["scene"])
	var board: Control = load("res://scenes/job_board.tscn").instantiate()
	root.add_child(board)
	await process_frame
	board._open("english")
	await process_frame
	var notice := _labels(board._layer)
	print("cartel nuevo puesto: ", notice.contains("también enseñas Inglés"), " | misma carrera: ", notice.contains("mismos"), " | materia elegida: ", jobs.current)
	board.queue_free()
	await process_frame

	# ---------- el aula de ingles
	var office: Control = load("res://scenes/job_menu.tscn").instantiate()
	root.add_child(office)
	await create_timer(0.2).timeout
	var office_text := _labels(office)
	print("aula: ", office_text.contains("Aula de Inglés"), " | tres caminos: ", office_text.contains("Palabras") and office_text.contains("¿Qué significa?") and office_text.contains("Frases"),
		" | niveles: ", office_text.contains("Colores") and office_text.contains("Saludos") and office_text.contains("Am, is, are"))
	office._show_lesson("en_words", 1)
	await process_frame
	print("leccion: ", _labels(office._layer).contains("red = rojo"))
	office.queue_free()
	await process_frame

	# ---------- un turno de palabras con dos errores
	Engine.time_scale = 6.0
	en.current_track = "en_words"
	var coins_before: int = gs.coins
	var job: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job)
	await create_timer(0.3).timeout
	print("turno de ingles: materia=", job.subject, " camino=", job.camino, " | leccion antes de jugar: ", job.state == 0 and _labels(job._layer).contains("Colores"))
	job._layer.get_child(1).get_child(0).closed.emit()
	await process_frame
	var played := await _play_shift(job, [0, 2])
	print("turno terminado: aciertos=", job.correct, " de 5 | explicaciones=", played["explanations"], " | con dibujo=", played["pictures"], " | muestran pronunciacion=", played["said"])
	print("  preguntas: ", played["prompts"])
	var texts := _labels(job._layer)
	print("cartel: nota=", texts.contains("Nota:"), " | 'Bien: 3 de 5'=", texts.contains("Bien: 3 de 5"), " | repaso con la palabra=", job.mistakes.all(func(m): return texts.contains(m["review"])))
	print("  repaso: ", job.mistakes.map(func(m): return m["review"]))
	print("palabras para repasar: ", gs.weak_facts("en_words"), " | turnos=", gs.jobs_done, " (era 3) | monedas=", gs.coins - coins_before)
	print("ficha: ", load("res://scripts/teacher_card.gd").subjects())
	job.queue_free()
	await process_frame

	# ---------- un turno de frases (las frases se completan al responder)
	en.current_track = "en_phrases"
	var job2: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job2)
	await create_timer(0.3).timeout
	if job2.state == 0:
		job2._layer.get_child(1).get_child(0).closed.emit()
		await process_frame
	var guard := 0
	while not job2.exam_ready and guard < 4000:
		guard += 1
		await process_frame
	job2._on_exam_tapped()
	await process_frame
	var box: Node = job2._layer.get_child(1).get_child(0)
	var before_text: String = box.get_node("Prompt").text
	for b in box.get_node("Options").get_children():
		if str(b.get_meta("value")) == str(job2._problem["answer"]):
			b.pressed.emit()
			break
	await process_frame
	print("frase: '", before_text, "' -> '", box.get_node("Prompt").text, "'")
	job2.queue_free()
	Engine.time_scale = 1.0
	await process_frame

	# ---------- guardar y cargar: el progreso de ingles y las palabras falladas quedan
	gs.math_weak["en_words"].append({"key": "99:nada", "streak": 0})
	var saved: Dictionary = JSON.parse_string(JSON.stringify(gs.save_dict()))
	gs._load_math(saved)
	print("tras cargar: nivel de palabras=", gs.math_level("en_words"), " | respondidas=", gs.math_state("en_words")["answered"],
		" | falladas=", gs.weak_facts("en_words").size(), " (sin la que no existe)")

	# ---------- matematicas sigue igual
	jobs.current = "math"
	var job3: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job3)
	await create_timer(0.2).timeout
	print("matematicas: materia=", job3.subject, " camino=", job3.camino)
	job3.queue_free()
	await process_frame
	quit()
