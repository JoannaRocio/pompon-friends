class_name MathProblems
extends RefCounted
## Matematicas del trabajo en el periodico.
##
## Tres caminos (sumas y restas, multiplicaciones, divisiones) de 10 niveles cada uno. El
## primer nivel es muy sencillo y cada paso agrega una sola idea nueva. El juego decide solo
## cuando alguien domina un nivel: mira las ultimas respuestas (aciertos y rapidez) a lo largo
## de varios turnos. Las cuentas falladas vuelven a salir mas adelante hasta que se aprenden.
## Los premios son fijos: no se paga por saber, sino por intentarlo.

const TRACKS := ["addsub", "mul", "div"]
const LABELS := {"addsub": "Sumas y restas", "mul": "Multiplicaciones", "div": "Divisiones"}
const SYMBOLS := {"add": "+", "sub": "−", "mul": "×", "div": "÷"}
const MAX_LEVEL := 10

const LEVEL_NAMES := {
	"addsub": ["Sumas muy fáciles", "Sumas hasta 10", "Restas hasta 10", "Sumas hasta 20", "Restas hasta 20",
		"Decenas y unidades", "Cruzar la decena", "Dos cifras sin llevar", "Dos cifras llevando", "Tres cifras"],
	"mul": ["Tabla del 2", "Tablas del 5 y 10", "Tabla del 3", "Tabla del 4", "Tablas 2, 3, 4, 5 y 10",
		"Tablas del 6 y 9", "Tablas del 7 y 8", "Todas las tablas", "Dos cifras × una (fácil)", "Dos cifras × una cifra"],
	"div": ["Dividir entre 2", "Dividir entre 5 y 10", "Dividir entre 3", "Dividir entre 4", "Dividir entre 2, 3, 4, 5 y 10",
		"Dividir entre 6 y 9", "Dividir entre 7 y 8", "Todas las divisiones", "Dos cifras ÷ una (fácil)", "Dos cifras ÷ una cifra"],
}

# Segundos para considerar una respuesta "rapida" en cada nivel (generosos: incluyen leer la cuenta).
const FAST_SECONDS := {
	"addsub": [4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 11.0, 12.0, 14.0, 18.0],
	"mul": [4.0, 4.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0, 10.0, 14.0],
	"div": [5.0, 5.0, 5.0, 5.0, 6.0, 6.0, 7.0, 7.0, 12.0, 16.0],
}

# Mesas de multiplicar por nivel (niveles 1 a 8)
const TABLES := {
	1: [2], 2: [5, 10], 3: [3], 4: [4], 5: [2, 3, 4, 5, 10], 6: [6, 9], 7: [7, 8], 8: [2, 3, 4, 5, 6, 7, 8, 9, 10],
}

# --- dominio de un nivel
const WINDOW := 8            # respuestas que se miran (abarcan al menos dos turnos de trabajo)
const CONSTANCY := 15        # aciertos seguidos que bastan aunque se responda despacio
const HISTORY_KEEP := 20
const DOWN_MAX_CORRECT := 4  # 4 aciertos de 8 o menos: se baja un nivel para afirmar
const JUMP_FACTOR := 0.5     # tan rapido como la mitad del tiempo: salta dos niveles

# --- el turno de trabajo y los premios (siempre iguales)
const QUESTIONS_PER_SHIFT := 5
const PAPERS_PER_QUESTION := 4
const SHIFT_SECONDS := 75.0     # lo que dura el turno de trabajo (el reloj se frena mientras se resuelve un examen)
const FULL_SHIFT_BONUS := 20  # monedas extra por terminar el turno completo (no es obligatorio)
const LEVEL_UP_BONUS := 30   # premio fijo por cada avance de nivel

static var current_track := "addsub"   # camino elegido en la oficina


# ------------------------------------------------------------------ utilidades

static func _pick(list: Array, rng: RandomNumberGenerator):
	return list[rng.randi() % list.size()]


static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


static func level_name(track: String, level: int) -> String:
	return LEVEL_NAMES[track][clampi(level, 1, MAX_LEVEL) - 1]


static func fast_seconds(track: String, level: int) -> float:
	return FAST_SECONDS[track][clampi(level, 1, MAX_LEVEL) - 1]


## Identifica una cuenta (para recordar las que se fallan). La multiplicacion es conmutativa.
static func fact_key(op: String, a: int, b: int) -> String:
	if op == "mul":
		return "mul:%d:%d" % [mini(a, b), maxi(a, b)]
	return "%s:%d:%d" % [op, a, b]


# ------------------------------------------------------------- generar cuentas

## [operacion, a, b] para un nivel de sumas y restas.
static func _addsub(level: int, rng: RandomNumberGenerator) -> Array:
	var a := 0
	var b := 0
	match level:
		1:
			return ["add", rng.randi_range(1, 5), rng.randi_range(1, 5)]
		2:
			a = rng.randi_range(1, 9)
			return ["add", a, rng.randi_range(1, 10 - a)]
		3:
			if rng.randf() < 0.35:
				a = rng.randi_range(1, 9)
				return ["add", a, rng.randi_range(1, 10 - a)]
			a = rng.randi_range(3, 10)
			return ["sub", a, rng.randi_range(1, a - 1)]
		4:
			if rng.randf() < 0.6:
				a = rng.randi_range(2, 9)
				return ["add", a, rng.randi_range(maxi(2, 11 - a), 9)]
			a = rng.randi_range(3, 10)
			return ["sub", a, rng.randi_range(1, a - 1)]
		5:
			if rng.randf() < 0.35:
				a = rng.randi_range(2, 9)
				return ["add", a, rng.randi_range(maxi(2, 11 - a), 9)]
			return ["sub", rng.randi_range(11, 20), rng.randi_range(2, 9)]
	var add := rng.randf() < 0.5
	var t1 := 0
	var t2 := 0
	var u1 := 0
	var u2 := 0
	match level:
		6:  # decenas y unidades, sin pasar de decena
			if add:
				u1 = rng.randi_range(0, 8)
				return ["add", rng.randi_range(1, 8) * 10 + u1, rng.randi_range(1, 9 - u1)]
			u1 = rng.randi_range(1, 9)
			return ["sub", rng.randi_range(1, 9) * 10 + u1, rng.randi_range(1, u1)]
		7:  # cruzando la decena
			if add:
				u1 = rng.randi_range(1, 9)
				return ["add", rng.randi_range(1, 8) * 10 + u1, rng.randi_range(10 - u1, 9)]
			u1 = rng.randi_range(0, 8)
			return ["sub", rng.randi_range(2, 9) * 10 + u1, rng.randi_range(u1 + 1, 9)]
		8:  # dos cifras sin llevar
			if add:
				t1 = rng.randi_range(1, 8)
				t2 = rng.randi_range(1, 9 - t1)
				u1 = rng.randi_range(0, 8)
				u2 = rng.randi_range(1, 9 - u1)
				return ["add", t1 * 10 + u1, t2 * 10 + u2]
			t1 = rng.randi_range(2, 9)
			t2 = rng.randi_range(1, t1 - 1)
			u1 = rng.randi_range(1, 9)
			u2 = rng.randi_range(0, u1)
			return ["sub", t1 * 10 + u1, t2 * 10 + u2]
		9:  # dos cifras llevando
			if add:
				u1 = rng.randi_range(1, 9)
				u2 = rng.randi_range(10 - u1, 9)
				return ["add", rng.randi_range(1, 7) * 10 + u1, rng.randi_range(1, 7) * 10 + u2]
			t1 = rng.randi_range(3, 9)
			u1 = rng.randi_range(0, 8)
			u2 = rng.randi_range(u1 + 1, 9)
			return ["sub", t1 * 10 + u1, rng.randi_range(1, t1 - 1) * 10 + u2]
	# nivel 10: tres cifras
	if add:
		a = rng.randi_range(100, 699)
		return ["add", a, rng.randi_range(100, 999 - a)]
	a = rng.randi_range(250, 999)
	return ["sub", a, rng.randi_range(100, a - 50)]


## [operacion, a, b] para multiplicaciones o divisiones.
static func _tables(track: String, level: int, rng: RandomNumberGenerator) -> Array:
	if level <= 8:
		var t: int = _pick(TABLES[level], rng)
		var q := rng.randi_range(2 if level == 8 else 1, 10)
		if track == "mul":
			return ["mul", t, q] if rng.randf() < 0.5 else ["mul", q, t]
		return ["div", t * q, t]
	if track == "mul":
		if level == 9:
			return ["mul", rng.randi_range(11, 19), rng.randi_range(2, 5)]
		return ["mul", rng.randi_range(12, 40), rng.randi_range(2, 9)]
	if level == 9:
		var d := rng.randi_range(2, 5)
		return ["div", d * rng.randi_range(11, 19), d]
	var d2 := rng.randi_range(2, 9)
	return ["div", d2 * rng.randi_range(12, 30), d2]


static func _answer(op: String, a: int, b: int) -> int:
	match op:
		"add":
			return a + b
		"sub":
			return a - b
		"mul":
			return a * b
	return a / b


## Arma una cuenta completa a partir de la operacion y los numeros.
static func build_problem(track: String, level: int, op: String, a: int, b: int, rng: RandomNumberGenerator) -> Dictionary:
	var answer := _answer(op, a, b)
	return {
		"track": track, "level": level, "op": op, "a": a, "b": b, "answer": answer,
		"text": "%d %s %d" % [a, SYMBOLS[op], b], "key": fact_key(op, a, b),
		"options": make_options(answer, op, a, b, rng),
	}


## Una cuenta nueva del nivel pedido.
static func generate(track: String, level: int, rng: RandomNumberGenerator) -> Dictionary:
	level = clampi(level, 1, MAX_LEVEL)
	var spec: Array = _addsub(level, rng) if track == "addsub" else _tables(track, level, rng)
	return build_problem(track, level, spec[0], spec[1], spec[2], rng)


## Elige la proxima cuenta del turno: a veces repasa una que se fallo antes (si no esta entre las
## ultimas preguntas) y si no, una nueva del nivel. `weak` = [{"op","a","b","streak"}].
static func pick_problem(track: String, level: int, rng: RandomNumberGenerator, weak: Array, recent: Array) -> Dictionary:
	if not weak.is_empty() and rng.randf() < 0.3:
		var options := weak.filter(func(w): return not recent.has(fact_key(w["op"], w["a"], w["b"])))
		if not options.is_empty():
			options.sort_custom(func(x, y): return x["streak"] < y["streak"])
			var w: Dictionary = options[0]
			var p := build_problem(track, level, w["op"], w["a"], w["b"], rng)
			p["review"] = true
			return p
	var p2 := generate(track, level, rng)
	for i in 8:
		if not recent.has(p2["key"]):
			break
		p2 = generate(track, level, rng)
	return p2


## Tres respuestas: la correcta y dos que se parecen (errores comunes), mezcladas.
static func make_options(answer: int, op: String, a: int, b: int, rng: RandomNumberGenerator) -> Array:
	var cands := []
	for d in [1, -1, 2, -2, 10, -10, 5, -5, 3, -3]:
		cands.append(answer + d)
	if op == "mul":
		cands.append_array([answer + a, answer - a, answer + b, answer - b])
	var pool := []
	for c in cands:
		if c >= 0 and c != answer and not pool.has(c):
			pool.append(c)
	_shuffle(pool, rng)
	var options := [answer, pool[0], pool[1]]
	_shuffle(options, rng)
	return options


# --------------------------------------------------------------- explicaciones

## Pasos para resolver sumando o restando b por partes (centenas, decenas y unidades).
static func _stepwise(a: int, b: int, sign: String) -> String:
	var parts := []
	for unit in [100, 10, 1]:
		var piece: int = (b / unit) % 10 * unit
		if piece > 0:
			parts.append(piece)
	var steps := []
	var current := a
	for piece in parts:
		var next: int = current + piece if sign == "+" else current - piece
		steps.append("%d %s %d = %d" % [current, sign, piece, next])
		current = next
	return "\n".join(steps)


## Explicacion corta y clara de por que da ese resultado (se muestra cuando se falla).
static func explanation(p: Dictionary) -> String:
	var a: int = p["a"]
	var b: int = p["b"]
	var r: int = p["answer"]
	match p["op"]:
		"add":
			if b >= 10:
				return "%d + %d = %d\nSumamos por partes:\n%s" % [a, b, r, _stepwise(a, b, "+")]
			if a + b > 10 and a % 10 + b >= 10:  # completar la decena
				var to_ten := 10 - a % 10
				var ten := a + to_ten
				return "%d + %d = %d\nPrimero completamos la decena: %d + %d = %d,\nluego %d + %d = %d." % [a, b, r, a, to_ten, ten, ten, b - to_ten, r]
			return "%d + %d = %d\nJuntamos %d y %d: en total hay %d." % [a, b, r, a, b, r]
		"sub":
			if b >= 10:
				return "%d − %d = %d\nRestamos por partes:\n%s" % [a, b, r, _stepwise(a, b, "-").replace(" - ", " − ")]
			if a >= 10 and a % 10 < b and a % 10 != 0:  # bajar hasta la decena
				var down := a % 10
				var ten2 := a - down
				return "%d − %d = %d\nPrimero bajamos hasta la decena: %d − %d = %d,\nluego %d − %d = %d." % [a, b, r, a, down, ten2, ten2, b - down, r]
			return "%d − %d = %d\nSi tienes %d y quitas %d, te quedan %d." % [a, b, r, a, b, r]
		"mul":
			var groups := mini(a, b)
			var size := maxi(a, b)
			var parts := []
			for i in groups:
				parts.append(str(size))
			if groups <= 6 and groups > 1 and size <= 12:
				return "%d × %d = %d\n%d veces %d: %s = %d." % [a, b, r, groups, size, " + ".join(parts), r]
			if size >= 11 and groups <= 9:
				var tens: int = size / 10 * 10
				var rest := size - tens
				return "%d × %d = %d\nSepáralo: %d × %d = %d y %d × %d = %d.\nLos sumamos: %d + %d = %d." % [a, b, r, tens, groups, tens * groups, rest, groups, rest * groups, tens * groups, rest * groups, r]
			return "%d × %d = %d\nSon %d grupos de %d: en total hay %d." % [a, b, r, groups, size, r]
		"div":
			return "%d ÷ %d = %d\nPorque %d × %d = %d.\nDividir es repartir %d en grupos de %d: salen %d grupos." % [a, b, r, b, r, a, a, b, r]
	return ""


# ------------------------------------------------------------------- lecciones

static func _table_line(t: int) -> String:
	var parts := []
	for i in range(1, 11):
		parts.append("%d × %d = %d" % [t, i, t * i])
	return "  ·  ".join(parts)


const ADDSUB_LESSONS := [
	"Sumar es juntar.
3 + 2 = 5",
	"Busca las parejas del 10.
1+9  ·  2+8  ·  3+7  ·  4+6  ·  5+5",
	"Restar es quitar.
8 − 3 = 5",
	"Completa el 10 primero.
8 + 5  →  8 + 2 = 10  →  10 + 3 = 13",
	"Baja primero hasta el 10.
14 − 6  →  14 − 4 = 10  →  10 − 2 = 8",
	"Mira solo las unidades.
34 + 5  →  4 + 5 = 9  →  39",
	"Llega a la decena y sigue.
38 + 7  →  38 + 2 = 40  →  45",
	"Decenas con decenas, unidades con unidades.
34 + 25  →  50 + 9 = 59",
	"Suma por partes.
47 + 38  →  47 + 30 = 77  →  77 + 8 = 85",
	"Separa en centenas, decenas y unidades.
234 + 156  →  334  →  384  →  390",
]
const MUL_TRICKS := {
	1: "Por 2 es el doble.
2 × 6 = 12",
	2: "Por 10 agregas un 0. Por 5 termina en 0 o 5.
10 × 7 = 70",
	3: "La tabla del 3 va de 3 en 3.
3 · 6 · 9 · 12 · 15",
	4: "Por 4 es el doble del doble.
4 × 6  →  12  →  24",
	5: "Repasamos las tablas del 2, 3, 4, 5 y 10.",
	6: "Tabla del 9: sus dígitos suman 9.
9 × 4 = 36  →  3 + 6 = 9",
	7: "Repite las tablas del 7 y del 8.
Por 8 es el doble del doble del doble.",
	8: "Todas las tablas mezcladas. ¡Tú puedes!",
	9: "Separa el número grande.
12 × 3  →  30 + 6 = 36",
	10: "Separa el número grande.
23 × 4  →  80 + 12 = 92",
}


## Lo que se muestra antes de practicar un nivel: {"title", "lines"}.
static func lesson(track: String, level: int) -> Dictionary:
	level = clampi(level, 1, MAX_LEVEL)
	var title := "Nivel %d: %s" % [level, level_name(track, level)]
	var lines: Array = []
	if track == "addsub":
		lines.append(ADDSUB_LESSONS[level - 1])
	else:
		if track == "div":
			lines.append("Dividir es repartir en partes iguales.\n12 ÷ 3 = 4  porque  3 × 4 = 12")
			if level >= 9:
				lines.append("Separa el número grande.\n48 ÷ 4  →  10 + 2 = 12")
		else:
			lines.append(MUL_TRICKS[level])
		if level in [1, 2, 3, 4, 6, 7]:  # las tablas de este nivel, a la vista para repasar
			for t in TABLES[level]:
				lines.append(_table_line(t))
	return {"title": title, "lines": lines}


# -------------------------------------------------------------------- la nota

## Nota final del turno (de 0 a 10) con mensaje animado.
static func grade(correct: int, total: int) -> Dictionary:
	var note := int(round(10.0 * correct / maxf(total, 1)))
	var title := "¡Ánimo!"
	var message := "Mira las respuestas de abajo: ¡así se aprende! La próxima te sale mejor."
	if note >= 9:
		title = "¡Excelente!"
		message = "¡Eres un genio de las cuentas!"
	elif note >= 7:
		title = "¡Muy bien!"
		message = "¡Casi perfecto! Sigue así."
	elif note >= 5:
		title = "¡Bien!"
		message = "Vas por buen camino. ¡Practicando se mejora!"
	elif note >= 3:
		title = "¡Sigue intentando!"
		message = "Cada cuenta que repasas te hace más rápido."
	return {"note": note, "title": title, "message": message}


# -------------------------------------------------------------- dominio del nivel

## Decide que hacer con el nivel segun las ultimas respuestas (`history` = [{"c": bool, "t": segundos}]).
## Devuelve {"action": "none"|"up"|"jump"|"complete"|"down", "levels": int, "reason": String}.
static func evaluate(track: String, level: int, history: Array) -> Dictionary:
	var n := history.size()
	var result := {"action": "none", "levels": 0, "reason": ""}
	if n >= WINDOW:
		var win := history.slice(n - WINDOW, n)
		var wrong := win.filter(func(h): return not h["c"]).size()
		if wrong == 0:
			var times := win.map(func(h): return float(h["t"]))
			times.sort()
			var median: float = (times[WINDOW / 2 - 1] + times[WINDOW / 2]) / 2.0
			var fast := fast_seconds(track, level)
			if median <= fast * JUMP_FACTOR:
				return _advance(level, 2, "¡Respondiste las últimas %d cuentas perfectas y rapidísimo!" % WINDOW)
			if median <= fast:
				return _advance(level, 1, "¡Respondiste las últimas %d cuentas bien y rápido, varias veces seguidas!" % WINDOW)
	if n >= CONSTANCY:
		var recent := history.slice(n - CONSTANCY, n)
		if recent.all(func(h): return h["c"]):
			return _advance(level, 1, "¡Llevas %d cuentas seguidas bien! Tu constancia da frutos." % CONSTANCY)
	if n >= WINDOW and level > 1:
		var win2 := history.slice(n - WINDOW, n)
		var right := win2.filter(func(h): return h["c"]).size()
		if right <= DOWN_MAX_CORRECT:
			result["action"] = "down"
			result["levels"] = 1
			result["reason"] = "Vamos a practicar un nivel más fácil para afirmar lo que ya sabes."
	return result


static func _advance(level: int, steps: int, reason: String) -> Dictionary:
	if level >= MAX_LEVEL:
		return {"action": "complete", "levels": 0, "reason": "¡Dominaste todo el camino! %s" % reason}
	var target := mini(MAX_LEVEL, level + steps)
	return {"action": "jump" if target - level >= 2 else "up", "levels": target - level, "reason": reason}


## Respuestas seguidas (desde la ultima hacia atras) que fueron correctas y rapidas.
static func good_streak(track: String, level: int, history: Array) -> int:
	var fast := fast_seconds(track, level)
	var count := 0
	for i in range(history.size() - 1, -1, -1):
		var h: Dictionary = history[i]
		if h["c"] and float(h["t"]) <= fast:
			count += 1
		else:
			break
	return count
