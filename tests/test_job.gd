extends SceneTree
## El trabajo del periodico en pantalla: leccion, turno completo (aciertos y errores), paga fija,
## cartel de nota, y cartel de avance de nivel cuando el juego decide que se domina.


func _play_shift(job: Control, wrong_questions: Array) -> Dictionary:
	var out := {"explanations": 0, "hints": 0}
	var question := 0
	var guard := 0
	while job.state != 3 and guard < 30000:
		guard += 1
		await process_frame
		if job.state == 1:
			if job.exam_ready:  # un alumno levanto la mano: se toca para corregir
				job._on_exam_tapped()
		elif job.state == 2 and job._layer != null and not job._answered:
			var box: Node = job._layer.get_child(1).get_child(0)
			var row: Node = box.get_node("Options")
			var answer: int = job._problem["answer"]
			var want_wrong: bool = question in wrong_questions
			var pick: Button = null
			for b in row.get_children():
				if (int(b.get_meta("value")) == answer) != want_wrong:
					pick = b
					break
			question += 1
			pick.pressed.emit()
			await process_frame
			if want_wrong:
				var info: Node = box.get_node("Info")
				if info.visible:
					out["explanations"] += 1
				if info.visible and info.get_child_count() >= 3:
					out["hints"] += 1
				info.get_child(info.get_child_count() - 1).pressed.emit()  # "Entendido!"
	return out


## Toca el boton que dice `text` (dentro de `node`).
func _press(node: Node, text: String) -> void:
	for b in node.find_children("*", "Button", true, false):
		if b.text == text:
			b.pressed.emit()
			return
	print("FALLA: no encuentro el boton '", text, "'")


func _labels(node: Node) -> String:
	var texts := ""
	for lbl in node.find_children("*", "Label", true, false):
		texts += lbl.text + " | "
	return texts


func _initialize() -> void:
	await process_frame
	Engine.time_scale = 6.0
	var gs := root.get_node("GameState")
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.coins = 0
	gs.jobs_done = 0
	gs.math_progress = {}
	gs.math_weak = {}
	gs.mission_progress = {}
	gs.missions_claimed = []
	var math: GDScript = load("res://scripts/math_problems.gd")
	math.current_track = "mul"

	# ---------- turno 1: primera vez (intro + leccion), con dos errores
	var job: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job)
	await create_timer(0.4).timeout
	var intro := _labels(job._layer)
	print("primer turno: intro=", job.state == 0, " | explica con animacion=", job._layer.find_children("*", "IntroDemo", true, false).size() == 1, " | dice que hacer=", intro.contains("Ordena") and intro.contains("Corrige"), " | poco texto=", intro.length() < 170)
	var intro_box: Node = job._layer.get_child(1).get_child(0)
	intro_box.get_child(intro_box.get_child_count() - 1).pressed.emit()  # "A ensenar!"
	await process_frame
	await process_frame
	# el primer turno es corto y sin el cartel de la leccion (menos carteles antes de que nazca el Pompon)
	print("primer turno corto, sin leccion: juega directo=", job.state == 1 and job._layer == null, " | leccion marcada como vista=", gs.lesson_seen("mul", 1),
		" | examenes=", job.shift_questions, " | reloj=", job._timer_label.text)

	var played := await _play_shift(job, [1])
	print("turno terminado: estado=", job.state, " | aciertos=", job.correct, " de 3 | errores guardados=", job.mistakes.size(), " | explicaciones=", played["explanations"], " | con dibujo=", played["hints"])
	var pay: int = load("res://scripts/jobs.gd").pay_for_level(1)
	print("monedas: ", gs.coins, " (", pay, " de paga + 20 extra por terminar el turno) | sin premio de nivel (primer turno): ", gs.coins == pay + 20)
	# el primer turno muestra antes el cartel del tutorial ("¡Perfecto!... compremos una cuna") y despues la nota
	var first := _labels(job._layer)
	print("primer turno: cartel del tutorial antes de la nota=", first.contains("¡Perfecto!") and not first.contains("Nota:"))
	_press(job._layer, "Ver mi nota")
	await process_frame
	await process_frame
	var texts := _labels(job._layer)
	print("cartel: ", texts.substr(0, 600))
	print("  nota=", texts.contains("Nota:"), " paga=", texts.contains("+%d monedas" % pay), " nivel=", texts.contains("Nivel 1"), " repaso=", texts.contains("Para repasar"))
	print("  dice como subir (de 8)=", texts.contains("Para subir: ") and texts.contains(" / 8"))
	print("  muestra la respuesta correcta de lo fallado=", job.mistakes.all(func(m): return texts.contains("%s = %d" % [m["text"], m["answer"]])))
	print("repaso: ", gs.weak_facts("mul").size(), " cuentas falladas quedan para repasar | historial=", gs.math_state("mul")["history"].size(), " respuestas")
	var times_ok: bool = job.answer_times.size() == 3 and job.answer_times.all(func(t): return t >= 0.0)
	print("se midio el tiempo de las 3 respuestas: ", times_ok)
	job.queue_free()
	Engine.time_scale = 1.0
	await process_frame

	# ---------- turno 2: el juego decide que domino el nivel -> cartel de avance con premio
	gs.math_state("mul")["history"] = []
	for i in 7:
		gs.math_state("mul")["history"].append({"c": true, "t": 1.0})  # 7 perfectas y rapidisimas de turnos anteriores
	var before: int = gs.coins
	Engine.time_scale = 6.0
	var job2: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job2)
	await create_timer(0.4).timeout
	print("turno 2: ya vio la leccion, juega directo: estado=", job2.state)
	await _play_shift(job2, [])
	var level_up := _labels(job2._layer)
	print("cartel de avance: ", level_up.substr(0, 400))
	print("  dice que subio=", level_up.contains("SUBISTE"), " premio fijo=", level_up.contains("+30 monedas"))
	print("  nivel ahora: ", gs.math_level("mul"), " (de 1 salta a 3 por responder rapidisimo)")
	print("  monedas ganadas: ", gs.coins - before, " (", pay, " de paga + 30 de premio + 20 extra): ", gs.coins - before == pay + 50)
	# "Genial!" -> cartel con la nota
	var box2: Node = job2._layer.get_child(1).get_child(0)
	box2.get_child(box2.get_child_count() - 1).pressed.emit()
	await process_frame
	await process_frame
	var res_text := _labels(job2._layer)
	print("tras 'Genial!': cartel de nota=", res_text.contains("Nota:"), " | recuerda el premio=", res_text.contains("premio por el nivel"), " | nivel nuevo=", res_text.contains("nivel 3"))
	Engine.time_scale = 1.0

	# ---------- la oficina y la leccion bajo demanda
	var office: Control = load("res://scenes/job_menu.tscn").instantiate()
	root.add_child(office)
	await create_timer(0.3).timeout
	var office_text := _labels(office)
	print("oficina: tres caminos=", office_text.contains("Sumas y restas") and office_text.contains("Multiplicaciones") and office_text.contains("Divisiones"), " | paga fija visible=", office_text.contains("+%d" % pay), " | poco texto (menos de 400 letras)=", office_text.length() < 400, " | nivel 3 de multiplicaciones=", office_text.contains("Nivel 3") and office_text.contains("Tabla del 3"))
	office._show_lesson("mul", 3)
	await process_frame
	print("ver leccion: ", _labels(office._layer).contains("Tabla del 3"))

	# ---------- cobrar antes: despues del primer examen se puede terminar (solo la paga de siempre)
	Engine.time_scale = 6.0
	var coins_before: int = gs.coins
	var job3: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job3)
	await create_timer(0.3).timeout
	if job3.state == 0:
		job3._close_layer()
		job3._start_play()
	print("reloj: empieza en ", job3._timer_label.text, " | el boton de cobrar empieza escondido: ", not job3._finish_button.visible)
	var guard := 0
	while not job3.exam_ready and guard < 4000:
		guard += 1
		await process_frame
	job3._on_finish_pressed()
	print("no se puede cobrar antes del primer examen: ", job3.state == 1)
	job3._on_exam_tapped()
	await process_frame
	var box3: Node = job3._layer.get_child(1).get_child(0)
	for b in box3.get_node("Options").get_children():
		if int(b.get_meta("value")) == job3._problem["answer"]:
			b.pressed.emit()
			break
	await create_timer(1.4).timeout
	print("tras el primer examen aparece 'Terminar y cobrar': ", job3._finish_button.visible, " | sigue jugando: estado=", job3.state)
	var left_before: float = job3.time_left
	await create_timer(0.3).timeout
	print("el reloj corre mientras juega: ", job3.time_left < left_before)
	job3._on_finish_pressed()
	await process_frame
	var cash_text := _labels(job3._layer)
	print("cobrar antes: monedas ganadas=", gs.coins - coins_before, " (solo la paga de ", pay, ") | sin el extra=", not cash_text.contains("Turno completo"), " | sin carteles de mas=", not cash_text.contains("Termina el turno completo"))
	job3.queue_free()
	await process_frame

	# ---------- terminar el turno completo da monedas extra
	gs.paid_shifts_day = -1   # (es otro dia: vuelven los turnos con paga)
	var coins_before2: int = gs.coins
	var job4: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job4)
	await create_timer(0.3).timeout
	if job4.state == 0:
		job4._close_layer()
		job4._start_play()
	await _play_shift(job4, [])
	var full_text := _labels(job4._layer)
	print("turno completo: monedas ganadas=", gs.coins - coins_before2, " | dice que fue completo=", full_text.contains("Turno completo! +20"))
	job4.queue_free()
	await process_frame

	# ---------- tope diario: despues de 3 turnos con paga, los demas son de practica (paga chica, sin extra)
	gs.paid_shifts_day = -1
	print("turnos con paga al empezar el dia: ", gs.paid_shifts_left(), " | paga=", gs.job_pay())
	for i in 3:
		gs.finish_job("mul", 5, 5, true)
	var office2: Control = load("res://scenes/job_menu.tscn").instantiate()
	root.add_child(office2)
	await create_timer(0.3).timeout
	var office2_text := _labels(office2)
	print("tras 3 turnos: quedan=", gs.paid_shifts_left(), " | paga=", gs.job_pay(), " | el aula lo dice=", office2_text.contains("Hoy ya cobraste."), " | muestra +", gs.PRACTICE_PAY, "=", office2_text.contains("+%d" % gs.PRACTICE_PAY))
	office2.queue_free()
	var coins_before3: int = gs.coins
	var job5: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job5)
	await create_timer(0.3).timeout
	if job5.state == 0:
		job5._close_layer()
		job5._start_play()
	await _play_shift(job5, [])
	var practice_text := _labels(job5._layer)
	while not practice_text.contains("Nota:") and job5._layer != null:   # (puede haber un cartel de avance antes)
		var b5: Node = job5._layer.get_child(1).get_child(0)
		b5.get_child(b5.get_child_count() - 1).pressed.emit()
		await process_frame
		await process_frame
		practice_text = _labels(job5._layer)
	var gained: int = gs.coins - coins_before3
	print("turno de practica: paga ", gs.PRACTICE_PAY, " (+30 si sube de nivel)=", gained == gs.PRACTICE_PAY or gained == gs.PRACTICE_PAY + 30,
		" | sin el extra=", not practice_text.contains("Turno completo"), " | lo explica=", practice_text.contains("este fue de práctica"))
	gs.paid_shifts_day = -1
	print("otro dia: vuelven los turnos con paga=", gs.paid_shifts_left(), " | paga=", gs.job_pay())
	Engine.time_scale = 1.0
	quit()
