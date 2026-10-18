extends SceneTree
## Empezar de nuevo: dos carteles de confirmacion y la partida queda como recien instalada.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.coins = 321
	gs.owned = ["hat_bow", "furn_crib"]
	gs.jobs_done = 7
	gs.player_name = "Ana"
	gs.player_title = "f"
	gs.tips_seen = ["job_intro", "egg1"]
	gs.journal = [{"t": 1, "kind": "frase", "text": "hola", "stat": ""}]
	gs.friend_points = {"luna": 40}
	gs.save_game()
	print("antes: guardado existe=", FileAccess.file_exists(gs.SAVE_PATH), " monedas=", gs.coins)

	# el menu muestra el boton y pide confirmar dos veces
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	print("boton reiniciar visible con partida: ", menu._reset_button.visible)
	menu._ask_reset()
	await process_frame
	print("cartel 1: ", menu._notice != null)
	menu._confirm_reset()
	await process_frame
	print("cartel 2 (¿seguro?): ", menu._notice != null, " | nada borrado todavia: ", gs.coins == 321)
	menu._close_notice()
	print("cancelar no borra: monedas=", gs.coins, " pompon=", gs.pompon != null)
	menu.queue_free()
	await process_frame

	gs.save_game()
	gs.reset_game()
	print("despues: guardado=", FileAccess.file_exists(gs.SAVE_PATH), " respaldo=", FileAccess.file_exists(gs.BACKUP_PATH))
	print("  pompon=", gs.pompon, " monedas=", gs.coins, " owned=", gs.owned, " trabajos=", gs.jobs_done, " nombre='", gs.player_name, "'")
	print("  guias=", gs.tips_seen, " diario=", gs.journal.size(), " amistad=", gs.friend_points, " vecino npc=", gs.buddy)
	gs.load_game()
	print("al recargar sigue vacio: pompon=", gs.pompon, " monedas=", gs.coins)

	var menu2: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu2)
	await process_frame
	print("sin partida no aparece el boton: ", not menu2._reset_button.visible)
	menu2.queue_free()
	await process_frame
	quit()
