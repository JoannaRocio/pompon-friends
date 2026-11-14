extends SceneTree
## Idiomas (T y locale/textos.csv): cambiar de idioma, que las pantallas de entrada (menú, bienvenida,
## edad, nombre, casa y tutorial) muestren el texto correcto y que una partida vieja sin idioma use el
## del celular.

var gs: Node


func _texts(node: Node) -> Array:
	var out := []
	for c in node.find_children("*", "", true, false):
		if c is Label or c is Button:
			if c.text != "" and not c.is_queued_for_deletion():
				out.append(c.text)
		elif c is RichTextLabel:
			out.append(c.get_parsed_text())
		elif c is Control and "text" in c and typeof(c.get("text")) == TYPE_STRING and c.get("text") != "":   # barras dibujadas (StatBar)
			out.append(c.get("text"))
	return out


func _notice(parent: Node) -> Node:
	var found: Node = null
	for c in parent.get_children():
		if c is BigNotice and not c.is_queued_for_deletion():
			found = c
	return found


## Claves sin traducir que se verian en pantalla ("menu.play", "tip.egg1"...).
func _raw_keys(texts: Array) -> Array:
	var re := RegEx.create_from_string("^(common|ui|menu|age|profile|names|welcome|home|tip|tut)\\.[A-Za-z_.0-9]+$")
	return texts.filter(func(s): return re.search(str(s)) != null)


## Textos en español del CSV que en inglés cambian: si alguno se ve tal cual en inglés, falta traducirlo.
var _spanish_only := {}


func _load_spanish_only() -> void:
	var f := FileAccess.open("res://locale/textos.csv", FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3 and row[1] != row[2]:
			_spanish_only[row[1]] = true


## Lo que se ve en inglés pero sigue en español: textos exactos del CSV o con letras del español.
func _spanish_left(texts: Array, allow: Array = []) -> Array:
	var re := RegEx.create_from_string("[áéíóúñ¿¡]")
	return texts.filter(func(s): return not s in allow and (_spanish_only.has(s) or re.search(s) != null))


## Todos los T.s("..."), T.t("...") y T.label("...") del codigo tienen su texto en inglés.
func _code_check(t: GDScript) -> void:
	var re := RegEx.create_from_string("T\\.(s|t|g|n|label)\\(\"((?:[^\"\\\\]|\\\\.)*)\"")
	var missing := []
	var count := 0
	for dir in ["res://scripts"]:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd"):
				continue
			var src := FileAccess.get_file_as_string(dir.path_join(file))
			for m in re.search_all(src):
				var kind := m.get_string(1)
				var lit := m.get_string(2).c_unescape()
				var key: String = {"s": "s:", "label": "ui."}.get(kind, "") + lit
				if kind == "g" or kind == "n" or (kind == "t" and lit.contains("%")):
					continue   # (variantes y claves armadas con % se prueban aparte)
				count += 1
				if String(TranslationServer.get_translation_object("en").get_message(key)) == "":
					missing.append("%s: %s" % [file, key])
	print("codigo: ", count, " textos con T.s/T.t/T.label | sin ingles: ", missing)


## Area 1: tienda, vestidor, catalogo y comidas.
func _area_shop(t: GDScript) -> void:
	var Catalog: GDScript = load("res://scripts/catalog.gd")
	var PomponTastes: GDScript = load("res://scripts/pompon_tastes.gd")
	var Rooms: GDScript = load("res://scripts/rooms.gd")
	var en := TranslationServer.get_translation_object("en")
	var no_item: Array = Catalog.ITEMS.filter(func(i): return String(en.get_message("item." + i["id"])) == "").map(func(i): return i["id"])
	var no_food: Array = PomponTastes.FOODS.filter(func(f): return String(en.get_message("food." + f["id"])) == "").map(func(f): return f["id"])
	print("catalogo: ", Catalog.ITEMS.size(), " objetos | sin ingles: ", no_item, " | comidas sin ingles: ", no_food, " | ej: ", Catalog.item_name("hat_bow"), ", ", PomponTastes.food_name("torta"), ", ", Rooms.room_name(1))
	var now := int(Time.get_unix_time_from_system())
	gs.reset_game()
	gs.set_language("en")
	gs.age_group = "adult"
	gs.set_profile("Ana", "f")
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.born_at = now - 3 * 86400
	gs.pompon.nickname = "Mochi"
	gs.coins = 30
	gs.daily_gift_day = Missions.today(now)
	gs.owned = ["hat_bow", "shirt_dress", "furn_sofa", "wall_stars"]
	for key in ["all", "special"]:
		var shop: Control = load("res://scenes/shop.tscn").instantiate()
		root.add_child(shop)
		await process_frame
		if key == "special":
			shop._filter = "special"
			shop._rebuild()
			await process_frame
		var st := _texts(shop)
		print("tienda (en, ", key, "): ", st.filter(func(s): return s in ["Shop", "All", "Clothes", "Furniture", "Bowls", "Special", "Yours", "Unlocks as you level up"] or s.begins_with("Level") or s.begins_with("New shop in")).slice(0, 12))
		print("  sigue en español: ", _spanish_left(st, ["Mochi"]), " | claves sueltas: ", _raw_keys(st))
		shop.queue_free()
		await process_frame
	var wd: Control = load("res://scenes/wardrobe.tscn").instantiate()
	root.add_child(wd)
	await process_frame
	var wt := _texts(wd)
	print("vestidor (en): ", wt.filter(func(s): return s in ["Closet", "Clothes", "Room", "Bowls", "Pink bow", "Pink dress"]), " | sigue en español: ", _spanish_left(wt, ["Mochi"]))
	wd.queue_free()
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.6).timeout
	h._show_food_menu()
	await process_frame
	var ft := _texts(h._food_panel) if h._food_panel != null else []
	print("comida (en): ", ft.filter(func(s): return s.begins_with("What should") or s in ["Toast", "Baby mush", "free", "New!"]).slice(0, 6), " | sigue en español: ", _spanish_left(ft, ["Mochi"]))
	h.queue_free()
	await process_frame


func _initialize() -> void:
	_load_spanish_only()
	await process_frame
	gs = root.get_node("GameState")
	var t: GDScript = load("res://scripts/t.gd")

	# ---------- el CSV: todas las claves en los dos idiomas
	var f := FileAccess.open("res://locale/textos.csv", FileAccess.READ)
	f.get_csv_line()
	var keys := []
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3 and row[0] != "":
			keys.append(row[0])
	var missing := {"es": [], "en": []}
	for lg in ["es", "en"]:
		t.apply(lg)
		for k in keys:
			if t.t(k) == k or t.t(k) == "":
				missing[lg].append(k)
	print("textos.csv: ", keys.size(), " claves | sin traducir en es: ", missing["es"], " | en en: ", missing["en"])

	# ---------- cambiar de idioma
	gs.reset_game()
	gs.set_language("en")
	print("en ingles: T.lang=", t.lang(), " | menu.play='", t.t("menu.play"), "' | ui.Comer='", t.label("Comer"), "' | sin clave queda igual: '", t.label("Sofá"), "'")
	print("  con datos: '", t.t("home.egg_of", {"species": "bunny"}), "' | plural: '", t.n("home.in_days", 1), "' / '", t.n("home.in_days", 3), "' | genero: '", t.g("menu.reset_sure", "f"), "'")
	gs.set_language("es")
	print("en español: menu.play='", t.t("menu.play"), "' | genero f/m/n: '", t.g("menu.reset_sure", "f"), "' '", t.g("menu.reset_sure", "m"), "' '", t.g("menu.reset_sure", "n"), "'")
	gs.set_language("en")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://save.json"))
	print("se guarda en la partida: language=", saved.get("language", "?"))
	gs.reset_game()
	print("empezar de nuevo conserva el idioma: ", gs.language, " | T.lang=", t.lang())

	# ---------- partida vieja sin idioma: usa el del celular
	gs.language = ""
	gs.apply_save({"coins": 5, "player_name": "Ana", "player_title": "f"})
	t.apply(gs.language)
	print("partida vieja sin idioma: language='", gs.language, "' | usa el del celular: ", t.lang() == t.device_lang(), " (celular=", t.device_lang(), ")")
	gs.apply_save({"coins": 5, "language": "marciano"})
	print("  idioma invalido se ignora: language='", gs.language, "'")

	# ---------- menú en inglés y botón de idioma
	gs.reset_game()
	gs.set_language("en")
	var menu: Control = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var mt := _texts(menu)
	print("menu (en): ", mt.filter(func(s): return s in ["Play!", "Take care of your Pompon and learn as you play", "No ads · Made with love"]), " | claves sueltas: ", _raw_keys(mt))
	menu._toggle_language()
	await process_frame
	var mt2 := _texts(menu)
	print("boton de idioma -> ", gs.language, " | menu (es): ", mt2.filter(func(s): return s in ["¡Jugar!", "Cuida a tu Pompon y aprende jugando", "Sin anuncios · Hecho con cariño"]))
	menu._toggle_language()
	await process_frame
	print("  y vuelve: ", gs.language, " | ", menu._play.text)

	# edad y nombre en inglés
	menu._on_play()
	await process_frame
	var age: Node = _notice(menu)
	var at := _texts(age)
	print("edad (en): ", at.slice(0, 3), " ... ", at[-1], " | claves sueltas: ", _raw_keys(at))
	for b in age.find_children("*", "Button", true, false):
		if b.text == "9":
			b.pressed.emit()
	await process_frame
	var dlg = menu._profile
	dlg.accepted.disconnect(menu._enter_game)
	var dt := _texts(dlg)
	print("nombre, menor de 13 (en): ", dt.filter(func(s): return s in ["What's your name?", "More names", "Pronouns", "She / her", "He / him", "Done!"]), " | claves sueltas: ", _raw_keys(dt))
	menu.queue_free()
	await process_frame
	gs.age_group = "adult"
	var dlg2: Control = load("res://scripts/profile_dialog.gd").new()
	root.add_child(dlg2)
	dlg2.setup(true)
	print("nombre, adulto (en): placeholder='", dlg2._edit.placeholder_text, "' | ", _texts(dlg2).filter(func(s): return s in ["Make up a name", "Cancel"]))
	dlg2.queue_free()

	# ---------- bienvenida en inglés
	gs.player_name = "Ana"
	gs.player_title = "f"
	var w: Control = load("res://scenes/welcome.tscn").instantiate()
	root.add_child(w)
	await process_frame
	var wt := _texts(w)
	print("bienvenida (en): ", wt.filter(func(s): return s.begins_with("Hi,") or s.begins_with("Today") or s == "Adopt a Pompon"))
	w._choose_species()
	await process_frame
	var st := _texts(w._step)
	print("  especie: ", st.filter(func(s): return s in ["Pick a kind", "Its colors will be a surprise", "Bunny", "Kitty", "Dragon", "Surprise"]))
	w._pick_species("Conejo")
	await process_frame
	var sx := _texts(w._step)
	print("  sexo: ", sx.filter(func(s): return s in ["Girl or boy?", "Girl", "Boy"]), " | claves sueltas: ", _raw_keys(wt + st + sx))
	w.queue_free()
	await process_frame

	# ---------- casa en inglés: huevo, aviso y tutorial
	var now := int(Time.get_unix_time_from_system())
	gs.reset_game()
	gs.set_language("en")
	gs.set_profile("Ana", "f")
	gs.age_group = "adult"
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = false
	gs.daily_gift_day = Missions.today(now)
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(2.2).timeout
	var ht := _texts(h)
	print("casa con huevo (en): ", ht.filter(func(s): return s in ["Your bunny egg", "Menu", "Missions", "Neighbors", "Work", "Diary", "Shop"] or s.begins_with("Your egg is here!") or s.begins_with("Crib")), " | claves sueltas: ", _raw_keys(ht))
	h.queue_free()
	await process_frame
	gs.pompon.hatched = true
	gs.pompon.born_at = now - 3600
	gs.pompon.nickname = "Mochi"
	gs.hatch_anim_pending = false
	gs.tips_seen = ["egg1", "job1", "shopcrib", "notify_ask"]
	var h2: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h2)
	await create_timer(2.0).timeout
	var tt: Array = _texts(h2._tut) if h2._tut != null else []
	var h2t := _texts(h2)
	print("casa con Pompon (en): ", h2t.filter(func(s): return s in ["Eat", "Drink", "Bath", "Cuddle", "Games", "Pompon", "Home", "Food", "Water", "Clean", "Fun", "Comfort", "Sleep", "Trust", "Social"] or s.begins_with("Mochi  (Baby)") or s.begins_with("Growth") or s.begins_with("Day 1 of 7")))
	print("  tutorial (en): ", tt.filter(func(s): return s.begins_with("Hi!") or s in ["Skip tutorial", "Got it!"]), " | claves sueltas: ", _raw_keys(h2t))
	h2.queue_free()
	await process_frame

	# ---------- lo mismo en español (no cambia nada para quien juega en español)
	gs.set_language("es")
	var h3: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h3)
	await create_timer(2.0).timeout
	var h3t := _texts(h3)
	var tt3: Array = _texts(h3._tut) if h3._tut != null else []
	print("casa con Pompon (es): ", h3t.filter(func(s): return s in ["Comer", "Caricia", "Casa", "Comida", "Sueño"] or s.begins_with("Mochi  (Bebé)") or s.begins_with("Día 1 de 7")), " | tutorial: ", tt3.filter(func(s): return s.begins_with("¡Hola!") or s == "Saltar tutorial"))
	h3.queue_free()

	gs.set_language("en")
	await _code_check(t)
	await _area_shop(t)

	gs.language = ""
	gs.reset_game()
	t.apply("")
	print("FIN test_locale")
	quit()
