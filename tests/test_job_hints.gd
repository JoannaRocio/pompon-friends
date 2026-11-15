extends SceneTree
## Guias del trabajo: flechas en las ofertas y en el aula la primera vez, y ayudas dentro del turno
## (dedito para ordenar, flecha al examen y a las respuestas).


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.player_name = "Ana"
	gs.player_title = "f"
	gs.age_group = "adult"
	gs.jobs_done = 0
	gs.coins = 0
	gs.owned = []
	print("guia con 0 trabajos: ", gs.job_guide_on(), " (esperado true)")

	var board: Control = load("res://scenes/job_board.tscn").instantiate()
	root.add_child(board)
	await process_frame
	await process_frame
	# la primera vez sale el cartel "Para cuidar a tu Pompon necesitas monedas": mientras tanto no hay flecha
	print("ofertas: cartel de la primera vez=", board._layer != null, " | sin flecha encima del cartel=", not board._arrow.visible)
	for b in board._layer.find_children("*", "Button", true, false):
		if b.text == "¡Vamos!":
			b.pressed.emit()
	await process_frame
	await process_frame
	print("ofertas: flecha visible=", board._arrow.visible, " apunta a Aplicar=", board._arrow.target in board._apply_buttons)
	board.queue_free()

	var menu: Control = load("res://scenes/job_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	print("aula: flecha recorre ", menu._arrow.targets.size(), " botones Trabajar (esperado 3) visible=", menu._arrow.visible)
	menu.queue_free()

	# ya trabajo y le alcanza para la cuna: el aula señala la tienda
	gs.jobs_done = 1
	gs.coins = 60
	var menu2: Control = load("res://scenes/job_menu.tscn").instantiate()
	root.add_child(menu2)
	await process_frame
	await process_frame
	print("aula con monedas: señala tienda=", menu2._arrow.target == menu2._shop_button and menu2._shop_button != null)
	menu2.queue_free()
	gs.owned = [gs.CRIB_ID]
	print("guia con cuna comprada y trabajos hechos: ", gs.job_guide_on(), " (esperado false)")

	# dentro del turno
	var game: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._close_layer()
	game._start_play()
	game.sorter.hint_delay = 1.0
	await create_timer(1.6).timeout
	print("dedito para ordenar: ", game.sorter.is_hinting())
	game._signal_t = 0.0
	await create_timer(game.EXAM_HINT + 0.6).timeout
	print("mano levantada: flecha al examen=", game._arrow.visible and game._arrow.target == game.classroom.anchor)
	game._on_exam_tapped()
	await process_frame
	await process_frame
	print("examen recien abierto: flecha=", game._arrow.visible, " (esperado false)")
	await create_timer(game.OPTION_HINT + 0.6).timeout
	print("sin responder: flecha recorre ", game._arrow.targets.size(), " respuestas, visible=", game._arrow.visible)
	game.queue_free()
	await process_frame
	quit()
