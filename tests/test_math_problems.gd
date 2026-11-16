extends SceneTree
## Cuentas y aprendizaje: cada nivel genera lo que dice, el juego decide cuando se domina un nivel
## (rapido y bien, varias veces; o con constancia), repasa lo fallado y los premios son fijos.


func _digit_units(x: int) -> int:
	return x % 10


func _valid(track: String, level: int, p: Dictionary) -> bool:
	var a: int = p["a"]
	var b: int = p["b"]
	var op: String = p["op"]
	var ans: int = p["answer"]
	var expected := 0
	match op:
		"add": expected = a + b
		"sub": expected = a - b
		"mul": expected = a * b
		"div": expected = a / b if b != 0 and a % b == 0 else -999999
	if ans != expected or ans < 0 or p["options"].size() != 3 or not p["options"].has(ans):
		return false
	var seen := {}
	for o in p["options"]:
		if o < 0 or seen.has(o):
			return false
		seen[o] = true
	if MathProblems.explanation(p).is_empty():
		return false
	if track == "addsub":
		match level:
			1: return op == "add" and a <= 5 and b <= 5
			2: return op == "add" and a + b <= 10
			3: return (op == "add" and a + b <= 10) or (op == "sub" and a <= 10 and b < a)
			4: return (op == "add" and a < 10 and b < 10 and a + b >= 11) or (op == "sub" and a <= 10 and b < a)
			5: return (op == "add" and a + b <= 20) or (op == "sub" and a <= 20 and b <= 9)
			6:
				if op == "add":
					return _digit_units(a) + b <= 9 and ans <= 99
				return _digit_units(a) >= b and ans >= 10
			7:
				if op == "add":
					return _digit_units(a) + b >= 10 and ans <= 99
				return _digit_units(a) < b and ans >= 10
			8:
				if op == "add":
					return _digit_units(a) + _digit_units(b) <= 9 and a / 10 + b / 10 <= 9 and b >= 10
				return _digit_units(a) >= _digit_units(b) and a / 10 > b / 10 and b >= 10
			9:
				if op == "add":
					return _digit_units(a) + _digit_units(b) >= 10 and b >= 10
				return _digit_units(a) < _digit_units(b) and a / 10 > b / 10 and b >= 10
			10: return a >= 100 and b >= 100 and ans >= 0 and (ans <= 999 if op == "add" else ans >= 50)
	elif track == "mul":
		var sets := {1: [2], 2: [5, 10], 3: [3], 4: [4], 5: [2, 3, 4, 5, 10], 6: [6, 9], 7: [7, 8], 8: [2, 3, 4, 5, 6, 7, 8, 9, 10]}
		if level <= 8:
			return op == "mul" and (a in sets[level] or b in sets[level]) and a <= 10 and b <= 10
		if level == 9:
			return op == "mul" and a >= 11 and a <= 19 and b >= 2 and b <= 5
		return op == "mul" and a >= 12 and a <= 40 and b >= 2 and b <= 9
	else:
		var sets2 := {1: [2], 2: [5, 10], 3: [3], 4: [4], 5: [2, 3, 4, 5, 10], 6: [6, 9], 7: [7, 8], 8: [2, 3, 4, 5, 6, 7, 8, 9, 10]}
		if level <= 8:
			return op == "div" and b in sets2[level] and ans <= 10
		if level == 9:
			return op == "div" and b >= 2 and b <= 5 and ans >= 11 and ans <= 19
		return op == "div" and b >= 2 and b <= 9 and ans >= 12 and ans <= 30
	return false


func _hist(count_good: int, count_slow: int = 0, count_wrong: int = 0, fast_t := 1.0, slow_t := 99.0) -> Array:
	var h := []
	for i in count_wrong:
		h.append({"c": false, "t": 3.0})
	for i in count_slow:
		h.append({"c": true, "t": slow_t})
	for i in count_good:
		h.append({"c": true, "t": fast_t})
	return h


func _shift(gs: Node, camino: String, rng: RandomNumberGenerator, p_correct: float, time_factor: float) -> Dictionary:
	var level: int = gs.math_level(camino)
	var fast := MathProblems.fast_seconds(camino, level)
	var recent := []
	var right := 0
	for i in MathProblems.QUESTIONS_PER_SHIFT:
		var prob := MathProblems.pick_problem(camino, level, rng, gs.weak_facts(camino), recent)
		recent.append(prob["key"])
		while recent.size() > 4:
			recent.pop_front()
		var ok := rng.randf() < p_correct
		gs.record_answer(camino, prob, ok, maxf(0.7, fast * time_factor * rng.randf_range(0.8, 1.2)))
		if ok:
			right += 1
	return gs.finish_job(camino, right, MathProblems.QUESTIONS_PER_SHIFT)


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2468

	# ---------- 1) las cuentas de cada nivel son correctas y del tipo pedido
	var bad := 0
	var total := 0
	for track in MathProblems.TRACKS:
		for level in range(1, MathProblems.MAX_LEVEL + 1):
			for i in 300:
				var p := MathProblems.generate(track, level, rng)
				total += 1
				if not _valid(track, level, p):
					bad += 1
					if bad < 5:
						print("MAL: ", track, " nivel ", level, " ", p)
	print("cuentas generadas: ", total, " | incorrectas o fuera de nivel: ", bad)
	var texts_ok := true
	for track in MathProblems.TRACKS:
		texts_ok = texts_ok and MathProblems.LEVEL_NAMES[track].size() == 10 and MathProblems.FAST_SECONDS[track].size() == 10
		for level in range(1, 11):
			var lesson := MathProblems.lesson(track, level)
			if lesson["lines"].is_empty() or MathProblems.level_name(track, level) == "":
				texts_ok = false
	print("10 niveles por camino, con nombre, tiempo y leccion: ", texts_ok)
	print("el nivel 1 de sumas es muy sencillo (todo <= 10): ", MathProblems.generate("addsub", 1, rng)["answer"] <= 10)

	# ---------- 2) explicaciones por partes
	for sample in [{"op": "add", "a": 8, "b": 5, "answer": 13}, {"op": "sub", "a": 14, "b": 6, "answer": 8},
			{"op": "add", "a": 47, "b": 38, "answer": 85}, {"op": "sub", "a": 82, "b": 37, "answer": 45},
			{"op": "add", "a": 234, "b": 156, "answer": 390}, {"op": "mul", "a": 12, "b": 3, "answer": 36},
			{"op": "div", "a": 12, "b": 3, "answer": 4}]:
		print("  ", MathProblems.explanation(sample).replace("\n", " | "))

	# ---------- 3) decision de dominio
	var ev := func(level: int, hist: Array) -> String:
		var r := MathProblems.evaluate("mul", level, hist)
		return "%s(+%d)" % [r["action"], r["levels"]]
	print("sin historial: ", ev.call(2, []))
	print("un solo turno perfecto y rapido (5): ", ev.call(2, _hist(5)), " (debe ser none)")
	print("8 perfectas y rapidas (mitad del tiempo = 2 s no: usa ", MathProblems.fast_seconds("mul", 2), " s): ", ev.call(2, _hist(8, 0, 0, 3.0)), " (up)")
	print("8 perfectas y rapidisimas: ", ev.call(2, _hist(8, 0, 0, 1.0)), " (jump +2)")
	print("rapidisimas en el nivel 9: ", ev.call(9, _hist(8, 0, 0, 1.0)), " (+1 por el tope)")
	print("rapidisimas en el nivel 10: ", ev.call(10, _hist(8, 0, 0, 1.0)), " (complete)")
	print("8 correctas pero lentas: ", ev.call(2, _hist(0, 8)), " (none)")
	print("15 correctas lentas (constancia): ", ev.call(2, _hist(0, 15)), " (up)")
	print("14 correctas lentas: ", ev.call(2, _hist(0, 14)), " (none)")
	print("7 de 8 y rapidas (un error): ", ev.call(2, _hist(7, 0, 1, 1.0)), " (none)")
	print("el error viejo no estorba si las ultimas 8 son perfectas: ", ev.call(2, _hist(0, 0, 3) + _hist(8, 0, 0, 3.0)), " (up)")
	print("4 de 8 en nivel 3: ", ev.call(3, _hist(4, 0, 4)), " (down)")
	print("4 de 8 en nivel 1: ", ev.call(1, _hist(4, 0, 4)), " (none: no baja del 1)")
	print("5 de 8: ", ev.call(3, _hist(5, 0, 3)), " (none)")
	print("racha buena (bien y rapido seguidas): ", MathProblems.good_streak("mul", 2, _hist(0, 2) + _hist(3, 0, 0, 1.0)), " (3)")

	# ---------- 4) jugadores simulados (premios fijos, progreso real)
	var coins_ok := true
	var profiles := {
		"experto (perfecto y rapidisimo)": [1.0, 0.25],
		"fluido (casi perfecto y rapido)": [0.97, 0.7],
		"adulto preciso pero lento": [1.0, 1.7],
		"con dificultades": [0.3, 1.5],
		"irregular": [0.75, 1.0],
	}
	for name in profiles:
		gs.math_progress = {}
		gs.math_weak = {}
		gs.coins = 0
		if name == "con dificultades":
			gs.math_state("mul")["level"] = 4
		var prof: Array = profiles[name]
		var levels := [gs.math_level("mul")]
		var level_ups := 0
		var downs := 0
		for s in 8:
			gs.paid_shifts_day = -1   # (cada turno como en un dia distinto: aca se prueba la paga, no el tope diario)
			var before: int = gs.coins
			var pay: int = gs.job_pay()   # depende del nivel de profesor/a al empezar el turno
			var res := _shift(gs, "mul", rng, prof[0], prof[1])
			var delta: int = gs.coins - before
			if res["action"] in ["up", "jump", "complete"]:
				level_ups += 1
				coins_ok = coins_ok and delta == pay + MathProblems.LEVEL_UP_BONUS
			else:
				coins_ok = coins_ok and delta == pay
			if res["action"] == "down":
				downs += 1
			levels.append(gs.math_level("mul"))
		print("  ", name, " -> niveles por turno ", levels, " | avances=", level_ups, " bajadas=", downs, " | monedas=", gs.coins)
	print("la paga sale del nivel de profesor/a (no de la nota) y el premio de nivel es fijo (", MathProblems.LEVEL_UP_BONUS, "): ", coins_ok)

	# el avance solo ocurre con varios turnos, nunca con uno solo
	gs.math_progress = {}
	var first := _shift(gs, "addsub", rng, 1.0, 0.2)
	print("primer turno perfecto y rapidisimo: accion=", first["action"], " (none: la evidencia necesita mas de un turno)")
	var second := _shift(gs, "addsub", rng, 1.0, 0.2)
	print("segundo turno igual: accion=", second["action"], " nivel ", second["level_before"], " -> ", second["level_after"])

	# ---------- 5) repaso de lo fallado
	gs.math_weak = {}
	gs.math_progress = {}
	var fact := MathProblems.build_problem("mul", 3, "mul", 7, 8, rng)
	gs.record_answer("mul", fact, false, 5.0)
	print("cuenta fallada guardada para repasar: ", gs.weak_facts("mul").size(), " | clave ", fact["key"])
	var reviews := 0
	for i in 400:
		var pick := MathProblems.pick_problem("mul", 3, rng, gs.weak_facts("mul"), [])
		if pick.get("review", false) and pick["key"] == fact["key"]:
			reviews += 1
	print("de 400 cuentas, repasos de la fallada: ", reviews, " (~30%: ", reviews > 80 and reviews < 160, ")")
	var avoided := true
	for i in 200:
		var pick2 := MathProblems.pick_problem("mul", 3, rng, gs.weak_facts("mul"), [fact["key"]])
		if pick2.get("review", false):
			avoided = false
	print("no repite la misma enseguida (si es reciente): ", avoided)
	gs.record_answer("mul", fact, true, 3.0)
	print("1 acierto: sigue en repaso=", gs.weak_facts("mul").size() == 1)
	gs.record_answer("mul", fact, true, 3.0)
	print("2 aciertos seguidos: aprendida, sale del repaso=", gs.weak_facts("mul").is_empty())
	var swapped := MathProblems.build_problem("mul", 3, "mul", 8, 7, rng)
	print("7x8 y 8x7 son la misma cuenta: ", swapped["key"] == fact["key"])

	# ---------- 6) se guarda y se sanea
	gs.math_progress = {}
	gs.math_weak = {}
	gs.math_state("div")["level"] = 6
	gs.math_state("div")["history"] = _hist(5, 2, 1, 2.0)
	gs.math_state("div")["lessons"] = [1, 2]
	gs.math_weak["div"] = [{"op": "div", "a": 56, "b": 7, "streak": 1}]
	gs.save_game()
	gs.math_progress = {}
	gs.math_weak = {}
	gs.load_game()
	print("progreso recargado: nivel ", gs.math_level("div"), " | historial=", gs.math_state("div")["history"].size(), " | lecciones vistas=", gs.math_state("div")["lessons"], " | repaso=", gs.weak_facts("div").size())
	var f := FileAccess.open("user://save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"coins": 5, "math_progress": {"mul": {"level": 99, "history": [{"c": true}, "x", {"c": 1, "t": 2}], "lessons": ["3"]}, "xx": 1}, "math_weak": {"mul": [{"op": "pow", "a": 1, "b": 2}, {"op": "mul", "a": 3, "b": 4}]}, "pompon": null}))
	f.close()
	gs.load_game()
	print("datos danados: nivel acotado=", gs.math_level("mul"), " | historial valido=", gs.math_state("mul")["history"].size(), " | repasos validos=", gs.weak_facts("mul").size())
	quit()
