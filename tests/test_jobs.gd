extends SceneTree
## Ofertas de empleo: profesor/a de matematicas, ingles y geografia disponibles,
## titulo segun como quiera que lo llamen el jugador, y que se guarde.


func _texts(node: Node, kind: String) -> Array:
	var out := []
	for n in node.find_children("*", kind, true, false):
		out.append(n.text)
	return out


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")

	# ---------- datos
	var jobs: GDScript = load("res://scripts/jobs.gd")
	print("trabajos: ", jobs.JOBS.map(func(j): return j["id"]), " | disponibles: ", jobs.JOBS.filter(func(j): return j["available"]).map(func(j): return j["id"]))
	for j in jobs.JOBS:
		print("  ", j["id"], " -> f='", j["title"]["f"], "' m='", j["title"]["m"], "' n='", j["title"]["n"], "'")
	print("matematicas lleva a una escena que existe: ", ResourceLoader.exists(jobs.get_job("math")["scene"]))
	print("ingles y geografia llevan al aula: ", jobs.get_job("english")["scene"] == jobs.get_job("math")["scene"] and jobs.get_job("geography")["scene"] == jobs.get_job("math")["scene"])
	print("sexo desconocido o vacio usa el neutro: '", jobs.title("math", ""), "' / '", jobs.title("math", "x"), "'")
	print("palabra: ", jobs.teacher_word("f"), " | ", jobs.teacher_word("m"), " | ", jobs.teacher_word(""))
	print("saludos: ", jobs.greeting("f"), " | ", jobs.greeting("m"), " | ", jobs.greeting("n"))
	print("con nombre: ", jobs.greeting("f", "Ana"), " | ", jobs.greeting("m", "Leo"), " | ", jobs.greeting("n", "Sol"))
	print("puesto: ", jobs.full_title("f", "Ana"), " | ", jobs.full_title("m", " Leo "), " | ", jobs.full_title("n", ""))

	# ---------- menu: la primera vez pregunta nombre y sexo antes de jugar
	gs.player_title = ""
	gs.player_name = ""
	gs.age_group = "adult"   # (la edad se pregunta antes: ver test_kids_names)
	print("sin perfil: has_profile=", gs.has_profile())
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	menu._on_play()
	await process_frame
	var dlg = menu._profile
	print("menu: aparece el dialogo=", dlg != null, " | listo desactivado=", dlg._ok.disabled)
	print("  botones: ", _texts(dlg, "Button"))
	var first_idea := ""
	dlg._random.pressed.emit()
	first_idea = dlg._edit.text
	dlg._random.pressed.emit()
	print("inventar nombre: primero='", first_idea, "' despues='", dlg._edit.text, "' distintos=", first_idea != dlg._edit.text, " | valido=", first_idea != "" and dlg._edit.text.length() <= 14, " | todos validos=", dlg.NAME_IDEAS.all(func(n): return n.length() <= 14 and n == n.strip_edges()))
	dlg._edit.text = ""
	dlg._edit.text_changed.emit("")
	for b in dlg.find_children("*", "Button", true, false):
		if b.text == "Soy ella":
			b.pressed.emit()
	await process_frame
	print("  solo sexo, sin nombre: listo desactivado=", dlg._ok.disabled)
	dlg._edit.text = "   "
	dlg._edit.text_changed.emit("   ")
	print("  nombre en blanco: listo desactivado=", dlg._ok.disabled)
	dlg._edit.text = "  Ana Maria Del Carmen Gonzalez  "
	dlg._edit.text_changed.emit(dlg._edit.text)
	print("  nombre y sexo: listo desactivado=", dlg._ok.disabled)
	dlg._ok.pressed.emit()
	print("  guardado: nombre='", gs.player_name, "' (", gs.player_name.length(), " letras) titulo='", gs.player_title, "' has_profile=", gs.has_profile())
	menu.queue_free()
	await process_frame

	# ---------- tablon sin elegir titulo: lo pregunta
	gs.new_pompon("Conejo", "Hembra")
	gs.set_profile("Ana", "f")
	gs.tips_seen.append("job_intro")   # el cartel de "necesitas monedas" ya se vio (lo prueba test_career)
	var board: Control = load("res://scenes/job_board.tscn").instantiate()
	root.add_child(board)
	await create_timer(0.4).timeout
	print("con perfil: no vuelve a preguntar=", board._layer == null)
	var labels := _texts(board, "Label")
	print("  ofertas: ", labels.filter(func(t): return t.begins_with("Profesor")))
	print("  encabezado: ", labels.filter(func(t): return t.contains("EMPLEO") or t.contains("PERIÓDICO")))
	var buttons := _texts(board, "Button")
	print("  botones: ", buttons)
	print("  'Aplicar' en los tres: ", buttons.count("Aplicar") == 3, " | bloqueados: ", buttons.count("Bloqueado"))
	print("  ninguno dice Proximamente: ", labels.count("Próximamente") == 0, " | sin carteles de vacantes: ", labels.count("¡Hay vacantes!") == 0)
	board._open("astronomia")
	print("tocar un trabajo bloqueado: '", board._message.text, "'")

	# ---------- cambiar el titulo
	board._ask_profile(true)
	await process_frame
	var cancel_present := _texts(board._layer, "Button").has("Cancelar")
	var d2 = board._layer
	print("cambiar: precarga nombre='", d2._edit.text, "'")
	d2._edit.text = "Leo"
	d2._edit.text_changed.emit("Leo")
	for b in d2.find_children("*", "Button", true, false):
		if b.text == "Soy él":
			b.pressed.emit()
	await process_frame
	d2._ok.pressed.emit()
	await process_frame
	await process_frame
	var labels2 := _texts(board, "Label")
	print("cambiar: se puede cancelar=", cancel_present, " | ahora='", gs.player_title, "' '", gs.player_name, "' | ", labels2.filter(func(t): return t.begins_with("Profesor") or t.begins_with("Tu puesto")))
	board.queue_free()
	await process_frame

	# ---------- con titulo ya elegido no vuelve a preguntar
	var board2: Control = load("res://scenes/job_board.tscn").instantiate()
	root.add_child(board2)
	await create_timer(0.4).timeout
	print("segunda vez: no pregunta=", board2._layer == null)
	board2.queue_free()
	await process_frame
	# sin nombre (partida vieja): el tablon lo pide
	gs.player_name = ""
	var board3: Control = load("res://scenes/job_board.tscn").instantiate()
	root.add_child(board3)
	await create_timer(0.4).timeout
	print("partida vieja sin nombre: lo pide=", board3._layer != null)
	board3.queue_free()
	await process_frame
	gs.set_profile("Ana", "f")

	# ---------- el aula y el juego usan el titulo
	var office: Control = load("res://scenes/job_menu.tscn").instantiate()
	root.add_child(office)
	await create_timer(0.3).timeout
	var office_labels := _texts(office, "Label")
	print("aula: ", office_labels.filter(func(t): return t.contains("Aula") or t.contains("Escuela")), " | vuelve a las ofertas=", _texts(office, "Button").has("Volver a las ofertas"))
	gs.set_profile("Ana", "f")
	gs.jobs_done = 0
	var job: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(job)
	await create_timer(0.3).timeout
	var intro := " ".join(_texts(job._layer, "Label"))
	print("intro del trabajo: saludo=", intro.contains("Bienvenida a la escuela, profesora Ana"), " | explicacion=", intro.contains("Ordena") and intro.contains("Corrige"))

	# ---------- se guarda y se sanea
	gs.save_game()
	gs.player_title = ""
	gs.player_name = ""
	gs.load_game()
	print("tras recargar: titulo='", gs.player_title, "' nombre='", gs.player_name, "'")
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"coins": 1, "player_title": "marciano", "player_name": "   ", "pompon": null}))
	f.close()
	gs.load_game()
	print("valor invalido se descarta: '", gs.player_title, "' nombre='", gs.player_name, "' perfil=", gs.has_profile())
	quit()
