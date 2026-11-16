class_name PomponThoughts
extends RefCounted
## Lo que el Pompon piensa, siente y dice: cada tanto sale una entrada nueva que queda guardada en su
## diario (GameState.journal). Todo sale de la realidad del juego: sus necesidades, la hora, la habitacion
## donde esta, los muebles que tiene, la ropa puesta, lo que hicieron juntos hace poco y su etapa de vida.
##
## Una entrada es {"kind": pensamiento|sentimiento|frase, "text", "stat" (para el icono), "key"}.
## `ctx` (lo arma la casa): {"now", "hour", "room", "items": ids puestos en la habitacion,
## "on_pairs": [[adorno, mueble]], "equipped", "events": suceso -> ultima vez, "jobs_done", "level"}.

const KIND_THINK := "pensamiento"
const KIND_FEEL := "sentimiento"
const KIND_SAY := "frase"
const KIND_VERBS := {"pensamiento": "pensó", "sentimiento": "sintió", "frase": "dijo"}

# {a} = "a" o "o" segun el sexo del Pompon.
const NEED_TEXT := {
	"alimentacion": {"mid": ["Tengo un poco de hambre", "Mi pancita empieza a hacer ruido"],
		"high": ["¡Tengo muchísima hambre!", "Necesito comer ya, por favor"]},
	"hidratacion": {"mid": ["Tengo un poco de sed", "Un traguito de agua me vendría bien"],
		"high": ["¡Tengo mucha sed!", "Necesito agua, por favor"]},
	"aseo": {"mid": ["Me gustaría estar más limpi{a}", "Siento que me falta un baño"],
		"high": ["Necesito un baño urgente", "Estoy muy suci{a}"]},
	"diversion": {"mid": ["Me estoy aburriendo un poquito", "¿Jugamos a algo?"],
		"high": ["¡Estoy muy aburrid{a}!", "Necesito jugar ya"]},
	"comodidad": {"mid": ["No estoy muy cómod{a} acá", "Creo que me falta algo en casa"], "high": []},
	"sueno": {"mid": ["Tengo un poquito de sueño", "*bosteza* ¿Ya es hora de dormir?"],
		"high": ["¡Tengo muchísimo sueño!", "Se me cierran los ojitos…"]},
	"amor": {"mid": ["Quiero un poco de cariño", "¿Me das un mimo?"],
		"high": ["Me siento solit{a}", "¿Todavía me quieres?"]},
	"amistad": {"mid": ["Extraño a mis amigos", "Me gustaría visitar a mis vecinos"], "high": []},
	"inteligencia": {"mid": ["Quiero aprender cosas nuevas", "Me gustaría aprender algo hoy"], "high": []},
}
const NEED_BABY := {"alimentacion": "hambre", "hidratacion": "sed", "aseo": "baño", "diversion": "jugar",
	"comodidad": "incomodidad", "sueno": "sueño", "amor": "mimos", "amistad": "amigos", "inteligencia": "aprender"}
const GOOD_TEXT := {
	"alimentacion": "Qué rica estuvo la comida",
	"aseo": "Me siento limpit{a} y perfumad{a}",
	"diversion": "¡Me divertí un montón!",
	"comodidad": "Qué cómod{a} estoy en casa",
	"sueno": "Dormí riquísimo y tengo mucha energía",
	"amor": "Me siento muy querid{a}",
	"amistad": "Tengo muchos amigos, ¡qué suerte!",
	"inteligencia": "Cada día entiendo más cosas",
}
const ROOM_TEXT := {
	"sala": ["Me gusta la sala, es tranquila", "Desde la sala se ve toda la casa"],
	"dormitorio": ["Acá se duerme riquísimo", "El dormitorio es mi rincón favorito"],
	"cocina": ["La cocina huele a galletitas", "En la cocina siempre pasa algo rico"],
	"biblioteca": ["Shh… en la biblioteca se piensa mejor", "Quiero leer algo en la biblioteca"],
	"jardin": ["¡Me encanta el pasto del jardín!", "En el jardín me dan ganas de correr"],
	"terraza": ["Desde la terraza se ven las estrellas", "La terraza estelar es mágica"],
}
const REACTIONS := {
	"fed": ["¡Ñam! Estaba riquísimo", "Mi pancita está contenta", "Gracias por la comida"],
	"drank": ["Glup glup… ¡qué fresquita!", "Qué rica el agua"],
	"bathed": ["Estoy limpit{a} y perfumad{a}", "El baño me dejó como nuev{a}"],
	"petted": ["Me encantan tus mimos", "Quédate un ratito más"],
	"played": ["¡Creo que aprendí algo nuevo!", "Jugar me hace sentir más list{a}"],
	"worked": ["¡Qué bueno que volviste! Te esperé", "Me alegra que trabajes para cuidarme"],
	"bought": ["¡Qué lindo, algo nuevo para la casa!", "¿Es para mí? ¡Gracias!"],
	"room_changed": ["Me gusta cambiar de lugar", "¡Qué lindo se ve todo por acá!"],
	"visited": ["Visitar a mis vecinos fue lindo", "Hice nuevos amigos hoy"],
	"levelup": ["¡Crecí un poquito!", "Cada día soy un poco más grande"],
}
const REACTION_STAT := {"fed": "alimentacion", "drank": "hidratacion", "bathed": "aseo", "petted": "amor", "played": "inteligencia",
	"worked": "felicidad", "bought": "felicidad", "room_changed": "comodidad", "visited": "amistad", "levelup": "felicidad"}
const REACTION_KIND := {"fed": KIND_SAY, "drank": KIND_SAY, "bathed": KIND_SAY, "petted": KIND_SAY, "played": KIND_FEEL,
	"worked": KIND_FEEL, "bought": KIND_FEEL, "room_changed": KIND_THINK, "visited": KIND_FEEL, "levelup": KIND_FEEL}
const PLURAL_START := ["Lentes", "Cubos", "Almohadones", "Velas", "Estrellas"]
const DREAMS := ["Soñé que volaba entre nubes de algodón", "Soñé con una montaña de galletitas",
	"Soñé que jugaba a la pelota con mis amigos", "Soñé que nadaba con pececitos de colores",
	"Soñé que la luna me contaba un cuento", "Soñé que mi casa era un castillo de almohadas",
	"Soñé que encontraba un tesoro en el jardín", "Soñé que bailábamos bajo las estrellas"]


static func _vowel(p: Pompon) -> String:
	return "a" if p.sex == "Hembra" else "o"


## La frase en el idioma actual (las fijas se traducen aca; las armadas con %s ya vienen traducidas).
static func _entry(p: Pompon, kind: String, text: String, stat: String, key: String, weight := 1.0) -> Dictionary:
	var out := T.s(text).replace("{a}", _vowel(p))
	if out.contains("{"):
		out = out.format(T.pron(p.sex))
	return {"kind": kind, "text": out, "stat": stat, "key": key, "w": weight}


## "mi sofá" / "mis lentes redondos" ("my sofa" en inglés).
static func _poss(item_id: String) -> String:
	if T.lang() == "en":
		return "my " + Catalog.item_name(item_id).to_lower()
	var name: String = Catalog.get_item(item_id).get("name", item_id)
	var first := name.split(" ")[0]
	return ("mis " if first in PLURAL_START else "mi ") + name.to_lower()


## Nivel de necesidad: 2 = urgente, 1 = atencion, 0 = bien (los mismos limites que PomponMood).
static func need_level(stat: String, v: float) -> int:
	match stat:
		"alimentacion", "hidratacion", "aseo", "diversion":
			return 2 if v < 25.0 else (1 if v < 55.0 else 0)
		"comodidad":
			return 1 if v < 40.0 else 0
		"sueno":
			return 2 if v < 20.0 else (1 if v < 40.0 else 0)
		"amor":
			return 2 if v < 30.0 else (1 if v < 55.0 else 0)
		"amistad":
			return 1 if v < 20.0 else 0
		"inteligencia":
			return 1 if v < 15.0 else 0
	return 0


static func _is_night(hour: float) -> bool:
	return hour >= 21.0 or hour < 6.0


static func _recent(ctx: Dictionary, event: String, within_seconds: float) -> bool:
	var t: int = int(ctx.get("events", {}).get(event, 0))
	return t > 0 and float(int(ctx["now"]) - t) <= within_seconds


# ---------------------------------------------------------------- necesidades y sentimientos

static func _pick(rng: RandomNumberGenerator, list: Array) -> String:
	return list[rng.randi() % list.size()]


static func _needs(p: Pompon, rng: RandomNumberGenerator, baby: bool, out: Array) -> void:
	for stat in NEED_TEXT:
		if baby and stat in ["amistad", "inteligencia"]:
			continue  # un bebe todavia no extraña amigos ni quiere aprender
		var lvl := need_level(stat, float(p.stats.get(stat, 100.0)))
		if lvl == 0:
			continue
		var lines: Array = NEED_TEXT[stat]["high" if lvl >= 2 else "mid"]
		if lines.is_empty():
			lines = NEED_TEXT[stat]["mid"] if not NEED_TEXT[stat]["mid"].is_empty() else NEED_TEXT[stat]["high"]
		if baby:
			var sound := _pick(rng, ["Buaaa…", "Pi… pi…", "T_T"])
			out.append(_entry(p, KIND_FEEL, "%s (%s)" % [sound, T.s(NEED_BABY[stat])], stat, "need:" + stat, 12.0 if lvl >= 2 else 4.0))
		else:
			for line in lines:
				out.append(_entry(p, KIND_FEEL, line, stat, "need:" + stat, (12.0 if lvl >= 2 else 4.0) / lines.size()))


static func _goods(p: Pompon, baby: bool, out: Array) -> void:
	var thresholds := {"alimentacion": 85.0, "aseo": 85.0, "diversion": 80.0, "comodidad": 80.0, "sueno": 85.0,
		"amor": 80.0, "amistad": 70.0, "inteligencia": 60.0}
	for stat in GOOD_TEXT:
		if float(p.stats.get(stat, 0.0)) >= thresholds[stat]:
			if baby:
				out.append(_entry(p, KIND_FEEL, "Pi pi! :)", stat, "good:" + stat, 1.2))
			else:
				out.append(_entry(p, KIND_FEEL, GOOD_TEXT[stat], stat, "good:" + stat, 1.2))


# ---------------------------------------------------------------- contexto (hora, casa, ropa, recuerdos)

static func _context(p: Pompon, ctx: Dictionary, rng: RandomNumberGenerator, out: Array) -> void:
	var hour: float = ctx["hour"]
	var night := _is_night(hour)
	var items: Array = ctx.get("items", [])
	var room: int = clampi(int(ctx.get("room", 0)), 0, Rooms.count() - 1)
	if night:
		out.append(_entry(p, KIND_THINK, "Ya es de noche… ¿mañana jugamos otra vez?", "comodidad", "night1", 1.6))
		out.append(_entry(p, KIND_SAY, "Qué sueño tengo", "comodidad", "night2", 1.4))
		if items.has("deco_window") or room == 5:
			out.append(_entry(p, KIND_THINK, "Las estrellas se ven hermosas esta noche", "felicidad", "night3", 1.6))
	elif hour < 12.0:
		out.append(_entry(p, KIND_SAY, "¡Buen día! Hoy quiero hacer algo lindo", "felicidad", "morning", 1.4))
	elif hour < 19.0:
		out.append(_entry(p, KIND_THINK, "Qué linda tarde para jugar", "diversion", "afternoon", 1.2))
	for line in ROOM_TEXT[Rooms.LIST[room]["id"]]:
		out.append(_entry(p, KIND_THINK, line, "comodidad", "room:%d:%s" % [room, line], 1.0))
	for id in items:
		if id == "furn_crib" or (Catalog.get_item(id).get("category", "") == "deco" and not Catalog.is_small(id)):
			continue
		out.append(_entry(p, KIND_THINK, _item_line(p, rng, id), "comodidad", "item:" + id, 0.7))
	for pair in ctx.get("on_pairs", []):
		out.append(_entry(p, KIND_THINK, T.s("Quedó lindo %s sobre %s") % [_poss(pair[0]), _poss(pair[1])], "felicidad", "on:%s:%s" % [pair[0], pair[1]], 1.4))
	var eq: Dictionary = ctx.get("equipped", {})
	for cat in ["hat", "shirt", "glasses"]:
		if eq.has(cat):
			out.append(_entry(p, KIND_SAY, T.s("Me siento especial con %s") % _poss(eq[cat]), "felicidad", "wear:" + str(eq[cat]), 1.1))
	for line in PomponSpeech.PERSONALITY_LINES.get(p.personality, []):
		out.append(_entry(p, KIND_SAY, line, "felicidad", "pers:" + line, 0.9))
	# gustos que fue aprendiendo (ver PomponTastes)
	var fav_color := PomponTastes.favorite_color(p)
	if fav_color != "":
		out.append(_entry(p, KIND_THINK, T.s("Me encantan las cosas de color %s") % PomponTastes.color_name(fav_color), "felicidad", "taste:color", 1.3))
	var fav_food := PomponTastes.favorite_food(p)
	if fav_food != "":
		var food_name := PomponTastes.food_name(fav_food).to_lower()
		var hungry := float(p.stats.get("alimentacion", 100.0)) < 60.0
		out.append(_entry(p, KIND_FEEL, (T.s("Me comería %s ahora mismo") if hungry else T.s("Qué ganas de comer %s")) % food_name, "alimentacion", "taste:food", 2.5 if hungry else 1.2))
	var fav_game := PomponTastes.favorite_game(p)
	if fav_game != "":
		out.append(_entry(p, KIND_THINK, T.s("Me gustaría jugar a %s") % PomponTastes.game_name(fav_game), "diversion", "taste:game", 1.1))
	if not PomponTastes.FOODS.filter(func(f): return PomponTastes.is_new_food(p, f["id"])).is_empty():
		out.append(_entry(p, KIND_THINK, "Me da curiosidad probar comidas nuevas", "alimentacion", "taste:new", 0.7))
	if p.stage_index(int(ctx["now"])) <= 2:
		out.append(_entry(p, KIND_THINK, "Cada día descubro cosas que me gustan", "felicidad", "taste:grow", 0.8))
	if float(p.stats.get("inteligencia", 0.0)) >= 5.0:
		for line in PomponSpeech.SMART_LINES:
			out.append(_entry(p, KIND_THINK, line, "inteligencia", "smart:" + line, 1.0))
	if _recent(ctx, "worked", 86400.0):
		out.append(_entry(p, KIND_THINK, "Me alegra que trabajes para cuidarme, ¡gracias!", "felicidad", "ev:worked", 2.2))
	if _recent(ctx, "played", 43200.0):
		out.append(_entry(p, KIND_THINK, "Me divertí mucho con los juegos de antes", "diversion", "ev:played", 2.0))
		if float(p.stats.get("inteligencia", 0.0)) > 0.0:
			out.append(_entry(p, KIND_THINK, "Creo que aprendí algo nuevo jugando", "inteligencia", "ev:played2", 1.8))
	if _recent(ctx, "visited", 86400.0):
		out.append(_entry(p, KIND_FEEL, "Visitar a mis vecinos fue muy lindo", "amistad", "ev:visited", 2.0))
	if _recent(ctx, "bought", 86400.0):
		out.append(_entry(p, KIND_FEEL, "¿Viste lo que compramos? ¡Me encanta!", "felicidad", "ev:bought", 2.0))
	if _recent(ctx, "petted", 7200.0):
		out.append(_entry(p, KIND_FEEL, "Las caricias me hacen muy feliz", "amor", "ev:petted", 1.5))
	var level: int = int(ctx.get("level", 1))
	out.append(_entry(p, KIND_THINK, T.s("Hoy es mi día %d de vida") % level, "felicidad", "day:%d" % level, 1.2))
	if int(ctx.get("jobs_done", 0)) >= 3:
		out.append(_entry(p, KIND_THINK, T.s("Ya trabajaste %d veces para cuidarme, ¡gracias!") % int(ctx["jobs_done"]), "felicidad", "jobs:%d" % int(ctx["jobs_done"]), 1.0))


static func _item_line(p: Pompon, rng: RandomNumberGenerator, id: String) -> String:
	var mine := _poss(id)
	return _cap(_pick(rng, [T.s("%s es lo mejor de la casa"), T.s("Hoy me quedé mirando %s")]) % mine)


static func _cap(text: String) -> String:
	return text.substr(0, 1).to_upper() + text.substr(1)


## Una entrada espontanea para este momento (o {} si no hay nada nuevo que decir).
## `recent_texts`: lo ultimo que ya dijo, para no repetirse.
static func spontaneous(p: Pompon, ctx: Dictionary, recent_texts: Array, rng: RandomNumberGenerator) -> Dictionary:
	var stage := p.stage_index(int(ctx["now"]))
	if stage == 0:
		return {}
	if ctx.get("sleeping", false):  # dormido: en lugar de pensar, sueña
		if stage == 1:
			return _clean(_entry(p, KIND_FEEL, "Zzz… (sueña algo lindo)", "sueno", "dream:baby"))
		var dreams := DREAMS.map(func(d): return T.s(d)).filter(func(d): return not recent_texts.has(d))
		return {} if dreams.is_empty() else _clean(_entry(p, KIND_FEEL, _pick(rng, dreams), "sueno", "dream"))
	var baby := stage == 1
	var cands: Array = []
	_needs(p, rng, baby, cands)
	_goods(p, baby, cands)
	if baby:
		if _is_night(float(ctx["hour"])):
			cands.append(_entry(p, KIND_SAY, "Zzz… pi", "comodidad", "baby:night", 1.5))
		cands.append(_entry(p, KIND_SAY, _pick(rng, ["Pi pi!", "Mmm~", "^_^", "<3"]), "felicidad", "baby:" + str(rng.randi() % 4), 0.8))
	else:
		_context(p, ctx, rng, cands)
	cands = cands.filter(func(c): return not recent_texts.has(c["text"]))
	return _weighted(cands, rng)


static func _weighted(cands: Array, rng: RandomNumberGenerator) -> Dictionary:
	if cands.is_empty():
		return {}
	var total := 0.0
	for c in cands:
		total += float(c["w"])
	var roll := rng.randf() * total
	for c in cands:
		roll -= float(c["w"])
		if roll <= 0.0:
			return _clean(c)
	return _clean(cands[cands.size() - 1])


static func _clean(c: Dictionary) -> Dictionary:
	return {"kind": c["kind"], "text": c["text"], "stat": c["stat"], "key": c["key"]}


## Reaccion a algo que acaba de pasar ("fed", "drank", "bathed", "petted", "played", "worked", "bought",
## "room_changed", "visited", "levelup"). {} si todavia es huevo.
static func reaction(event: String, p: Pompon, ctx: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var stage := p.stage_index(int(ctx["now"]))
	if stage == 0 or not REACTIONS.has(event):
		return {}
	var stat: String = REACTION_STAT[event]
	if stage == 1:
		var sound := "¡Ñam ñam!" if event == "fed" else _pick(rng, ["Pi pi! :)", "^_^", "<3"])
		return _clean(_entry(p, KIND_SAY, sound, stat, "re:" + event))
	var text: String = _pick(rng, REACTIONS[event])
	if event == "room_changed":
		text = T.s("Me gusta estar %s") % Rooms.place_name(int(ctx.get("room", 0)))
	return _clean(_entry(p, REACTION_KIND[event], text, stat, "re:" + event))


## Cuando una necesidad se vuelve urgente: lo dice enseguida (la casa limita cada cuanto).
static func urgent(p: Pompon, stat: String, now: int, rng: RandomNumberGenerator) -> Dictionary:
	var stage := p.stage_index(now)
	if stage == 0 or not NEED_TEXT.has(stat):
		return {}
	var lines: Array = NEED_TEXT[stat]["high"]
	if lines.is_empty():
		lines = NEED_TEXT[stat]["mid"]
	if stage == 1:
		return _clean(_entry(p, KIND_FEEL, "%s (%s)" % [_pick(rng, ["Buaaa…", "Pi… pi…"]), T.s(NEED_BABY[stat])], stat, "urgent:" + stat))
	return _clean(_entry(p, KIND_FEEL, _pick(rng, lines), stat, "urgent:" + stat))


## Lo primero que siente al nacer (pasos 1 a 3, con unos minutos entre uno y otro): sorpresa, curiosidad y carinio.
static func birth(p: Pompon, step: int) -> Dictionary:
	match step:
		1:
			return _clean(_entry(p, KIND_FEEL, "¡Acabo de nacer! Todo es nuevo y me siento muy curios{a}", "felicidad", "birth1"))
		2:
			return _clean(_entry(p, KIND_THINK, "¿Quién será esa persona que me cuida? Quiero conocerla…", "amor", "birth2"))
		3:
			return _clean(_entry(p, KIND_SAY, "Pi pi… ¡ba!", "felicidad", "birth3"))   # todavia no sabe decir palabras
	return {}


## Al volver despues de un buen rato: te extrañó y cuenta como esta.
static func welcome_back(p: Pompon, now: int, away_seconds: int, rng: RandomNumberGenerator) -> Dictionary:
	var stage := p.stage_index(now)
	if stage == 0 or away_seconds < 3 * 3600:
		return {}
	if stage == 1:
		return _clean(_entry(p, KIND_FEEL, "Pi pi! <3", "amor", "back"))
	var hours := away_seconds / 3600
	var text := T.s("¡Volviste! Te extrañé") if hours < 24 else T.s("¡Volviste! Pasó mucho tiempo, te extrañé muchísimo")
	if float(p.stats.get("alimentacion", 100.0)) < 40.0:
		text += T.s(" (y tengo hambre)")
	return _clean(_entry(p, KIND_FEEL, text, "amor", "back"))
