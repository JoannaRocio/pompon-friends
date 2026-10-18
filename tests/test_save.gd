extends SceneTree


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.coins = 123
	gs.owned = ["hat_bow", "furn_sofa", "wall_stars"]
	gs.placed = []
	gs.place_item("furn_sofa")
	gs.equipped = {"hat": "hat_bow", "wall": "wall_stars"}
	gs.tips_seen = ["egg"]
	gs.save_game()
	gs.coins = 124
	gs.save_game()  # el segundo guardado crea el respaldo
	print("archivos: save=", FileAccess.file_exists("user://save.json"), " respaldo=", FileAccess.file_exists("user://save.json.bak"),
		" tmp sobrante=", FileAccess.file_exists("user://save.json.tmp"))

	# 1) ida y vuelta
	gs.coins = 0
	gs.tips_seen = []
	gs.owned = []
	gs.load_game()
	print("recarga: monedas=", gs.coins, " items=", gs.owned.size(), " colocados=", gs.placed.size(), " guias=", gs.tips_seen, " equipado=", gs.equipped)

	# 2) guardado principal danado -> usa el respaldo
	_write("user://save.json", "{ esto no es json ::: ")
	gs.coins = 0
	gs.owned = []
	gs.load_game()
	print("principal danado, desde respaldo: monedas=", gs.coins, " (respaldo guarda 123)", " items=", gs.owned.size())

	# 3) los dos danados -> no se cae
	_write("user://save.json", "basura")
	_write("user://save.json.bak", "[1,2,3]")
	gs.coins = 55
	gs.load_game()
	print("ambos danados: sin caida, monedas se mantienen=", gs.coins)

	# 4) datos invalidos se filtran
	var bad := {
		"coins": -50, "owned": ["hat_bow", "item_fantasma", 42, "hat_bow", "furn_sofa"],
		"equipped": {"hat": "hat_bow", "shirt": "shirt_no_comprada", "furniture": "furn_sofa"},
		"placed": [{"id": "furn_sofa", "x": 5.0, "y": -3.0}, {"id": "item_fantasma", "x": 0.5, "y": 0.5}, {"id": "furn_sofa"}, "texto"],
		"pompon": null,
	}
	_write("user://save.json", JSON.stringify(bad))
	gs.load_game()
	print("filtrado: monedas=", gs.coins, " owned=", gs.owned, " equipado=", gs.equipped, " colocados=", gs.placed)

	# 5) archivo de una partida antigua (sin campos nuevos)
	_write("user://save.json", JSON.stringify({"coins": 9, "owned": ["furn_bed"], "pompon": null}))
	gs.placed = []
	gs.load_game()
	print("partida antigua: monedas=", gs.coins, " mueble colocado solo=", gs.is_placed("furn_bed"), " guias=", gs.tips_seen)

	# 6) guias de primer uso en la casa
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.owned = []  # sin compras: la guia de Decorar todavia no corresponde
	gs.placed = []
	gs.tips_seen = []
	gs.daily_gift_day = int(Time.get_unix_time_from_system()) / 86400  # sin regalo hoy
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	h._visit_time = 100.0  # como si ya llevara un rato en la casa (las guias opcionales esperan)
	await create_timer(2.6).timeout
	print("guia 1 visible: ", h._tip_panel != null, " | es un aviso chico abajo (no tapa el juego): ", h._tip_panel.anchor_top == 1.0)
	h._tip_panel.get_child(0).get_child(2).pressed.emit()
	await process_frame
	print("guias vistas: ", gs.tips_seen, " | aviso cerrado: ", h._tip_panel == null)
	await create_timer(2.6).timeout
	print("solo una guia opcional por visita: ", h._tip_panel == null)

	# se va sola a los segundos si nadie la toca
	h._optional_shown = false
	h._last_optional_tip = -100000.0
	await create_timer(2.6).timeout
	print("otra guia aparece en otra visita: ", h._tip_panel != null)
	await create_timer(h.TIP_SECONDS + 1.0).timeout
	print("desaparece sola: ", h._tip_panel == null)
	quit()
