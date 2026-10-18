class_name PomponGrowth
extends RefCounted
## Calidad de crecimiento: la barra mas importante. Mide que tan bien cuidas a tu Pompon durante cada
## etapa (bebe 7 dias, niño 14, adolescente 30). Cada dia vale unos puntos segun lo que hagas: entrar a
## verlo, mantener sus necesidades, darle de comer, agua y baño, cariño, minijuegos y socializar
## (con su cuidador y con otros Pompons). Al terminar la etapa, segun la barra:
##   - 90 o mas: crece con un rasgo muy positivo y sabiendo 5 palabras nuevas.
##   - 50 a 89: rasgos normales (y algunas palabras).
##   - menos de 50: rasgos como tímido, miedoso o solitario (y pocas palabras).
## Los datos se guardan en `Pompon.growth`.

const TASKS := [
	{"key": "presence", "label": "Entrar a verlo", "weight": 0.15, "need": 1.0},
	{"key": "needs", "label": "Mantener sus necesidades bien", "weight": 0.20, "need": 1.0},
	{"key": "fed", "label": "Darle de comer (2 veces)", "weight": 0.15, "need": 2.0},
	{"key": "drink", "label": "Darle agua", "weight": 0.05, "need": 1.0},
	{"key": "bath", "label": "Bañarlo", "weight": 0.05, "need": 1.0},
	{"key": "trust", "label": "Darle cariño (2 veces)", "weight": 0.10, "need": 2.0},
	{"key": "learn", "label": "Jugar 2 minijuegos", "weight": 0.15, "need": 2.0},
	{"key": "social_carer", "label": "Pasar un rato juntos", "weight": 0.075, "need": 1.0},
	{"key": "social_others", "label": "Visitar a otro Pompon", "weight": 0.075, "need": 1.0},
]
const EXCELLENT := 90.0
const NORMAL := 50.0
const GOOD_NEED := 40.0          # una muestra de necesidades es "buena" si comida, agua y aseo estan por encima

# Palabras que aprende al terminar cada etapa (la clave es la etapa que termina).
const WORDS := {
	1: ["agua", "mamá", "comida", "hola", "gracias"],
	2: ["amigo", "jugar", "abrazo", "quiero", "casa"],
	3: ["familia", "juntos", "aprender", "siempre", "confío"],
}
# Rasgos segun el resultado: [metrica, nombre]
const TRAITS_EXCELLENT := {"social": "Muy amable", "trust": "Súper confiado", "gift": "Muy generoso"}
const TRAITS_NORMAL := {"joy": "Curioso", "trust": "Alegre", "social": "Amable"}
const TRAITS_POOR := {"trust": "Miedoso", "social": "Solitario", "joy": "Tímido"}
const TRAIT_INFO := {
	"Muy amable": "Se lleva bien con todos", "Súper confiado": "Confía mucho en ti", "Muy generoso": "Siempre quiere compartir",
	"Curioso": "Quiere saber cómo funciona todo", "Alegre": "Contagia buen humor", "Amable": "Trata bien a los demás",
	"Miedoso": "Le cuesta confiar", "Solitario": "Prefiere estar solito", "Tímido": "Le da vergüenza todo lo nuevo",
}
const TRAIT_STAT := {
	"Muy amable": "amistad", "Súper confiado": "amor", "Muy generoso": "felicidad", "Curioso": "inteligencia",
	"Alegre": "felicidad", "Amable": "amistad", "Miedoso": "amor", "Solitario": "amistad", "Tímido": "amor",
}


# ------------------------------------------------------------------ calendario de la etapa

## Segundo en que empezo la etapa `stage` (1 = bebe, 2 = niño, 3 = adolescente).
static func stage_start(p: Pompon, stage: int) -> int:
	var t := p.born_at
	for i in range(1, stage):
		t += int(Pompon.STAGE_SECONDS[i])
	return t


## Dias que dura la etapa (0 si no hay crecimiento que medir: huevo y adulto).
static func stage_days(stage: int) -> int:
	if stage < 1 or stage > 3:
		return 0
	return int(Pompon.STAGE_SECONDS[stage]) / 86400


static func active(p: Pompon, now: int) -> bool:
	return p != null and p.hatched and stage_days(p.stage_index(now)) > 0


## Dia de la etapa en el que estamos (0 = el primero).
static func day_index(p: Pompon, now: int) -> int:
	var stage := p.stage_index(now)
	return clampi(maxi(0, now - stage_start(p, stage)) / 86400, 0, maxi(stage_days(stage) - 1, 0))


static func days_left(p: Pompon, now: int) -> int:
	var stage := p.stage_index(now)
	return stage_days(stage) - day_index(p, now) if stage_days(stage) > 0 else 0


static func _stages(p: Pompon) -> Dictionary:
	if not p.growth.has("stages"):
		p.growth["stages"] = {}
	return p.growth["stages"]


static func _days(p: Pompon, stage: int) -> Dictionary:
	var stages := _stages(p)
	if not stages.has(str(stage)):
		stages[str(stage)] = {}
	return stages[str(stage)]


static func _day(p: Pompon, stage: int, day: int) -> Dictionary:
	var days := _days(p, stage)
	if not days.has(str(day)):
		days[str(day)] = {}
	return days[str(day)]


# ------------------------------------------------------------------ registrar lo que haces

static func record(p: Pompon, now: int, key: String, amount := 1.0) -> void:
	if not active(p, now):
		return
	var rec := _day(p, p.stage_index(now), day_index(p, now))
	rec[key] = float(rec.get(key, 0.0)) + amount


## Un suceso del juego ("fed", "drank", "bathed", "petted", "tapped", "played", "visited") suma a la tarea que corresponda.
static func record_event(p: Pompon, event: String, now: int) -> void:
	match event:
		"fed":
			record(p, now, "fed")
		"drank":
			record(p, now, "drink")
		"bathed":
			record(p, now, "bath")
		"petted":
			record(p, now, "trust")
			record(p, now, "social_carer", 0.5)
		"gifted":
			record(p, now, "gift")
		"tapped":
			record(p, now, "trust", 0.5)
		"played":
			record(p, now, "learn")
			record(p, now, "social_carer", 0.5)
		"visited":
			record(p, now, "social_others")


## Mira como estan sus necesidades basicas (se llama al entrar y cada tanto): una muestra buena o mala.
static func sample_needs(p: Pompon, now: int) -> void:
	if not active(p, now):
		return
	var rec := _day(p, p.stage_index(now), day_index(p, now))
	rec["presence"] = 1.0
	rec["samples"] = float(rec.get("samples", 0.0)) + 1.0
	var good := true
	for s in ["alimentacion", "hidratacion", "aseo"]:
		if float(p.stats.get(s, 0.0)) < GOOD_NEED:
			good = false
	if good:
		rec["good"] = float(rec.get("good", 0.0)) + 1.0


# ------------------------------------------------------------------ puntajes

## Cuanto de la tarea `task` se hizo ese dia (0 a 1).
static func task_done(rec: Dictionary, task: Dictionary) -> float:
	if task["key"] == "needs":
		var samples := float(rec.get("samples", 0.0))
		return clampf(float(rec.get("good", 0.0)) / samples, 0.0, 1.0) if samples > 0.0 else 0.0
	return clampf(float(rec.get(task["key"], 0.0)) / float(task["need"]), 0.0, 1.0)


## Puntaje de un dia (0 a 1).
static func day_score(rec: Dictionary) -> float:
	var total := 0.0
	for t in TASKS:
		total += float(t["weight"]) * task_done(rec, t)
	return total


static func quality_for_stage(p: Pompon, stage: int) -> float:
	var n := stage_days(stage)
	if n <= 0:
		return 0.0
	var total := 0.0
	var days := _days(p, stage)
	for k in days:
		if int(k) < n:
			total += day_score(days[k])
	return clampf(total / float(n) * 100.0, 0.0, 100.0)


## Calidad de crecimiento ahora (0 a 100) de la etapa en curso.
static func quality(p: Pompon, now: int) -> float:
	if not active(p, now):
		return 0.0
	return quality_for_stage(p, p.stage_index(now))


## Calidad que tendria al terminar la etapa si sigue al ritmo de hoy (cuenta el dia de hoy como completo).
static func pace(p: Pompon, now: int) -> float:
	if not active(p, now):
		return 0.0
	var stage := p.stage_index(now)
	return clampf(quality(p, now) / maxf(float(day_index(p, now) + 1) / float(stage_days(stage)), 0.05), 0.0, 100.0)


static func tier(q: float) -> String:
	return "excelente" if q >= EXCELLENT else ("normal" if q >= NORMAL else "floja")


static func tier_color(q: float) -> Color:
	return Color("5fc77f") if q >= EXCELLENT else (Color("ffb938") if q >= NORMAL else Color("ff7a6b"))


## Lo que habria que hacer hoy: [{"label", "done" (0 a 1), "weight"}].
static func checklist(p: Pompon, now: int) -> Array:
	var out: Array = []
	if not active(p, now):
		return out
	var rec := _day(p, p.stage_index(now), day_index(p, now))
	for t in TASKS:
		out.append({"label": t["label"], "done": task_done(rec, t), "weight": t["weight"]})
	return out


# ------------------------------------------------------------------ palabras

## Calidad que hace falta para aprender cada palabra: la primera recien llega con buen cuidado de varios dias.
const WORD_THRESHOLDS := [25.0, 40.0, 55.0, 70.0, 85.0]


static func words_for(q: float) -> int:
	var n := 0
	for t in WORD_THRESHOLDS:
		if q >= t:
			n += 1
	return n


## Palabras que ya sabe decir de la etapa en curso (cuanto mejor lo cuidas, mas rapido aprende a hablar).
static func live_words(p: Pompon, now: int) -> Array:
	if not active(p, now):
		return []
	var list: Array = WORDS.get(p.stage_index(now), [])
	return list.slice(0, mini(words_for(quality(p, now)), list.size()))


static func final_words(p: Pompon) -> Array:
	return p.growth.get("words", [])


static func known_words(p: Pompon, now: int) -> Array:
	return final_words(p) + live_words(p, now)


## Palabras nuevas que aprendio desde la ultima vez: devuelve entradas para el diario.
static func check_words(p: Pompon, now: int) -> Array:
	var out: Array = []
	if not active(p, now):
		return out
	var stage := p.stage_index(now)
	var announced: Dictionary = p.growth.get("announced", {})
	var done := int(announced.get(str(stage), 0))
	var words := live_words(p, now)
	for i in range(done, words.size()):
		out.append({"kind": "frase", "text": "¡Ahora sé decir «%s»!" % words[i], "stat": "inteligencia", "key": "word:%s" % words[i]})
	if words.size() > done:
		announced[str(stage)] = words.size()
		p.growth["announced"] = announced
	return out


# ------------------------------------------------------------------ fin de etapa

static func _sum(p: Pompon, stage: int, keys: Array) -> float:
	var total := 0.0
	var days := _days(p, stage)
	for d in days:
		for k in keys:
			total += float(days[d].get(k, 0.0))
	return total


## La etapa `stage` termino: reparte palabras y rasgo segun la calidad. Devuelve las entradas del diario.
static func finish_stage(p: Pompon, stage: int, now: int) -> Array:
	var out: Array = []
	if stage_days(stage) <= 0:
		return out
	var history: Dictionary = p.growth.get("history", {})
	if history.has(str(stage)):
		return out   # ya estaba cerrada
	var q := quality_for_stage(p, stage)
	var t := tier(q)
	var social := _sum(p, stage, ["social_carer", "social_others"])
	var trust := _sum(p, stage, ["trust"])
	var joy := _sum(p, stage, ["learn"])
	var gifts := _sum(p, stage, ["gift"]) * 4.0   # dejar un regalo a un vecino es poco frecuente: pesa mas
	var metrics := {"social": social, "trust": trust, "joy": joy, "gift": gifts}
	var pick := ""
	var names: Dictionary = TRAITS_EXCELLENT if t == "excelente" else (TRAITS_NORMAL if t == "normal" else TRAITS_POOR)
	var best_key := ""
	for k in names.keys():   # empata: gana el primero
		if best_key == "" or (metrics[k] > metrics[best_key] if t != "floja" else metrics[k] < metrics[best_key]):
			best_key = k
	pick = names[best_key]
	var list: Array = WORDS.get(stage, [])
	var n := mini(words_for(q), list.size())
	var learned: Array = list.slice(0, n)
	var all_words: Array = p.growth.get("words", [])
	for w in learned:
		if not all_words.has(w):
			all_words.append(w)
	p.growth["words"] = all_words
	var traits: Array = p.growth.get("traits", [])
	traits.append({"stage": stage, "name": pick, "tier": t, "quality": int(round(q))})
	p.growth["traits"] = traits
	history[str(stage)] = {"quality": q, "tier": t, "trait": pick, "words": learned}
	p.growth["history"] = history
	if learned.is_empty():
		out.append({"kind": "sentimiento", "text": "Todavía no sé decir palabras nuevas…", "stat": "inteligencia", "key": "growth:words"})
	else:
		out.append({"kind": "frase", "text": "¡Aprendí %d palabras nuevas: %s!" % [learned.size(), ", ".join(learned.map(func(w): return "«%s»" % w))], "stat": "inteligencia", "key": "growth:words"})
	out.append({"kind": "sentimiento", "text": "Crecí y ahora soy %s" % pick.to_lower(), "stat": TRAIT_STAT.get(pick, "felicidad"), "key": "growth:trait"})
	return out
