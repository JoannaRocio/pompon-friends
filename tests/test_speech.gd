extends SceneTree


func _initialize() -> void:
	var now := int(Time.get_unix_time_from_system())
	var p := Pompon.generate()
	print("huevo: ", PomponSpeech.line(p, now))
	p.hatched = true  # nace: a partir de aqui se prueban las otras etapas
	p.born_at = now - 3 * 86400  # bebe
	print("bebe feliz: ", PomponSpeech.line(p, now, 0), " | bebe con hambre: ", _with(p, "alimentacion", 10.0, now))
	p.stats["alimentacion"] = 100.0
	p.born_at = now - 30 * 86400  # nino
	print("nino con sed: ", _with(p, "hidratacion", 5.0, now))
	p.stats["hidratacion"] = 100.0
	p.stats["inteligencia"] = 0.0
	print("nino normal (", p.personality, "): ", PomponSpeech.line(p, now, 0))
	p.stats["inteligencia"] = 8.0
	var seen := {}
	for i in 8:
		seen[PomponSpeech.line(p, now, i)] = true
	print("nino listo, frases distintas: ", seen.size())

	var ok := true
	for sp in Pompon.SPECIES:
		var req := Catalog.required_furniture(sp)
		for d in 60:
			var shop := Catalog.daily_shop(now + d * 86400, sp, [])
			if shop.size() != Catalog.SHOP_SIZE or not shop.has(req):
				ok = false
			var ids := shop.map(func(x): return x["id"])
			for id in ids:
				if ids.count(id) != 1:
					ok = false
		if not Catalog.daily_shop(now, sp, [req["id"]]).size() == Catalog.SHOP_SIZE:
			ok = false
	print("tienda siempre trae el mueble clave y 10 sin repetir: ", ok)

	var gs := root.get_node("GameState")
	gs.new_pompon()
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await process_frame
	await process_frame
	print("home ok; habla: '", h._speech.text, "'")
	quit()


func _with(p: Pompon, stat: String, v: float, now: int) -> String:
	var old: float = p.stats[stat]
	p.stats[stat] = v
	var s := PomponSpeech.line(p, now, 0)
	p.stats[stat] = old
	return s

