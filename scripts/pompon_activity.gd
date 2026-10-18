class_name PomponActivity
extends RefCounted
## Lo que el Pompon esta haciendo ahora mismo ("Kiwi gatea por la sala", "Kiwi balbucea ba-ba"):
## siempre hace algo. Sale de su etapa, su personalidad, la hora, donde esta y lo que acaba de pasar.
## No se guarda en el diario: es solo el cuadrito que explica que esta haciendo.

const BABY := [
	"balbucea «ba-ba»", "mira a su alrededor con ojos enormes", "juega con sus patitas", "hace burbujas con la boca",
	"se ríe solito", "se chupa el dedito", "escucha los sonidos de la casa", "intenta decir «ma-ma»",
	"descubre su propia sombra", "hace «pi pi» para ver qué pasa", "mira la luz con curiosidad",
]
const BABY_WALK := ["explora %s", "descubre %s", "curiosea por %s", "recorre %s con curiosidad"]
const GROWN := [
	"aprende cosas de lo que lo rodea", "canturrea una canción", "salta de un lado a otro", "se estira con ganas",
	"huele el aire", "piensa en sus cosas", "mira por todos lados", "juega solito", "hace sonidos con la boca",
]
const GROWN_WALK := ["pasea por %s", "recorre %s", "explora %s", "da una vuelta por %s"]
const PERSONALITY := {
	"Energico": ["hace ejercicio de calentamiento", "corre en el lugar"],
	"Timido": ["se asoma con timidez", "se esconde un poquito y vuelve a mirar"],
	"Curioso": ["investiga cada rincón", "se pregunta cómo funcionan las cosas"],
	"Gloton": ["se relame pensando en comida", "se imagina una torta enorme"],
	"Artistico": ["dibuja en el aire con el dedito", "tararea una melodía inventada"],
}
const SMART := ["repasa cuentas en su cabeza", "ordena sus pensamientos", "recuerda lo que aprendió hoy"]
const JUST_DID := {
	"fed": "mastica contento", "drank": "se relame después de beber", "bathed": "se sacude las gotitas",
	"petted": "disfruta de los mimos", "played": "practica lo que aprendió",
}
# Cuanto dura el "recien hizo algo" (segundos).
const JUST_SECONDS := 120.0


static func _pick(rng: RandomNumberGenerator, list: Array) -> String:
	return list[rng.randi() % list.size()]


static func _place(room: int) -> String:
	return Rooms.place_name(room).substr(3)   # "en la sala" -> "la sala"


static func _poss(id: String) -> String:
	var name: String = Catalog.get_item(id).get("name", id)
	return ("a sus " if name.split(" ")[0] in ["Lentes", "Cubos"] else "a su ") + name.to_lower()


## `ctx` es el mismo de PomponThoughts ("now", "hour", "room", "items", "events"...).
static func walking(p: Pompon, ctx: Dictionary, rng: RandomNumberGenerator) -> String:
	var stage := p.stage_index(int(ctx["now"]))
	var line := _pick(rng, BABY_WALK if stage <= 1 else GROWN_WALK) % _place(int(ctx.get("room", 0)))
	return "%s %s" % [p.display_name(), line]


static func idle(p: Pompon, ctx: Dictionary, rng: RandomNumberGenerator, last := "") -> String:
	var now := int(ctx["now"])
	var stage := p.stage_index(now)
	var room := int(ctx.get("room", 0))
	var pool: Array = []
	# lo que acaba de pasar tiene prioridad
	var events: Dictionary = ctx.get("events", {})
	for ev in JUST_DID:
		var t := int(events.get(ev, 0))
		if t > 0 and float(now - t) <= (300.0 if ev == "played" else JUST_SECONDS):
			pool.append(JUST_DID[ev])
			pool.append(JUST_DID[ev])
	var hour: float = ctx["hour"]
	if hour >= 21.0 or hour < 6.0:
		pool.append_array(["bosteza grande", "cabecea de sueño", "se acurruca", "mira por la ventana soñoliento"] if stage > 1 else ["bosteza", "cabecea de sueño"])
	if float(p.stats.get("alimentacion", 100.0)) < 40.0:
		pool.append("mira hacia donde suele estar la comida")
	if float(p.stats.get("diversion", 100.0)) < 40.0:
		pool.append("busca algo para jugar")
	if stage <= 1:
		pool.append_array(BABY)
		pool.append("mira %s con curiosidad" % _place(room))
		for id in ctx.get("items", []):
			if id != "furn_crib":
				pool.append("mira %s sin parpadear" % _poss(id))
				break
	else:
		pool.append_array(GROWN)
		pool.append("mira %s" % _place(room))
		pool.append_array(PERSONALITY.get(p.personality, []))
		if float(p.stats.get("inteligencia", 0.0)) >= 5.0:
			pool.append_array(SMART)
		var items: Array = ctx.get("items", [])
		if not items.is_empty():
			var id: String = items[rng.randi() % items.size()]
			if id != "furn_crib":
				pool.append("mira %s con atención" % _poss(id))
	if pool.size() > 1:
		pool = pool.filter(func(x): return x != last)
	return "%s %s" % [p.display_name(), _pick(rng, pool)]
