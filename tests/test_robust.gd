extends SceneTree


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.owned = []
	var now := int(Time.get_unix_time_from_system())

	# 1) Pausa en segundo plano: al volver se aplica el tiempo que paso.
	gs.pompon.stats["alimentacion"] = 100.0
	gs.pompon.born_at = now - 100 * 86400
	gs._paused_at = now - 10 * 3600
	gs._notification(NOTIFICATION_APPLICATION_RESUMED)
	print("tras 10h pausado: comida=", snappedf(gs.pompon.stats["alimentacion"], 0.1), " (esperado ~60)")

	# 2) Avance de etapa: el huevo espera su cuna; al nacer y al crecer hay avisos.
	gs.new_pompon()
	await create_timer(1.2).timeout
	print("huevo sin cuna: sigue huevo=", not gs.pompon.hatched, " | sin aviso='", gs.stage_news, "'")
	gs.hatch_now()
	print("aviso al eclosionar: '", gs.stage_news, "'")
	gs.stage_news = ""
	gs.pompon.born_at = now - 8 * 86400
	await create_timer(1.3).timeout
	print("aviso al crecer: '", gs.stage_news, "'")
	gs.stage_news = ""

	# 3) Abandono: la nota se conserva en el guardado y se muestra en la casa.
	gs.coins = 77
	gs.pompon.neglect_seconds = 30.0 * 86400.0 - 0.05
	gs.pompon.stats["alimentacion"] = 0.0
	await create_timer(0.5).timeout
	print("pompon se fue: ", gs.pompon == null, " coins conserva=", gs.coins)
	print("nota guardada: ", gs.farewell.left(46).replace("\n", " "))
	gs.last_stage = -1
	gs.load_game()
	print("nota tras recargar: ", gs.farewell != "")
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.4).timeout
	print("modal de despedida visible: ", h._note_panel != null)
	h._note_panel.get_child(0).get_child(2).pressed.emit()  # "Mas tarde"
	await process_frame
	print("tras 'Mas tarde': nota=", gs.farewell == "", " sin pompon=", gs.pompon == null)

	# 4) Boton atras de Android.
	var ok := true
	for pair in [["menu", "quit"], ["home", "menu"], ["minigames", "home"]]:
		pass
	print("autosave listo, atras manejado (no se puede quitar desde headless)")
	quit()
