extends SceneTree
## Pantalla de misiones: tarjetas, cobrar una mision lista y cobrar un premio del pase.


func _find_buttons(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_find_buttons(c, out)


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.coins = 0
	gs._refresh_missions()
	gs.mission_progress = {"minigame": 2}
	gs.missions_claimed = []
	gs.pass_xp = 5
	gs.pass_claimed = []
	var scene: Control = load("res://scenes/missions.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	print("tarjetas=", scene._missions_box.get_child_count(), " (esperado 5) premios pase=", scene._nodes.get_child_count(), " (esperado 5)")

	# la tarjeta de minijuegos (segunda) tiene el boton de cobrar habilitado
	var buttons := []
	_find_buttons(scene._missions_box.get_child(1), buttons)
	print("boton cobrar habilitado=", not buttons[0].disabled)
	buttons[0].pressed.emit()
	await process_frame
	print("tras cobrar: monedas=", gs.coins, " (esperado 15) xp=", gs.pass_xp, " (esperado 20) cobrada=", gs.missions_claimed.has("minigame"))

	# con 20 XP se abre el primer premio del pase
	var nodes := []
	_find_buttons(scene._nodes.get_child(0), nodes)
	print("premio 1 habilitado=", not nodes[0].disabled)
	nodes[0].pressed.emit()
	await process_frame
	print("tras premio 1: monedas=", gs.coins, " (esperado 25) reclamado=", gs.pass_claimed.has(0))
	var nodes2 := []
	_find_buttons(scene._nodes.get_child(1), nodes2)
	print("premio 2 bloqueado=", nodes2[0].disabled, " (esperado true)")
	scene.queue_free()
	await process_frame
	quit()
