class_name GeographyProblems
extends RefCounted
## Geografia del trabajo en el periodico: capitales y banderas del mundo.
##
## Tres caminos de 10 niveles. Los niveles 1 a 5 recorren las regiones (Sudamerica, Norte y
## Centroamerica, Europa, Asia, Africa y Oceania) CON PISTA: se muestra la primera letra ("T...") y las
## tres opciones empiezan igual, asi se aprende jugando. Los niveles 6 a 10 vuelven a las mismas
## regiones SIN PISTA y con opciones parecidas (de la misma region): hay que recordarlo de verdad.
##   "geo_capitals": la bandera y el pais -> ¿cual es su capital?
##   "geo_flags": la bandera -> ¿de que pais es? / el pais -> ¿cual es su bandera? (se elige entre 3 banderas)
##   "geo_mix": la capital -> ¿de que pais es? / la capital -> ¿cual es la bandera de ese pais?
## El dominio del nivel, los premios y el turno son los mismos que en matematicas (ver MathProblems).

const TRACKS := ["geo_capitals", "geo_flags", "geo_mix"]
const LABELS := {"geo_capitals": "Capitales", "geo_flags": "Banderas", "geo_mix": "Capitales y banderas"}
const MAX_LEVEL := 10
const HINT_LEVELS := 5   # hasta este nivel se muestra la primera letra
const REGIONS := ["Sudamérica", "Norte y Centroamérica", "Europa", "Asia", "África y Oceanía"]
const FAST_SECONDS := {"geo_capitals": 6.0, "geo_flags": 6.0, "geo_mix": 7.0}

const WINDOW := MathProblems.WINDOW
const HISTORY_KEEP := MathProblems.HISTORY_KEEP
const QUESTIONS_PER_SHIFT := MathProblems.QUESTIONS_PER_SHIFT
const SHIFT_SECONDS := MathProblems.SHIFT_SECONDS
const FULL_SHIFT_BONUS := MathProblems.FULL_SHIFT_BONUS
const LEVEL_UP_BONUS := MathProblems.LEVEL_UP_BONUS

static var current_track := "geo_capitals"

# "id|Pais|Capital" por region (el id es el de su bandera en FlagArt).
const COUNTRIES := [
	["argentina|Argentina|Buenos Aires", "brasil|Brasil|Brasilia", "chile|Chile|Santiago", "uruguay|Uruguay|Montevideo",
		"paraguay|Paraguay|Asunción", "peru|Perú|Lima", "colombia|Colombia|Bogotá", "venezuela|Venezuela|Caracas", "ecuador|Ecuador|Quito"],
	["mexico|México|Ciudad de México", "eeuu|Estados Unidos|Washington D. C.", "canada|Canadá|Ottawa", "cuba|Cuba|La Habana",
		"costa_rica|Costa Rica|San José", "panama|Panamá|Ciudad de Panamá", "guatemala|Guatemala|Ciudad de Guatemala",
		"honduras|Honduras|Tegucigalpa", "jamaica|Jamaica|Kingston", "dominicana|República Dominicana|Santo Domingo"],
	["espana|España|Madrid", "francia|Francia|París", "italia|Italia|Roma", "alemania|Alemania|Berlín", "portugal|Portugal|Lisboa",
		"reino_unido|Reino Unido|Londres", "irlanda|Irlanda|Dublín", "paises_bajos|Países Bajos|Ámsterdam", "suecia|Suecia|Estocolmo",
		"grecia|Grecia|Atenas", "suiza|Suiza|Berna", "rusia|Rusia|Moscú"],
	["japon|Japón|Tokio", "china|China|Pekín", "corea_sur|Corea del Sur|Seúl", "india|India|Nueva Delhi", "tailandia|Tailandia|Bangkok",
		"vietnam|Vietnam|Hanói", "indonesia|Indonesia|Yakarta", "filipinas|Filipinas|Manila", "turquia|Turquía|Ankara", "banglades|Bangladés|Daca"],
	["egipto|Egipto|El Cairo", "marruecos|Marruecos|Rabat", "nigeria|Nigeria|Abuya", "ghana|Ghana|Acra", "kenia|Kenia|Nairobi",
		"senegal|Senegal|Dakar", "etiopia|Etiopía|Adís Abeba", "australia|Australia|Canberra", "nueva_zelanda|Nueva Zelanda|Wellington",
		"madagascar|Madagascar|Antananarivo"],
]

# Otras capitales y paises del mundo, solo para armar opciones que empiecen con la misma letra.
const EXTRA_CAPITALS := ["Tiflis", "Teherán", "Taskent", "Tirana", "Trípoli", "Túnez", "Taipéi", "Tallin", "Timbu", "Bakú",
	"Belgrado", "Bucarest", "Budapest", "Bratislava", "Beirut", "Bamako", "Bagdad", "Brazzaville", "Bruselas", "Copenhague",
	"Conakri", "Colombo", "Doha", "Damasco", "Dodoma", "Dusambé", "Ereván", "Freetown", "Gaborone", "Harare", "Helsinki",
	"Islamabad", "Jartum", "Kabul", "Kampala", "Kigali", "Katmandú", "Kuala Lumpur", "Kuwait", "La Paz", "Luanda", "Lusaka",
	"Liubliana", "Luxemburgo", "Minsk", "Maputo", "Managua", "Mascate", "Monrovia", "Niamey", "Nicosia", "Nuakchot", "Oslo",
	"Praga", "Puerto Príncipe", "Riga", "Reikiavik", "Sofía", "Sarajevo", "San Salvador", "Singapur", "Skopie", "Ulán Bator",
	"Vilna", "Viena", "Varsovia", "Vientián", "Windhoek", "Yaundé", "Zagreb", "Abu Dabi", "Amán", "Argel", "Asmara", "Astaná",
	"Pionyang", "Phnom Penh", "Port Moresby", "Suva", "Apia", "Nukualofa", "Gitega", "Uagadugú", "Yamusukro", "Victoria", "Valeta"]
const EXTRA_COUNTRIES := ["Japón", "Jordania", "Bolivia", "Bélgica", "Bulgaria", "Camboya", "Camerún", "Croacia", "Dinamarca",
	"Ecuador", "Eslovenia", "Estonia", "Finlandia", "Francia", "Gabón", "Georgia", "Haití", "Hungría", "Irán", "Irak", "Islandia",
	"Kazajistán", "Laos", "Letonia", "Líbano", "Malasia", "Malí", "Mongolia", "Mozambique", "Nepal", "Nicaragua", "Noruega",
	"Omán", "Pakistán", "Polonia", "Qatar", "Rumania", "Ruanda", "Serbia", "Siria", "Somalia", "Sudán", "Taiwán", "Tanzania",
	"Túnez", "Ucrania", "Uganda", "Venezuela", "Vanuatu", "Vaticano", "Yemen", "Zambia", "Zimbabue", "Austria", "Angola", "Argelia", "Armenia",
	"Australia", "Albania", "Guinea", "Grecia", "Ghana", "Paraguay", "Panamá", "Perú", "Portugal", "Tailandia", "Turquía",
	"Togo", "Tonga", "Chad", "Chipre", "Corea del Norte", "Kenia", "Kuwait", "Kirguistán", "Madagascar", "Malta", "Marruecos",
	"Senegal", "Sri Lanka", "Suiza", "Suecia", "Singapur", "Eritrea", "Etiopía", "Egipto", "El Salvador", "Níger",
	"Nigeria", "Nueva Zelanda", "Dominica", "Irlanda", "India", "Indonesia", "Italia", "Israel", "Honduras", "Libia"]

# Las mismas listas en inglés (para las opciones con pista cuando se juega en inglés).
const EXTRA_CAPITALS_EN := [
	"Tbilisi", "Tehran", "Tashkent", "Tirana", "Tripoli", "Tunis", "Taipei", "Tallinn", "Thimphu", "Baku", "Belgrade",
	"Bucharest", "Budapest", "Bratislava", "Beirut", "Bamako", "Baghdad", "Brazzaville", "Brussels", "Copenhagen",
	"Conakry", "Colombo", "Doha", "Damascus", "Dodoma", "Dushanbe", "Djibouti", "Yerevan", "Freetown", "Gaborone",
	"Georgetown", "Harare", "Helsinki", "Islamabad", "Juba", "Khartoum", "Kabul", "Kampala", "Kigali", "Kathmandu",
	"Kuala Lumpur", "Kuwait City", "La Paz", "Luanda", "Lusaka", "Ljubljana", "Luxembourg", "Minsk", "Maputo",
	"Managua", "Muscat", "Monrovia", "Niamey", "Nicosia", "Nouakchott", "Oslo", "Prague", "Port-au-Prince", "Riga",
	"Reykjavik", "Riyadh", "Sofia", "Sarajevo", "San Salvador", "Singapore", "Skopje", "Ulaanbaatar", "Vilnius",
	"Vienna", "Warsaw", "Vientiane", "Windhoek", "Yaounde", "Zagreb", "Abu Dhabi", "Amman", "Algiers", "Asmara",
	"Astana", "Pyongyang", "Phnom Penh", "Port Moresby", "Suva", "Apia", "Gitega", "Ouagadougou", "Yamoussoukro",
	"Victoria", "Valletta", "Honiara"]
const EXTRA_COUNTRIES_EN := [
	"Japan", "Jordan", "Bolivia", "Belgium", "Bulgaria", "Bhutan", "Bahamas", "Cambodia", "Cameroon", "Croatia",
	"Denmark", "Djibouti", "Dominica", "Ecuador", "Slovenia", "Estonia", "Finland", "France", "Gabon", "Georgia",
	"Haiti", "Hungary", "Iran", "Iraq", "Iceland", "Kazakhstan", "Laos", "Latvia", "Lebanon", "Malaysia", "Mali",
	"Mongolia", "Mozambique", "Nepal", "Nicaragua", "Norway", "Oman", "Pakistan", "Poland", "Qatar", "Romania",
	"Rwanda", "Serbia", "Syria", "Somalia", "Sudan", "Taiwan", "Tanzania", "Tunisia", "Ukraine", "Uganda", "Uzbekistan",
	"United Arab Emirates", "Venezuela", "Vanuatu", "Vatican City", "Yemen", "Zambia", "Zimbabwe", "Austria", "Angola",
	"Algeria", "Armenia", "Australia", "Albania", "Guinea", "Greece", "Ghana", "Paraguay", "Panama", "Peru", "Portugal",
	"Thailand", "Turkey", "Togo", "Tonga", "Chad", "Cyprus", "North Korea", "Kenya", "Kuwait", "Kyrgyzstan",
	"Madagascar", "Malta", "Morocco", "Senegal", "Sri Lanka", "Switzerland", "Sweden", "Singapore", "Eritrea",
	"Ethiopia", "Egypt", "El Salvador", "Niger", "Nigeria", "New Zealand", "Ireland", "India", "Indonesia", "Italy",
	"Israel", "Honduras", "Libya", "Fiji"]

const LESSON_TRICK := {
	"geo_capitals": "Mira la bandera y aprende su capital.",
	"geo_flags": "Mira bien los colores de cada bandera.",
	"geo_mix": "Une la capital con su país y su bandera.",
}


# ------------------------------------------------------------------ datos

static func region_of(level: int) -> int:
	return (clampi(level, 1, MAX_LEVEL) - 1) % REGIONS.size()


static func has_hint(level: int) -> bool:
	return level <= HINT_LEVELS


static func level_name(_track: String, level: int) -> String:
	level = clampi(level, 1, MAX_LEVEL)
	return "%s%s" % [T.s(REGIONS[region_of(level)]), T.s(" (con pista)") if has_hint(level) else ""]


static func fast_seconds(track: String, _level: int) -> float:
	return FAST_SECONDS[track]


## Los paises de una region, en el idioma actual: [{"id", "country", "capital"}].
static func countries(region: int) -> Array:
	var out: Array = []
	for line in COUNTRIES[clampi(region, 0, REGIONS.size() - 1)]:
		var f := String(line).split("|")
		out.append({"id": f[0], "country": T.data("geo.c", f[0], f[1]), "capital": T.data("geo.k", f[0], f[2])})
	return out


## Otras capitales y paises del mundo (para las opciones con pista), en el idioma actual.
static func extra_capitals() -> Array:
	return EXTRA_CAPITALS_EN if T.lang() == "en" else EXTRA_CAPITALS


static func extra_countries() -> Array:
	return EXTRA_COUNTRIES_EN if T.lang() == "en" else EXTRA_COUNTRIES


static func track_label(track: String) -> String:
	return T.s(LABELS[track])


static func all_countries() -> Array:
	var out: Array = []
	for r in REGIONS.size():
		out.append_array(countries(r))
	return out


static func find_country(id: String) -> Dictionary:
	for c in all_countries():
		if c["id"] == id:
			return c
	return {}


## Primera letra sin acento ("Ámsterdam" -> "A"), para armar las opciones con pista.
static func initial(text: String) -> String:
	if text == "":
		return ""
	var ch := text.substr(0, 1).to_upper()
	return {"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U"}.get(ch, ch)


## La version "items" para que el juego trate a todos los caminos igual (clave y repaso).
static func items(_track: String, level: int) -> Array:
	return countries(region_of(level))


static func item_key(level: int, item: Dictionary, kind := "") -> String:
	return "%d:%s:%s" % [level, item["id"], kind]


static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	MathProblems._shuffle(list, rng)


## Dos opciones falsas: con pista, que empiecen con la misma letra; sin pista, de la misma region
## (son mas faciles de confundir). `pool_same` = las de la region, `pool_world` = todas las conocidas.
static func _distractors(answer: String, pool_same: Array, pool_world: Array, hint: bool, rng: RandomNumberGenerator) -> Array:
	var letter := initial(answer)
	var first: Array = _unique(pool_world.filter(func(x): return initial(x) == letter) if hint else pool_same, answer)
	_shuffle(first, rng)
	var out: Array = first.slice(0, 2)
	if out.size() < 2:   # (casi no hay capitales con Q u O: se completa con otras)
		var rest: Array = _unique(pool_same + pool_world, answer).filter(func(x): return not out.has(x))
		_shuffle(rest, rng)
		out.append_array(rest.slice(0, 2 - out.size()))
	return out


static func _unique(list: Array, answer: String) -> Array:
	var out: Array = []
	for x in list:
		if x != answer and not out.has(x):
			out.append(x)
	return out


## Que pregunta toca segun el camino (los de banderas y mezcla alternan dos tipos).
static func _kind_for(track: String, rng: RandomNumberGenerator) -> String:
	match track:
		"geo_flags":
			return "flag_to_country" if rng.randf() < 0.5 else "country_to_flag"
		"geo_mix":
			return "capital_to_country" if rng.randf() < 0.5 else "capital_to_flag"
	return "capital"


## Arma la pregunta sobre `item` (un pais). `kind` = "" elige al azar segun el camino.
static func build_problem(track: String, level: int, item: Dictionary, rng: RandomNumberGenerator, kind := "") -> Dictionary:
	if kind == "":
		kind = _kind_for(track, rng)
	var hint := has_hint(level)
	var region := countries(region_of(level))
	var world := all_countries()
	var p := {"track": track, "level": level, "kind": kind, "key": item_key(level, item, kind), "id": item["id"],
		"country": item["country"], "capital": item["capital"], "flag": "", "hint": "", "option_flags": false,
		"text": "%s: %s" % [item["country"], item["capital"]], "en": item["id"], "say": ""}
	var options: Array = []
	match kind:
		"capital":   # bandera + pais -> capital
			p["flag"] = item["id"]
			p["prompt"] = item["country"]
			p["ask"] = T.s("¿Cuál es la capital de %s?") % item["country"]
			p["answer"] = item["capital"]
			var world_caps: Array = world.map(func(c): return c["capital"]) + extra_capitals()
			options = _distractors(item["capital"], region.map(func(c): return c["capital"]), world_caps, hint, rng)
		"flag_to_country":   # bandera -> pais
			p["flag"] = item["id"]
			p["prompt"] = ""
			p["ask"] = T.s("¿De qué país es esta bandera?")
			p["answer"] = item["country"]
			var world_names: Array = world.map(func(c): return c["country"]) + extra_countries()
			options = _distractors(item["country"], region.map(func(c): return c["country"]), world_names, hint, rng)
		"capital_to_country":   # capital -> pais
			p["prompt"] = item["capital"]
			p["ask"] = T.s("¿De qué país es la capital?")
			p["answer"] = item["country"]
			var world_names2: Array = world.map(func(c): return c["country"]) + extra_countries()
			options = _distractors(item["country"], region.map(func(c): return c["country"]), world_names2, hint, rng)
		_:   # "country_to_flag" o "capital_to_flag": se elige entre tres banderas
			p["option_flags"] = true
			p["prompt"] = item["country"] if kind == "country_to_flag" else item["capital"]
			p["ask"] = T.s("¿Cuál es su bandera?") if kind == "country_to_flag" else T.s("¿Cuál es la bandera del país de esta capital?")
			p["answer"] = item["id"]
			# con pista: banderas de otras regiones (muy distintas); sin pista: de la misma region
			var pool: Array = (world if hint else region).filter(func(c): return c["id"] != item["id"] and (not hint or not region.has(c)))
			if pool.size() < 2:
				pool = world.filter(func(c): return c["id"] != item["id"])
			_shuffle(pool, rng)
			options = [pool[0]["id"], pool[1]["id"]]
	options.append(p["answer"])
	_shuffle(options, rng)
	p["options"] = options
	# la pista ("Q…") solo si las tres opciones empiezan con esa letra (con Quito u Ottawa no hay suficientes)
	var letter := initial(str(p["answer"]))
	if hint and not p["option_flags"] and options.all(func(o): return initial(str(o)) == letter):
		p["hint"] = String(p["answer"]).substr(0, 1).to_upper() + "…"
	return p


## Busca la pregunta guardada para repasar ("nivel:pais:tipo"); {} si ya no existe.
static func find_item(_track: String, key: String) -> Dictionary:
	var parts := key.split(":")
	if parts.size() < 2 or not parts[0].is_valid_int():
		return {}
	var level := int(parts[0])
	if level < 1 or level > MAX_LEVEL:
		return {}
	return find_country(parts[1])


## La proxima pregunta: a veces una que se fallo antes; si no, un pais de la region que no haya salido hace poco.
static func pick_problem(track: String, level: int, rng: RandomNumberGenerator, weak: Array, recent: Array) -> Dictionary:
	if not weak.is_empty() and rng.randf() < 0.3:
		var options := weak.filter(func(w): return not recent.has(w["key"]))
		if not options.is_empty():
			options.sort_custom(func(x, y): return x["streak"] < y["streak"])
			var w: Dictionary = options[0]
			var item := find_item(track, w["key"])
			if not item.is_empty():
				var parts := String(w["key"]).split(":")
				var p := build_problem(track, int(parts[0]), item, rng, parts[2] if parts.size() > 2 else "")
				p["review"] = true
				return p
	var pool := items(track, level)
	var recent_ids: Array = recent.map(func(k): return String(k).get_slice(":", 1))
	var fresh := pool.filter(func(it): return not recent_ids.has(it["id"]))
	if fresh.is_empty():
		fresh = pool
	return build_problem(track, level, fresh[rng.randi() % fresh.size()], rng)


## Lo que se muestra cuando se falla.
static func explanation(p: Dictionary) -> String:
	match p["kind"]:
		"capital", "capital_to_country", "capital_to_flag":
			return T.s("La capital de %s es %s.") % [p["country"], p["capital"]]
	return T.s("Esta es la bandera de %s.") % p["country"]


## Antes de practicar un nivel: los paises de la region con su capital.
static func lesson(track: String, level: int) -> Dictionary:
	level = clampi(level, 1, MAX_LEVEL)
	var title := T.s("Nivel %d: %s") % [level, level_name(track, level)]
	var list := items(track, level)
	var head: String = T.s(LESSON_TRICK[track])
	for i in 3:
		head += "\n%s: %s" % [list[i]["country"], list[i]["capital"]]
	var lines: Array = [head]
	var rest: Array = []
	for i in range(3, list.size()):
		rest.append("%s: %s" % [list[i]["country"], list[i]["capital"]])
	for i in range(0, rest.size(), 2):
		lines.append("  ·  ".join(rest.slice(i, i + 2)))
	return {"title": title, "lines": lines, "flags": list.map(func(c): return c["id"])}


static func grade(correct: int, total: int) -> Dictionary:
	var g := MathProblems.grade(correct, total)
	var note: int = g["note"]
	if note >= 9:
		g["message"] = T.s("¡Conoces el mundo entero!")
	elif note >= 7:
		g["message"] = T.s("¡Casi perfecto! Ya eres un gran viajero.")
	elif note >= 5:
		g["message"] = T.s("Vas por buen camino. ¡Cada bandera se te queda!")
	elif note >= 3:
		g["message"] = T.s("Repasa las capitales de abajo: ¡la próxima te salen!")
	return g


static func evaluate(track: String, level: int, history: Array) -> Dictionary:
	return MathProblems.judge(fast_seconds(track, level), level, history, "respuestas")


static func good_streak(track: String, level: int, history: Array) -> int:
	return MathProblems.streak(fast_seconds(track, level), history)
