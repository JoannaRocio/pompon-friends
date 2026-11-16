extends SceneTree
## Carrera de profesor/a (niveles por turnos y paga 50 -> 500) y los carteles del tutorial del trabajo.


## La ficha de profesor/a (sin nombrar la clase: usa GameState y no compila en --script).
func _is_card(n: Node) -> bool:
	return n.get_script() != null and String(n.get_script().resource_path).ends_with("teacher_card.gd")


func _initialize() -> void:
	await process_frame
	var jobs: GDScript = load("res://scripts/jobs.gd")
	print("turnos para nivel 2/3/4/5/6/100: ", [jobs.shifts_for_level(2), jobs.shifts_for_level(3), jobs.shifts_for_level(4),
		jobs.shifts_for_level(5), jobs.shifts_for_level(6), jobs.shifts_for_level(100)], " (esperado [5, 10, 20, 30, 40, 980])")
	var ok := true
	for lvl in range(1, 101):
		ok = ok and jobs.career_level(jobs.shifts_for_level(lvl)) == lvl
		if lvl > 1:
			ok = ok and jobs.career_level(jobs.shifts_for_level(lvl) - 1) == lvl - 1
	print("nivel y turnos coinciden en los 100 niveles: ", ok, " | tope con 5000 turnos: ", jobs.career_level(5000))
	print("paga nivel 1/2/50/100: ", [jobs.pay_for_level(1), jobs.pay_for_level(2), jobs.pay_for_level(50), jobs.pay_for_level(100)], " (de 50 a 500)")

	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = false
	gs.player_name = "Ana"
	gs.player_title = "f"
	gs.owned = []
	gs.coins = 0
	gs.jobs_done = 4
	gs.tips_seen = []
	var before: int = gs.coins
	var res: Dictionary = gs.finish_job("addsub", 5, 5, false)
	print("turno 5: paga=", res["pay"], " (esperado 50) ascendio=", res["promoted"], " nivel ", res["career_before"], "->", res["career_after"],
		" | ahora paga ", gs.job_pay())
	gs.coins = before

	# ofertas la primera vez: sin cartel al entrar; al aplicar, el cartel con la ficha y para que son las monedas
	gs.jobs_done = 0
	var board: Control = load("res://scenes/job_board.tscn").instantiate()
	root.add_child(board)
	await process_frame
	await process_frame
	print("ofertas sin cartel al entrar: ", board._layer == null, " | sin ficha todavia: ", not _is_card(board._slot.get_child(0)))
	board._open("math")
	await process_frame
	var has_card := false
	for c in board._layer.box.get_children():
		has_card = has_card or _is_card(c)
	var says_coins := false
	for l in board._layer.find_children("*", "Label", true, false):
		says_coins = says_coins or l.text.contains("Con las monedas")
	print("cartel 2 al aplicar: ", board._layer is BigNotice, " con ficha: ", has_card, " | dice para que son las monedas: ", says_coins)
	board.queue_free()

	# fin del primer turno: cartel 3 antes del resultado
	gs.tips_seen.append("job_hired")
	var game: Control = load("res://scenes/job_game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._close_layer()
	game.questions_done = 1
	game.correct = 1
	game._finish(false)
	await process_frame
	var text := ""
	for c in game._layer.box.get_children():
		if c is Label:
			text += c.text + " / "
	print("cartel 3: ", text)
	print("queda el resultado en la fila: ", game._steps.size(), " (esperado 1)")
	game.queue_free()
	await process_frame
	quit()
