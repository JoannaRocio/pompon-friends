extends SceneTree
## Recorrido del principio del juego: elegir especie y sexo, huevo que espera su cuna,
## tutorial para ninos (trabajo -> tienda -> cuna), nacimiento y nombre.


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	print("monedas al empezar: ", gs.coins, " (deben ser 0)")

	# --- genetica: especie y sexo elegidos; el huevo no nace solo
	var ok := true
	for sp in Pompon.SPECIES:
		for sx in Pompon.SEX:
			var p := Pompon.generate(sp, sx)
			if p.species != sp or p.sex != sx or p.hatched:
				ok = false
	print("especie y sexo elegidos se respetan (7 x 2): ", ok)
	print("sexo invalido -> al azar valido: ", Pompon.generate("Ave", "X").sex in Pompon.SEX)
	var egg := Pompon.generate("Felino", "Hembra")
	var t0 := int(Time.get_unix_time_from_system())
	egg.born_at = t0 - 40 * 86400  # aunque pase mucho tiempo, sigue siendo huevo
	var before := egg.stats.duplicate()
	var left := egg.advance(40.0 * 86400.0)
	print("huevo tras 40 dias: etapa=", egg.stage_name(t0), " se fue=", left, " stats iguales=", egg.stats == before)
	var old := Pompon.from_dict({"species": "Ave", "sex": "Macho", "stats": {}})
	print("partida vieja (sin 'hatched') ya habia nacido: ", old.hatched)
	var again := Pompon.from_dict(egg.to_dict())
	print("el huevo se guarda como huevo: ", not again.hatched)

	# --- casa sin Pompon: selector con especie y sexo
	gs.pompon = null
	gs.owned = []
	gs.placed = []
	gs.tips_seen = []
	gs.daily_gift_day = 0
	gs.farewell = ""
	gs.coins = 0
	gs.jobs_done = 0
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await _frames(3)
	print("casa sin Pompon: boton='", h.hatch_button.text, "' visible=", h.hatch_button.visible)

	# --- bienvenida: saluda por nombre, especie en sombras, sexo y cigüena
	gs.player_name = "Ana"
	gs.player_title = "f"
	gs.age_group = "adult"   # (partida nueva: la edad ya se pregunto en el menu)
	var w: Control = load("res://scenes/welcome.tscn").instantiate()
	root.add_child(w)
	await _frames(3)
	var greeting := ""
	for rt in w.find_children("*", "RichTextLabel", true, false):
		greeting += rt.text
	var wbuttons := []
	for b in w.find_children("*", "Button", true, false):
		wbuttons.append(b.text)
	var wtexts := []
	for l in w.find_children("*", "Label", true, false):
		wtexts.append(l.text)
	print("bienvenida: saluda a Ana=", greeting.contains("Ana"), " | botones=", wbuttons, " | dice primer Pompon=", wtexts.any(func(x): return x.contains("primer Pompon")))
	w._choose_species()
	await _frames(3)
	var cards: Array = []
	for b in w._step.find_children("*", "Button", true, false):
		if b.custom_minimum_size.y > 200.0:
			cards.append(b)
	var sil_count := 0
	for v in w._step.find_children("*", "Control", true, false):
		if v is PomponView and v.material != null:
			sil_count += 1
	print("especies: tarjetas=", cards.size(), " (7 + sorpresa) | siluetas planas (sin revelar diseno)=", sil_count)
	w._pick_species("Conejo")
	await _frames(3)
	var sex_texts := []
	for l in w._step.find_children("*", "Label", true, false):
		sex_texts.append(l.text)
	print("sexo: ", sex_texts)
	w._pick_sex("Macho")
	await _frames(3)
	w._t = 5.5
	await create_timer(1.2).timeout
	print("cigüena: huevo en el nido=", w._egg_view.scale.x > 0.9, " | boton ir a casa activo=", not w._go_button.disabled, " | titulo=", w._caption.text)
	w.queue_free()
	await _frames(2)
	var pm: Pompon = gs.pompon
	print("Pompon creado: ", pm.species, " ", pm.sex, " | huevo=", not pm.hatched)

	# --- regalo + tutorial de ninos
	await create_timer(0.5).timeout
	print("regalo del dia: espera a que nazca=", h._gift_panel == null)
	await create_timer(2.4).timeout
	var tip1: String = h._tip_panel.get_child(0).get_child(1).text
	print("guia 1: ", tip1)
	print("  explica la cuna=", tip1.contains("cuna"), " | no manda a Decorar=", not tip1.contains("Decorar"))
	h._tip_panel.get_child(0).get_child(2).pressed.emit()
	await create_timer(1.6).timeout
	var tip2: String = h._tip_panel.get_child(0).get_child(1).text
	print("guia 2: ", tip2)
	print("  cuenta que cuesta monedas=", tip2.contains("monedas"), " manda a Trabajo=", tip2.contains("Trabajo"), " corto=", tip2.length() < 60)
	print("  boton Trabajo late=", h._pulses.has(h._job_button), " | Tienda no late=", not h._pulses.has(h._shop_button))
	h._tip_panel.get_child(0).get_child(2).pressed.emit()
	await create_timer(1.6).timeout
	print("sin mas guias mientras no alcance para la cuna: ", h._tip_panel == null)
	print("flecha guia: visible=", h._arrow.visible, " | apunta a Trabajo=", h._arrow.target == h._job_button)
	print("fila de cuidados oculta en el huevo: ", not h._dock._tab_buttons[0].is_visible_in_tree(), " | titulo: ", h.title.text)
	print("detalle: ", h.details.text.replace("\n", " | "))
	h._on_pet_tapped()
	print("tocar el huevo no lo hace nacer: ", not gs.pompon.hatched, " | dice: ", h._speech.text)

	# --- tienda: la cuna va primera
	var shop := Catalog.daily_shop(int(Time.get_unix_time_from_system()), pm.species, gs.owned, ["furn_crib"])
	print("tienda: primer item = ", shop[0]["id"], " (", shop[0]["name"], ") | total=", shop.size(), " | mueble de la especie incluido=", shop.any(func(i): return i.get("species", "") == "Conejo"))
	print("comprar sin monedas: ", gs.buy("furn_crib"), " (debe ser false) | sigue huevo=", not gs.pompon.hatched)

	# --- ya alcanza: guia de ir a la Tienda
	gs.coins = 55
	await create_timer(1.8).timeout
	var tip3: String = h._tip_panel.get_child(0).get_child(1).text
	print("guia 3 (alcanza): ", tip3)
	print("  Tienda late=", h._pulses.has(h._shop_button), " | Trabajo ya no late=", not h._pulses.has(h._job_button))
	h._tip_panel.get_child(0).get_child(2).pressed.emit()
	await process_frame

	# --- comprar la cuna: nace
	var bought: bool = gs.buy("furn_crib")
	print("compra de la cuna: ", bought, " | monedas=", gs.coins, " | nacio=", gs.pompon.hatched, " | cuna colocada=", gs.is_placed("furn_crib"))
	print("aviso de nacimiento: ", gs.stage_news)
	await create_timer(1.0).timeout
	print("antes de nacer golpea la cascara: ", h._prehatch)
	for i in 3:
		h._on_pet_tapped()   # cada toque lo raja un poco mas
	await create_timer(0.9).timeout
	print("antes: animacion del nacimiento=", h._hatch_layer != null, " | todavia sin pedir nombre=", h._name_panel == null)
	h._hatch_layer.t = 6.0  # se salta al final de la animacion
	await create_timer(2.6).timeout
	print("pide nombre: ", h._name_panel != null, " | cuidados visibles=", h._dock._tab_buttons[0].is_visible_in_tree())
	var nbox: Node = h._name_panel.get_child(0)
	var edit: LineEdit = nbox.get_child(2)
	edit.text = "Mochi"
	nbox.get_child(3).get_child(1).pressed.emit()
	await process_frame
	print("nombre: ", gs.pompon.nickname, " | titulo: ", h.title.text)

	# --- migracion: tiene la cuna y sigue como huevo -> nace al cargar
	gs.pompon.hatched = false
	gs.pompon.born_at = int(Time.get_unix_time_from_system())
	gs.save_game()
	gs.pompon = null
	gs.load_game()
	print("al cargar con cuna y huevo: nacio=", gs.pompon.hatched)

	# --- vecinos: no se visitan siendo huevo
	var egg2 := Pompon.generate("Ave", "Hembra")
	gs.pompon = egg2
	print("visitar vecino siendo huevo: ", gs.friend_action("luna", "pet")["msg"])
	quit()
