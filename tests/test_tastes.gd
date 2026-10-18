extends SceneTree
## Gustos y personalidad que el Pompon aprende (color, comida, juego, habitacion, rasgos).


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var now := int(Time.get_unix_time_from_system())

	# --- familias de color
	var fam := {"ff8fb1": "rosa", "5b8def": "azul", "ffd33d": "amarillo", "6bbf7a": "verde", "d2b8f0": "lila", "8ecae6": "celeste", "ff9b54": "naranja", "222222": "", "f6f6f6": ""}
	var bad := []
	for hex in fam:
		var got := PomponTastes.color_family(Color.html(hex))
		if got != fam[hex]:
			bad.append("%s=%s (esperado %s)" % [hex, got, fam[hex]])
	print("familias de color: ", "todas bien" if bad.is_empty() else bad)

	# --- cada Pompon nace con su propia inclinacion
	var a := Pompon.generate("Conejo", "Hembra")
	var b := Pompon.generate("Conejo", "Hembra")
	a.id = "#POMPON-0001"
	b.id = "#POMPON-0002"
	a.tastes = {}
	b.tastes = {}
	PomponTastes.ensure(a)
	PomponTastes.ensure(b)
	print("gustos de nacimiento distintos: ", a.tastes["innate_food"] != b.tastes["innate_food"] or a.tastes["innate_color"] != b.tastes["innate_color"])
	var a2 := Pompon.generate("Conejo", "Hembra")
	a2.id = "#POMPON-0001"
	a2.tastes = {}
	PomponTastes.ensure(a2)
	print("misma ID, mismos gustos: ", a2.tastes["innate_food"] == a.tastes["innate_food"])

	# --- comida nueva: al principio duda, de a poco la ama (y bebe aprende mas rapido que adulto)
	var baby := Pompon.generate("Conejo", "Hembra")
	baby.hatched = true
	baby.born_at = now - 86400
	baby.tastes = {}
	PomponTastes.ensure(baby)
	baby.tastes["innate_food"]["manzana"] = 0
	var first := PomponTastes.eat(baby, "manzana", now)
	print("1ra vez: duda=", first["force"], " mult=", first["mult"], " corazones=", first["hearts"], " | '", first["text"], "'")
	var hearts_by_time := [first["hearts"]]
	for i in 7:
		hearts_by_time.append(PomponTastes.eat(baby, "manzana", now)["hearts"])
	print("corazones de a poco (bebe): ", hearts_by_time)
	print("favorita: ", PomponTastes.favorite_food(baby))
	var adult := Pompon.generate("Conejo", "Macho")
	adult.hatched = true
	adult.born_at = now - 80 * 86400
	adult.tastes = {}
	PomponTastes.ensure(adult)
	adult.tastes["innate_food"]["manzana"] = 0
	var adult_hearts := []
	for i in 8:
		adult_hearts.append(PomponTastes.eat(adult, "manzana", now)["hearts"])
	print("corazones de a poco (adulto, aprende mas lento): ", adult_hearts)
	print("bebe aprende mas rapido que el adulto: ", hearts_by_time[-1] > adult_hearts[-1])
	# lo que le cae mal cuesta mas
	var picky := Pompon.generate("Felino", "Hembra")
	picky.hatched = true
	picky.born_at = now - 86400
	picky.tastes = {}
	PomponTastes.ensure(picky)
	picky.tastes["innate_food"]["pizza"] = -1
	picky.tastes["innate_food"]["helado"] = 1
	for i in 4:
		PomponTastes.eat(picky, "pizza", now)
		PomponTastes.eat(picky, "helado", now)
	print("le gusta mas lo que le cae bien: pizza=", PomponTastes.food_hearts(picky, "pizza"), " helado=", PomponTastes.food_hearts(picky, "helado"))

	# --- anuncios de favoritos (color por compras, comida por habito)
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.born_at = now - 86400
	gs.pompon.nickname = "Mochi"
	gs.pending_thoughts = []
	gs.coins = 100000
	gs.owned = []
	gs.placed = []
	for id in ["hat_beanie", "hat_bow", "shirt_dress", "furn_beanbag", "deco_balloons"]:   # todo rosa
		gs.buy(id)
	var color_news: Array = gs.pending_thoughts.filter(func(e): return e["key"] == "fav:color")
	print("color favorito tras comprar cosas rosas: ", PomponTastes.favorite_color(gs.pompon), " | anuncio: ", color_news.size(), " ", color_news[0]["text"] if not color_news.is_empty() else "-")
	for i in 8:
		gs.pompon.tastes["innate_food"]["banana"] = 0
		PomponTastes.eat(gs.pompon, "banana", now)
	gs._taste_check()
	var food_news: Array = gs.pending_thoughts.filter(func(e): return e["key"] == "fav:food")
	print("comida favorita anunciada: ", food_news.size(), " ", food_news[0]["text"] if not food_news.is_empty() else "-")
	var n: int = gs.pending_thoughts.size()
	gs._taste_check()
	print("no se anuncia dos veces lo mismo: ", gs.pending_thoughts.size() == n)

	# --- juegos y habitaciones
	for i in 4:
		gs.reward_minigame(1, "simon")
	print("juego favorito: ", PomponTastes.favorite_game(gs.pompon))
	PomponTastes.add_room_time(gs.pompon, 2, 900.0)
	PomponTastes.add_room_time(gs.pompon, 0, 100.0)
	print("habitacion favorita: ", PomponTastes.favorite_room(gs.pompon), " (esperado 2)")

	# --- personalidad: de niño se moldea, de grande casi no
	var kid := Pompon.generate("Raton", "Macho")
	kid.hatched = true
	kid.born_at = now - 5 * 86400
	kid.personality = "Timido"
	kid.tastes = {}
	PomponTastes.ensure(kid)
	for i in 30:
		PomponTastes.bump(kid, "Curioso", 2.0, now)
	var changed := PomponTastes.check_personality(kid, now)
	print("bebe se vuelve curioso con tanta exploracion: ", kid.personality, " | ", changed.get("text", "-"))
	var old := Pompon.generate("Raton", "Macho")
	old.hatched = true
	old.born_at = now - 80 * 86400
	old.personality = "Timido"
	old.tastes = {}
	PomponTastes.ensure(old)
	for i in 30:
		PomponTastes.bump(old, "Curioso", 2.0, now)
	print("el adulto ya no cambia: ", old.personality, " ", PomponTastes.check_personality(old, now).is_empty())

	# --- habilidades del Pompon (no del cuidador)
	var sk := Pompon.generate("Conejo", "Hembra")
	sk.hatched = true
	sk.born_at = now - 86400
	print("habilidades: ", PomponSkills.ORDER, " | todas en nivel 0: ", PomponSkills.ORDER.all(func(k): return PomponSkills.level(sk, k) == 0))
	var ups := 0
	for i in 3:
		var news := PomponSkills.on_game(sk, "math", 1.0)
		ups += news.size()
	print("3 juegos de matematicas: matematicas nivel ", PomponSkills.level(sk, "matematicas"), " xp=", snappedf(PomponSkills.xp(sk, "matematicas"), 0.1), " | avisos de nivel=", ups, " | logica=", PomponSkills.level(sk, "logica"))
	PomponSkills.on_game(sk, "simon", 1.0)
	print("memoria entrena musica (", snappedf(PomponSkills.xp(sk, "musica"), 0.1), ") y un poco de logica (", snappedf(PomponSkills.xp(sk, "logica"), 0.1), ")")
	var bad_score := Pompon.generate("Conejo", "Hembra")
	bad_score.hatched = true
	PomponSkills.on_game(bad_score, "pattern", 0.0)
	var good_score := Pompon.generate("Conejo", "Hembra")
	good_score.hatched = true
	PomponSkills.on_game(good_score, "pattern", 1.0)
	print("jugar bien da mas experiencia que jugar mal: ", PomponSkills.xp(good_score, "logica") > PomponSkills.xp(bad_score, "logica") and PomponSkills.xp(bad_score, "logica") > 0.0)
	var piano_news := PomponSkills.on_buy(sk, "furn_piano")
	print("comprar el piano suma musica: xp=", snappedf(PomponSkills.xp(sk, "musica"), 0.1), " | objeto sin habilidad no suma: ", PomponSkills.on_buy(sk, "furn_sofa").is_empty())
	var lv_news := PomponSkills.add_xp(sk, "fisico", 6.0)
	print("subir de nivel avisa: ", lv_news.get("text", "-"))
	PomponSkills.add_xp(sk, "creatividad", 999.0)
	print("tope en nivel ", PomponSkills.MAX_LEVEL, ": ", PomponSkills.level(sk, "creatividad"), " progreso=", PomponSkills.progress(sk, "creatividad"))
	print("practica: ", PomponSkills.practice_text("furn_piano"), " | ", PomponSkills.practice_text("toy_blocks"), " | solo entrenan: ", PomponSkills.trainers(["furn_sofa", "furn_piano", "toy_robot"]))
	var egg_skill := Pompon.generate("Felino", "Macho")
	print("el huevo no entrena: ", PomponSkills.add_xp(egg_skill, "fisico", 50.0).is_empty() and PomponSkills.xp(egg_skill, "fisico") == 0.0)
	# lo ganado en el juego llega a las habilidades del Pompon actual
	gs.pending_thoughts = []
	gs.buy("furn_wheel")
	for i in 3:
		gs.reward_minigame(6, "pattern", 1.0)
	print("en el juego: logica nivel ", PomponSkills.level(gs.pompon, "logica"), " fisico xp=", snappedf(PomponSkills.xp(gs.pompon, "fisico"), 0.1), " | avisos pendientes=", gs.pending_thoughts.filter(func(e): return str(e["key"]).begins_with("skill:")).size())
	# el trabajo es del cuidador: el Pompon no gana habilidades ni dice que trabajo
	var before: float = PomponSkills.ORDER.map(func(k): return PomponSkills.xp(gs.pompon, k)).reduce(func(a, b): return a + b)
	gs.finish_job("suma_resta", 3, 5)
	var after: float = PomponSkills.ORDER.map(func(k): return PomponSkills.xp(gs.pompon, k)).reduce(func(a, b): return a + b)
	print("trabajar no cambia las habilidades del Pompon: ", is_equal_approx(before, after))
	var texts := []
	for ev in ["worked"]:
		for i in 20:
			texts.append(PomponThoughts.reaction(ev, gs.pompon, {"now": now, "hour": 12.0, "room": 0}, RandomNumberGenerator.new())["text"])
	print("reacciones al trabajo (del cuidador): ", texts.filter(func(t): return t.contains("contigo")).is_empty(), " | ej: ", texts[0])

	# --- guardado
	gs.save_game()
	var traits_before: Dictionary = gs.pompon.tastes["traits"].duplicate()
	gs.pompon = null
	gs.load_game()
	print("tras recargar: color=", PomponTastes.favorite_color(gs.pompon), " comida=", PomponTastes.favorite_food(gs.pompon), " juego=", PomponTastes.favorite_game(gs.pompon), " cuarto=", PomponTastes.favorite_room(gs.pompon))
	print("rasgos conservados: ", gs.pompon.tastes["traits"].keys().all(func(k): return absf(float(gs.pompon.tastes["traits"][k]) - float(traits_before[k])) < 0.01))
	# partida vieja sin gustos
	var d: Dictionary = gs.pompon.to_dict()
	d.erase("tastes")
	var legacy := Pompon.from_dict(d)
	print("partida vieja: gustos creados=", legacy.tastes.has("traits"))
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string("{}")
	f.close()
	quit()
