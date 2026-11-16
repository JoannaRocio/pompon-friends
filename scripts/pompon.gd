class_name Pompon
extends RefCounted
## Datos de un Pompon: genética fija + estadísticas (0 a 100) + etapa de vida.

const SPECIES := ["Reptil", "Canino", "Felino", "Conejo", "Raton", "Ave", "Dragon"]
const SEX := ["Hembra", "Macho"]
const PERSONALITIES := ["Energico", "Timido", "Curioso", "Gloton", "Artistico"]
const EYE_SHAPES := ["redondos", "ovalados", "brillantes", "tiernos"]   # siempre abiertos (parpadean)
const MOUTH_SHAPES := ["sonrisa", "pico", "colmillitos", "bigotes"]
const FACE_SHAPES := ["redonda", "ovalada", "ancha"]
## Nombres tiernos para el Pompon ("Otro nombre"; los menores de 13 solo pueden elegir de aca).
const NAME_IDEAS := ["Pompi", "Mochi", "Copito", "Bombón", "Canela", "Tofu", "Mimi", "Coco", "Kiwi", "Pelusa",
	"Lila", "Duki", "Chipa", "Muffin", "Pepita", "Ñoqui", "Nacho", "Dulce", "Bolita", "Galleta",
	"Churro", "Waffle", "Panqueque", "Frutilla", "Moca", "Turrón", "Merengue", "Pochoclo", "Caramelo", "Cupcake",
	"Nubecita", "Bizcocho", "Alfajor", "Mazapán", "Rosquita", "Polvorón", "Avellana", "Pistacho", "Tapioca", "Brownie"]

const STAGES := ["Huevo", "Bebé", "Niño", "Adolescente", "Adulto"]
# Duracion de cada etapa en segundos (el adulto no termina).
const STAGE_SECONDS := [0, 7 * 86400, 14 * 86400, 30 * 86400]   # el huevo nace al comprar la cuna (no por tiempo)
const ABANDON_SECONDS := 30 * 86400
# El Pompon sube de nivel cada dia (nivel = dia de vida). Nivel en el que empieza cada etapa:
# Bebe (1-7), Niño (8-21), Adolescente (22-51), Adulto (52 en adelante).
const STAGE_START_LEVEL := [0, 1, 8, 22, 52]

# Puntos que baja cada estadistica por hora. Inteligencia nunca baja. Sueño va aparte (ver _advance_sleep).
const DECAY_PER_HOUR := {
	"alimentacion": 4.0,
	"hidratacion": 5.0,
	"aseo": 2.5,
	"diversion": 3.0,
	"comodidad": 1.0,
	"amor": 1.0,
	"amistad": 0.5,
}
const STAT_NAMES := [
	"alimentacion", "hidratacion", "aseo", "diversion", "comodidad",
	"sueno", "amor", "amistad", "inteligencia",
]
# Sueño: de dia baja; de noche (22 a 8 h, hora del jugador) duerme y se recupera, mas rapido si tiene
# una cama de verdad en su cuarto. (Reemplaza a la vieja "felicidad".)
const SLEEP_DRAIN := 5.0
const SLEEP_REST := 11.0
const SLEEP_REST_COZY := 15.0
const COZY_FLOOR := 50.0   # con un mueble para descansar, la comodidad no baja de aca aunque no juegue

var id := ""
var nickname := ""          # el nombre que le pone el jugador cuando nace
var hatched := true         # false: sigue siendo un huevo (nace al comprarle la cuna)
var species := ""
var sex := ""
var personality := ""
var color_primary := Color.WHITE
var color_secondary := Color.WHITE
var eyes := ""
var mouth := ""
var face := ""
var born_at := 0
var neglect_seconds := 0.0
var stats := {}
var tastes := {}            # gustos y rasgos que va aprendiendo (ver PomponTastes)
var growth := {}            # calidad de crecimiento, palabras y rasgos ganados (ver PomponGrowth)


const SPECIES_LABELS := {"Raton": "Ratón", "Dragon": "Dragón"}
const PERSONALITY_LABELS := {"Energico": "Enérgico", "Timido": "Tímido", "Gloton": "Glotón", "Artistico": "Artístico"}


## Nombres para mostrar (con tildes); los internos siguen sin ellas.
static func species_label(s: String) -> String:
	return T.label(SPECIES_LABELS.get(s, s))


static func personality_label(s: String) -> String:
	return T.label(PERSONALITY_LABELS.get(s, s))


## Crea un Pompon nuevo. La especie la elige el jugador (si no se indica, sale una al azar);
## el sexo, los colores, las facciones y la personalidad son siempre una sorpresa.
static func generate(chosen_species := "", chosen_sex := "") -> Pompon:
	var p := Pompon.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	p.id = "#POMPON-%04d" % rng.randi_range(0, 9999)
	p.species = chosen_species if chosen_species in SPECIES else SPECIES[rng.randi() % SPECIES.size()]
	p.sex = chosen_sex if chosen_sex in SEX else SEX[rng.randi() % SEX.size()]
	p.hatched = false
	p.personality = PERSONALITIES[rng.randi() % PERSONALITIES.size()]
	p.color_primary = Color.from_hsv(rng.randf(), rng.randf_range(0.25, 0.55), rng.randf_range(0.85, 1.0))
	p.color_secondary = Color.from_hsv(rng.randf(), rng.randf_range(0.1, 0.3), rng.randf_range(0.92, 1.0))
	p.eyes = EYE_SHAPES[rng.randi() % EYE_SHAPES.size()]
	p.mouth = MOUTH_SHAPES[rng.randi() % MOUTH_SHAPES.size()]
	p.face = FACE_SHAPES[rng.randi() % FACE_SHAPES.size()]
	p.born_at = int(Time.get_unix_time_from_system())
	for s in STAT_NAMES:
		p.stats[s] = 100.0 if s != "inteligencia" and s != "amistad" else 0.0
	p.stats["amor"] = 50.0
	PomponTastes.ensure(p)
	return p


## Su nombre, o su ID mientras no tenga uno.
func display_name() -> String:
	return nickname if nickname != "" else id


## El huevo nace (cuando el jugador le compra la cuna).
func hatch(now: int) -> void:
	hatched = true
	born_at = now


func age_seconds(now: int) -> int:
	return maxi(0, now - born_at)


func stage_index(now: int) -> int:
	if not hatched:
		return 0  # el huevo no nace solo: espera su cuna
	var age := age_seconds(now)
	var acc := 0
	for i in STAGE_SECONDS.size():
		acc += STAGE_SECONDS[i]
		if age < acc:
			return i
	return STAGES.size() - 1


## Dia de vida (0 el primer dia). El huevo todavia no tiene.
func days_alive(now: int) -> int:
	return 0 if not hatched else age_seconds(now) / 86400


## Nivel = dia de vida (Nivel 1 el dia que nace). 0 si todavia es huevo.
func level(now: int) -> int:
	return 0 if not hatched else days_alive(now) + 1


## Nivel al que llega la proxima etapa (o -1 si ya es adulto).
func next_stage_level(now: int) -> int:
	var lv := level(now)
	for start in STAGE_START_LEVEL:
		if start > lv:
			return start
	return -1


## Nombre de la etapa que empieza en ese nivel.
static func stage_name_for_level(lv: int) -> String:
	var idx := 0
	for i in STAGE_START_LEVEL.size():
		if lv >= STAGE_START_LEVEL[i]:
			idx = i
	return STAGES[idx]


func stage_name(now: int) -> String:
	return STAGES[stage_index(now)]


## Sueño en el tiempo que paso: se reparte por hora (lo que cayo de noche descansa, lo de dia cansa).
func _advance_sleep(seconds: float, cozy: bool) -> void:
	var t := float(Time.get_unix_time_from_system()) - seconds
	var left := seconds
	var v := float(stats.get("sueno", 80.0))
	while left > 0.0:
		var step := minf(left, 900.0)
		var rate := -SLEEP_DRAIN
		if DayClock.is_night(DayClock.hour_at(int(t + step * 0.5))):
			rate = SLEEP_REST_COZY if cozy else SLEEP_REST
		v = clampf(v + rate * step / 3600.0, 0.0, 100.0)
		t += step
		left -= step
	stats["sueno"] = v


## Aplica el paso del tiempo. Devuelve true tras ABANDON_SECONDS sin cuidados (GameState lo hace volver de lo de su abuela).
## Comodidad: baja con el tiempo y sube cuando usa los muebles de su cuarto (sentarse, acostarse,
## calentarse junto al fuego... ver PomponPlay). `cozy` = tiene donde descansar: no baja de COZY_FLOOR.
func advance(seconds: float, cozy := false) -> bool:
	if seconds <= 0.0 or not hatched:
		return false  # el huevo no tiene necesidades: no gasta nada ni se abandona
	var hours := seconds / 3600.0
	for s in DECAY_PER_HOUR:
		var floor_v := COZY_FLOOR if s == "comodidad" and cozy else 0.0
		stats[s] = clampf(stats[s] - DECAY_PER_HOUR[s] * hours, minf(floor_v, stats[s]), 100.0)
	_advance_sleep(seconds, cozy)
	# Descuido continuo: necesidades basicas en cero.
	var basics_low: bool = stats["alimentacion"] <= 0.0 or stats["hidratacion"] <= 0.0 or stats["aseo"] <= 0.0
	if basics_low:
		neglect_seconds += seconds
	else:
		neglect_seconds = 0.0
	return neglect_seconds >= ABANDON_SECONDS


## "Social": la mitad de la barra se llena con su cuidador (mimos, juegos) y la otra mitad solo
## socializando con otros Pompons. `from_carer` = viene de su cuidador: no pasa de la mitad.
const SOCIAL_CARER_CAP := 50.0


func add_social(amount: float, from_carer: bool) -> void:
	var current: float = stats.get("amistad", 0.0)
	var target := current + amount
	if from_carer:
		target = minf(target, maxf(current, SOCIAL_CARER_CAP))
	stats["amistad"] = clampf(target, 0.0, 100.0)


func add_stat(stat: String, amount: float) -> void:
	if stats.has(stat):
		stats[stat] = clampf(stats[stat] + amount, 0.0, 100.0)
		if stat in ["alimentacion", "hidratacion", "aseo"] and amount > 0.0:
			neglect_seconds = 0.0


func to_dict() -> Dictionary:
	return {
		"id": id, "nickname": nickname, "hatched": hatched, "species": species, "sex": sex, "personality": personality,
		"color_primary": color_primary.to_html(), "color_secondary": color_secondary.to_html(),
		"eyes": eyes, "mouth": mouth, "face": face,
		"born_at": born_at, "neglect_seconds": neglect_seconds, "stats": stats, "tastes": tastes, "growth": growth,
	}


static func from_dict(d: Dictionary) -> Pompon:
	var p := Pompon.new()
	p.id = d.get("id", "")
	p.nickname = str(d.get("nickname", ""))
	p.hatched = bool(d.get("hatched", true))  # partidas viejas: ya habian nacido
	p.species = d.get("species", SPECIES[0])
	p.sex = d.get("sex", SEX[0])
	p.personality = d.get("personality", PERSONALITIES[0])
	p.color_primary = Color.html(d.get("color_primary", "ffffff"))
	p.color_secondary = Color.html(d.get("color_secondary", "ffffff"))
	p.eyes = d.get("eyes", EYE_SHAPES[0])
	if not p.eyes in EYE_SHAPES:  # partidas viejas: "dormilones" (siempre cerrados) pasan a "tiernos"
		p.eyes = "tiernos"
	p.mouth = d.get("mouth", MOUTH_SHAPES[0])
	p.face = d.get("face", FACE_SHAPES[0])
	p.born_at = int(d.get("born_at", 0))
	p.neglect_seconds = float(d.get("neglect_seconds", 0.0))
	p.stats = d.get("stats", {})
	if not p.stats.has("sueno"):  # partidas de antes del Sueño: arranca descansado
		p.stats["sueno"] = 80.0
	p.stats.erase("felicidad")
	for s in STAT_NAMES:
		if not p.stats.has(s):
			p.stats[s] = 0.0
	var saved_growth = d.get("growth", {})
	p.growth = saved_growth if typeof(saved_growth) == TYPE_DICTIONARY else {}
	var saved_tastes = d.get("tastes", {})
	p.tastes = saved_tastes if typeof(saved_tastes) == TYPE_DICTIONARY else {}
	var visited: Array = []
	for r in p.tastes.get("visited", []):
		visited.append(int(r))
	if p.tastes.has("visited"):
		p.tastes["visited"] = visited
	PomponTastes.ensure(p)  # partidas viejas: le arma sus gustos de nacimiento
	return p
