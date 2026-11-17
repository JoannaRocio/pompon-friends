extends SceneTree
## Animacion del nacimiento: al comprar la cuna, la casa muestra el huevo meneandose, rajandose y
## abriendose (sale el bebe) y recien despues pide ponerle nombre.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon("Conejo", "Hembra")
	gs.owned = []
	gs.placed = []
	gs.tips_seen = ["egg1", "job1", "shopcrib"]
	gs.daily_gift_day = int(Time.get_unix_time_from_system()) / 86400
	gs.coins = 60
	print("antes de comprar la cuna: pendiente=", gs.hatch_anim_pending)
	gs.buy("furn_crib")
	print("cuna comprada: nacio=", gs.pompon.hatched, " | animacion pendiente=", gs.hatch_anim_pending)
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.8).timeout
	# antes de nacer: el huevo golpea la cascara y hay que tocarlo
	print("esta por nacer: ", h._prehatch, " | se ve el huevo: ", h.pet.show_egg, " | flecha al huevo: ", h._arrow.target == h._egg_anchor,
		" | aviso: '", h._tip_panel.get_child(0).get_child(1).text.c_escape() if h._tip_panel != null else "", "' | sin animacion todavia: ", h._hatch_layer == null)
	for i in 3:
		h._on_pet_tapped()
		print("  toque ", i + 1, ": rajaduras=", h.pet.egg_cracks)
	await create_timer(0.9).timeout
	print("la casa muestra la animacion: ", h._hatch_layer != null, " | todavia no pide nombre: ", h._name_panel == null, " | ya no esta pendiente: ", not gs.hatch_anim_pending)
	var anim = h._hatch_layer
	await create_timer(1.0).timeout
	print("el huevo se va rajando: grietas=", anim._cracks_shown)
	await create_timer(1.6).timeout
	print("nace (se abre la cascara): ", anim._popped, " | aparece el bebe: ", anim._baby.visible)
	await create_timer(1.2).timeout
	print("al principio no se puede saltar el final: ", not anim._done)
	anim.t = 6.0   # como si hubiera pasado todo el tiempo
	await create_timer(1.2).timeout
	print("termina sola: capa cerrada=", h._hatch_layer == null)
	await create_timer(1.0).timeout
	print("primero la fiesta: confeti=", h._born_party > 0.0, " | sin cartel del nombre todavia=", h._name_panel == null)
	await create_timer(3.6).timeout
	print("despues pide el nombre: ", h._name_panel != null, " | ya no esta por nacer: ", not h._prehatch, " | se ve el bebe: ", not h.pet.show_egg)
	quit()
