class_name PomponFirsts
extends RefCounted
## Primeras veces: cuando el Pompon prueba o hace algo nuevo (una comida, su primer baño, un juego,
## el piano, una prenda, una habitacion, un vecino) lo anota en su diario contando como se sintio.
## La primera vez se anota SIEMPRE; las siguientes cada vez menos y con una pausa entre una y otra,
## para que el diario no se llene. Se guarda en `Pompon.tastes["firsts"]` (veces por cosa).

const REPEAT_GAP := 480            # segundos minimos entre dos entradas de "otra vez"
# Probabilidad de anotar la vez numero 2, 3, 4-6 y 7 en adelante.
const REPEAT_CHANCE := [0.45, 0.3, 0.12, 0.04]

# Por tipo: texto de la primera vez, de otra vez y como se sintio (al azar). {x} = la cosa, {a} = a/o.
const TEXTS := {
	"bath": {"stat": "aseo",
		"first": "Hoy tuve mi primer baño y {r}",
		"first_r": ["el agua estaba calentita", "me dio un poquito de frío", "me asusté con las burbujas",
			"¡me encantaron las burbujas!", "quedé oliendo a flores"],
		"again": "Otro baño: {r}",
		"again_r": ["ya no me asusta el agua", "¡qué rica el agua tibia!", "jugué con la espuma", "quedé suavecit{a}"]},
	"drink": {"stat": "hidratacion",
		"first": "Hoy tomé agua de mi tazón por primera vez: {r}",
		"first_r": ["¡qué fresquita!", "me mojé un poco la nariz", "glup glup, ¡rica!"],
		"again": "Agüita otra vez: {r}",
		"again_r": ["¡fresquita!", "me encanta mi tazón", "glup glup"]},
	"pet": {"stat": "amor",
		"first": "Hoy me hiciste mi primer mimo y {r}",
		"first_r": ["me sentí muy querid{a}", "me dio cosquillas", "me puse colorad{a}"],
		"again": "Otro mimo: {r}",
		"again_r": ["me encantan tus mimos", "me quedé dormid{a} un ratito", "¡cosquillitas!"]},
	"game": {"stat": "diversion",
		"first": "Hoy jugué a {x} por primera vez y {r}",
		"first_r": ["¡estuvo súper!", "me costó un poquito", "¡quiero jugar otra vez!", "aprendí algo nuevo"],
		"again": "Jugamos a {x} otra vez: {r}",
		"again_r": ["¡cada vez me sale mejor!", "¡qué divertido!", "me costó, pero lo logré"]},
	"item": {"stat": "felicidad",
		"first": "Hoy probé {x} por primera vez y {r}",
		"first_r": ["¡estuvo súper!", "hice un poco de lío", "¡me encantó!", "no sabía cómo se usaba, pero aprendí"],
		"again": "Volví a usar {x}: {r}",
		"again_r": ["cada vez me sale mejor", "¡qué divertido!", "me quedé un rato largo"]},
	"wear": {"stat": "felicidad",
		"first": "Hoy estrené {x}: {r}",
		"first_r": ["¡me siento muy lind{a}!", "me queda un poquito grande", "¡me encanta!", "me miré en el espejo un rato"],
		"again": "Me puse {x} otra vez: {r}",
		"again_r": ["me sigue encantando", "me queda genial"]},
	"room": {"stat": "comodidad",
		"first": "Hoy conocí {x}: {r}",
		"first_r": ["¡es enorme!", "huele a nuevo", "me dio un poquito de miedo", "¡me encantó!"]},
	"sleep": {"stat": "sueno",
		"first": "Hoy dormí por primera vez en mi camita: {r}",
		"first_r": ["soñé cosas lindas", "me dio un poquito de miedo la oscuridad", "estaba muy calentit{a}", "¡qué rico se duerme!"]},
	"friend": {"stat": "amistad",
		"first": "Hoy conocí a {x}: {r}",
		"first_r": ["al principio me dio vergüenza", "nos olimos y ya somos amigos", "¡me cayó muy bien!"],
		"again": "Volví a ver a {x}: {r}",
		"again_r": ["¡nos divertimos mucho!", "cada vez somos más amigos", "me contó un secreto"]},
}
# La comida depende de si le gusto: [le gusta, no sabe, no le gusta].
const FOOD_FIRST := "Hoy probé {x} por primera vez y {r}"
const FOOD_FIRST_R := [["¡me encantó!", "¡quiero más!", "¡fue una sorpresa riquísima!"],
	["me dio un poquito de desconfianza", "sabía raro… pero lo voy a volver a probar", "no sé si me gustó"],
	["no me convenció mucho", "hice una carita rara"]]
const FOOD_AGAIN := "Comí {x} otra vez: {r}"
const FOOD_AGAIN_R := [["cada vez me gusta más", "¡ñam ñam!", "ya es de mis favoritas"],
	["todavía no sé si me gusta", "me estoy acostumbrando"],
	["todavía no me acostumbro", "prefiero otra cosa…"]]
const ROOM_NAMES := ["la sala", "el dormitorio", "la cocina", "la biblioteca", "el jardín", "la terraza estelar"]


static func _data(p: Pompon) -> Dictionary:
	if not p.tastes.has("firsts"):
		p.tastes["firsts"] = {}
	return p.tastes["firsts"]


## Cuantas veces hizo esa cosa (`kind:subject`).
static func times(p: Pompon, kind: String, subject := "") -> int:
	return int(_data(p).get("%s:%s" % [kind, subject], 0))


## Cuenta una vez mas `kind` con `subject` y devuelve la entrada del diario ({} si esta vez no se anota).
## `label` = como se nombra la cosa en el texto; `liking` (solo comida): 1 le gusta, 0 no sabe, -1 no.
static func experience(p: Pompon, kind: String, subject: String, label: String, now: int, rng: RandomNumberGenerator, liking := 0) -> Dictionary:
	if p == null or not p.hatched:
		return {}
	var d := _data(p)
	var key := "%s:%s" % [kind, subject]
	var count := int(d.get(key, 0)) + 1
	d[key] = count
	if count == 1:  # cuando fue (para el album de recuerdos)
		if not p.tastes.has("firsts_at"):
			p.tastes["firsts_at"] = {}
		p.tastes["firsts_at"][key] = now
	var info: Dictionary = TEXTS.get(kind, {})
	if count > 1:
		if kind != "food" and not info.has("again"):
			return {}   # (habitaciones: solo la primera vez)
		if now - int(p.tastes.get("firsts_last", 0)) < REPEAT_GAP:
			return {}
		var chance: float = REPEAT_CHANCE[0 if count == 2 else (1 if count == 3 else (2 if count <= 6 else 3))]
		if rng.randf() >= chance:
			return {}
		p.tastes["firsts_last"] = now
	var text := ""
	var stat := "alimentacion"
	if kind == "food":
		var pool: Array = (FOOD_FIRST_R if count == 1 else FOOD_AGAIN_R)[1 - clampi(liking, -1, 1)]
		text = T.s(FOOD_FIRST if count == 1 else FOOD_AGAIN).replace("{r}", T.s(pool[rng.randi() % pool.size()]))
	else:
		var pool2: Array = info["first_r" if count == 1 else "again_r"]
		text = T.s(String(info["first" if count == 1 else "again"])).replace("{r}", T.s(pool2[rng.randi() % pool2.size()]))
		stat = info["stat"]
	text = text.replace("{x}", label).replace("{a}", "a" if p.sex == "Hembra" else "o")
	if text.contains("{"):
		text = text.format(T.pron(p.sex))
	return {"kind": "sentimiento", "text": text, "stat": stat, "key": "first:" + key}


static func room_label(i: int) -> String:
	return T.s(ROOM_NAMES[clampi(i, 0, ROOM_NAMES.size() - 1)])
