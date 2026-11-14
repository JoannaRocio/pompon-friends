class_name SpanishProblems
extends RefCounted
## Clase de Español: la materia de idiomas cuando se juega en inglés (en español es la clase de Inglés,
## EnglishProblems). Usa las MISMAS palabras y frases de EnglishProblems, al revés:
##   "es_words": se ve la palabra en inglés (con su dibujo) -> ¿cómo se dice en español?
##   "es_meaning": se ve la palabra en español -> ¿qué significa en inglés?
##   "es_phrases": se ve la frase en inglés -> ¿cuál es en español?
## La voz del teléfono dice el español (si tiene una voz en español). No se escribe la pronunciación.
## El progreso va en sus propios caminos (es_*), aparte de los de Inglés (en_*). El dominio del nivel,
## los premios y el turno son los mismos que en Matemáticas (ver MathProblems).
## (Los textos de esta materia solo se ven en inglés: por eso están escritos en inglés.)

const TRACKS := ["es_words", "es_meaning", "es_phrases"]
const LABELS := {"es_words": "Words", "es_meaning": "What does it mean?", "es_phrases": "Sentences"}
const MAX_LEVEL := 10

const LEVEL_NAMES := {
	"es_words": ["Colors", "Numbers", "Animals", "Food", "Family", "Body", "Clothes", "Home", "School", "Nature"],
	"es_meaning": ["Greetings", "How I feel", "Opposites", "Actions", "Days", "Weather", "Places", "Toys", "Months", "Questions"],
	"es_phrases": ["I am, you are", "A and an", "One and many", "To have", "He, she, they", "There is", "Can and can't",
		"In, on, under", "I like", "Questions"],
}
const FAST_SECONDS := {"es_words": 5.0, "es_meaning": 5.0, "es_phrases": 9.0}

const WINDOW := MathProblems.WINDOW
const HISTORY_KEEP := MathProblems.HISTORY_KEEP
const QUESTIONS_PER_SHIFT := MathProblems.QUESTIONS_PER_SHIFT
const SHIFT_SECONDS := MathProblems.SHIFT_SECONDS
const FULL_SHIFT_BONUS := MathProblems.FULL_SHIFT_BONUS
const LEVEL_UP_BONUS := MathProblems.LEVEL_UP_BONUS

static var current_track := "es_words"   # camino elegido en el aula

# La regla de cada nivel de frases (leccion y explicacion cuando se falla).
const RULES := [
	"Soy / estoy = I am. Eres = you are. Es = he, she or it is. Somos = we are.",
	"Un and una both mean a or an: un perro (a dog), una manzana (an apple).",
	"For more than one, add s or es: gato → gatos, ratón → ratones.",
	"Tengo = I have. Tiene = he or she has. Tenemos = we have.",
	"Él = he. Ella = she. Ellos = they.",
	"Hay = there is and there are.",
	"Puede = can. No puede = can't.",
	"Dentro = in. Encima = on. Debajo = under.",
	"Me gusta = I like. Le gusta = he or she likes.",
	"In Spanish, questions start with ¿ and end with ?",
]
const LESSON_TRICKS := {
	"es_words": "Learn how to say them in Spanish.",
	"es_meaning": "Learn what they mean.",
}


static func track_label(track: String) -> String:
	return LABELS[track]


static func level_name(track: String, level: int) -> String:
	return LEVEL_NAMES[track][clampi(level, 1, MAX_LEVEL) - 1]


static func fast_seconds(track: String, _level: int) -> float:
	return FAST_SECONDS[track]


## Las palabras o frases de un nivel (las de EnglishProblems): {"en", "es", "pic"}.
static func items(track: String, level: int) -> Array:
	level = clampi(level, 1, MAX_LEVEL)
	var out: Array = []
	match track:
		"es_words":
			for line in EnglishProblems.WORDS[level - 1]:
				var f := String(line).split("|")
				out.append({"en": f[0], "es": f[1], "pic": f[3]})
		"es_meaning":
			for line in EnglishProblems.MEANINGS[level - 1]:
				var f := String(line).split("|")
				out.append({"en": f[0], "es": f[1], "pic": ""})
		"es_phrases":
			for line in EnglishProblems.PHRASES[level - 1]:
				var f := String(line).split("|")
				out.append({"en": String(f[0]).replace("___", f[1]), "es": f[3], "pic": ""})
	return out


static func item_key(level: int, item: Dictionary) -> String:
	return "%d:%s" % [level, item["en"]]


static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	MathProblems._shuffle(list, rng)


## Arma la pregunta. "speak" = lo que dice la voz (en español, "speak_lang").
static func build_problem(track: String, level: int, item: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var p := {"track": track, "level": level, "key": item_key(level, item), "es": item["es"], "en": item["en"],
		"say": "", "pic": item["pic"], "speak": item["es"], "speak_lang": "es"}
	var all := items(track, level)
	var to_spanish := track != "es_meaning"   # palabras y frases: se elige el español
	var field := "es" if to_spanish else "en"
	var others := all.filter(func(it): return it[field] != item[field]).map(func(it): return it[field])
	_shuffle(others, rng)
	var options: Array = [item[field], others[0], others[1]]
	_shuffle(options, rng)
	p["options"] = options
	p["answer"] = item[field]
	p["prompt"] = item["en"] if to_spanish else item["es"]
	p["ask"] = "How do you say it in Spanish?" if to_spanish else "What does it mean?"
	p["text"] = "%s = %s" % [item["en"], item["es"]]
	return p


static func find_item(track: String, key: String) -> Dictionary:
	var parts := key.split(":", true, 1)
	if parts.size() < 2 or not parts[0].is_valid_int():
		return {}
	var level := int(parts[0])
	if level < 1 or level > MAX_LEVEL:
		return {}
	for it in items(track, level):
		if it["en"] == parts[1]:
			return it
	return {}


static func pick_problem(track: String, level: int, rng: RandomNumberGenerator, weak: Array, recent: Array) -> Dictionary:
	if not weak.is_empty() and rng.randf() < 0.3:
		var options := weak.filter(func(w): return not recent.has(w["key"]))
		if not options.is_empty():
			options.sort_custom(func(x, y): return x["streak"] < y["streak"])
			var w: Dictionary = options[0]
			var item := find_item(track, w["key"])
			if not item.is_empty():
				var p := build_problem(track, int(String(w["key"]).get_slice(":", 0)), item, rng)
				p["review"] = true
				return p
	var pool := items(track, level)
	var fresh := pool.filter(func(it): return not recent.has(item_key(level, it)))
	if fresh.is_empty():
		fresh = pool
	return build_problem(track, level, fresh[rng.randi() % fresh.size()], rng)


static func explanation(p: Dictionary) -> String:
	match p["track"]:
		"es_words":
			return "%s in Spanish is %s." % [_cap(p["en"]), p["es"]]
		"es_meaning":
			return "%s means %s." % [_cap(p["es"]), p["en"]]
	return RULES[clampi(int(p["level"]), 1, MAX_LEVEL) - 1]


static func _cap(text: String) -> String:
	if text == "" or text[0] in ["¿", "¡"]:
		return text
	return text[0].to_upper() + text.substr(1)


static func lesson(track: String, level: int) -> Dictionary:
	level = clampi(level, 1, MAX_LEVEL)
	var title := "Level %d: %s" % [level, level_name(track, level)]
	var list := items(track, level)
	var lines: Array = []
	if track == "es_phrases":
		var first: String = RULES[level - 1]
		for i in 2:
			first += "\n%s = %s" % [list[i]["en"], list[i]["es"]]
		lines.append(first)
		return {"title": title, "lines": lines}
	var head: String = LESSON_TRICKS[track]
	for i in 3:
		head += "\n%s = %s" % [list[i]["en"], list[i]["es"]]
	lines.append(head)
	var rest: Array = []
	for i in range(3, list.size()):
		rest.append("%s = %s" % [list[i]["en"], list[i]["es"]])
	for i in range(0, rest.size(), 3):
		lines.append("  ·  ".join(rest.slice(i, i + 3)))
	return {"title": title, "lines": lines}


static func grade(correct: int, total: int) -> Dictionary:
	var g := MathProblems.grade(correct, total)
	var note: int = g["note"]
	if note >= 9:
		g["message"] = "You speak Spanish like a champion!"
	elif note >= 7:
		g["message"] = "Almost perfect! ¡Muy bien!"
	elif note >= 5:
		g["message"] = "You're on the right track. Practice makes progress!"
	elif note >= 3:
		g["message"] = "Every word you review sticks with you."
	return g


static func evaluate(track: String, level: int, history: Array) -> Dictionary:
	return MathProblems.judge(fast_seconds(track, level), level, history, "respuestas")


static func good_streak(track: String, level: int, history: Array) -> int:
	return MathProblems.streak(fast_seconds(track, level), history)
