class_name PomponMood
extends RefCounted
## Como se siente el Pompon, en frases cortas ("Tofu se siente un poco aburrido"): sirve para que el
## jugador este atento a lo que necesita y se encariñe. Las urgentes van primero.

## Una frase: {"text", "stat" (para el icono y el color), "level"}: 2 = urgente, 1 = atencion, 0 = todo bien.
static func _m(text: String, stat: String, level: int, value: float) -> Dictionary:
	return {"text": text, "stat": stat, "level": level, "value": value}


## Pone {his}/{he} (ingles) segun el sexo del Pompon.
static func _pron(out: Array, p: Pompon) -> Array:
	for m in out:
		if String(m["text"]).contains("{"):
			m["text"] = String(m["text"]).format(T.pron(p.sex))
	return out


static func messages(p: Pompon) -> Array:
	var n := p.display_name()
	var a := "" if T.lang() == "en" else ("a" if p.sex == "Hembra" else "o")   # aburrida / aburrido (en inglés no hace falta)
	var s := p.stats
	var out: Array = []
	var v: float
	v = s.get("alimentacion", 100.0)
	if v < 25.0:
		out.append(_m(T.s("%s tiene mucha hambre") % n, "alimentacion", 2, v))
	elif v < 55.0:
		out.append(_m(T.s("%s tiene un poco de hambre") % n, "alimentacion", 1, v))
	elif v >= 85.0:
		out.append(_m(T.s("%s está bien alimentad%s") % [n, a], "alimentacion", 0, v))
	v = s.get("hidratacion", 100.0)
	if v < 25.0:
		out.append(_m(T.s("%s tiene mucha sed") % n, "hidratacion", 2, v))
	elif v < 55.0:
		out.append(_m(T.s("%s tiene un poco de sed") % n, "hidratacion", 1, v))
	elif v >= 85.0:
		out.append(_m(T.s("%s está bien hidratad%s") % [n, a], "hidratacion", 0, v))
	v = s.get("aseo", 100.0)
	if v < 25.0:
		out.append(_m(T.s("%s necesita un baño") % n, "aseo", 2, v))
	elif v < 55.0:
		out.append(_m(T.s("%s quiere estar más limpi%s") % [n, a], "aseo", 1, v))
	elif v >= 85.0:
		out.append(_m(T.s("%s está limpit%s") % [n, a], "aseo", 0, v))
	v = s.get("diversion", 100.0)
	if v < 25.0:
		out.append(_m(T.s("%s está muy aburrid%s") % [n, a], "diversion", 2, v))
	elif v < 55.0:
		out.append(_m(T.s("%s se siente un poco aburrid%s") % [n, a], "diversion", 1, v))
	elif v >= 80.0:
		out.append(_m(T.s("%s se siente muy divertid%s") % [n, a], "diversion", 0, v))
	v = s.get("comodidad", 100.0)
	if v < 40.0:
		out.append(_m(T.s("%s no se siente cómod%s") % [n, a], "comodidad", 1, v))
	elif v >= 80.0:
		out.append(_m(T.s("%s está muy cómod%s") % [n, a], "comodidad", 0, v))
	v = s.get("sueno", 100.0)
	if v < 20.0:
		out.append(_m(T.s("%s se cae de sueño") % n, "sueno", 2, v))
	elif v < 40.0:
		out.append(_m(T.s("%s tiene sueño") % n, "sueno", 1, v))
	elif v >= 85.0:
		out.append(_m(T.s("%s está muy descansad%s") % [n, a], "sueno", 0, v))
	v = s.get("amor", 100.0)
	if v < 30.0:
		out.append(_m(T.s("%s se siente solit%s") % [n, a], "amor", 2, v))
	elif v < 55.0:
		out.append(_m(T.s("%s quiere más cariño") % n, "amor", 1, v))
	elif v >= 80.0:
		out.append(_m(T.s("%s se siente amad%s") % [n, a], "amor", 0, v))
	v = s.get("amistad", 100.0)
	if v < 20.0:
		out.append(_m(T.s("%s extraña a sus amigos") % n, "amistad", 1, v))
	elif v >= 70.0:
		out.append(_m(T.s("%s tiene muchos amigos") % n, "amistad", 0, v))
	v = s.get("inteligencia", 100.0)
	if v < 15.0:
		out.append(_m(T.s("%s quiere aprender cosas nuevas") % n, "inteligencia", 1, v))
	elif v >= 60.0:
		out.append(_m(T.s("%s se siente muy list%s") % [n, a], "inteligencia", 0, v))
	if out.is_empty():
		out.append(_m(T.s("%s está tranquil%s") % [n, a], "felicidad", 0, 70.0))
	out.sort_custom(func(x, y): return x["level"] > y["level"] or (x["level"] == y["level"] and x["value"] < y["value"]))
	return _pron(out, p)


## Lista para ir mostrando de a una: primero lo urgente y lo que necesita atencion, y un par de cosas buenas.
static func rotation(p: Pompon, rng: RandomNumberGenerator = null) -> Array:
	var all := messages(p)
	var needs := all.filter(func(m): return m["level"] >= 1)
	var good := all.filter(func(m): return m["level"] == 0)
	if rng != null:
		for i in range(good.size() - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var t = good[i]
			good[i] = good[j]
			good[j] = t
	return needs + good.slice(0, 2)
