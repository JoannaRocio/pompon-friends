class_name TutorialSteps
extends RefCounted
## El tutorial guiado, por capitulos cortos y repartidos en varios dias (para no agobiar y para que
## siempre haya algo nuevo por descubrir). Empieza cuando el Pompon ya nacio y tiene nombre.
##
## Cada capitulo tiene pasos: "target" = que boton se resalta (ver Home._tutorial_target), "mode" =
## "tap" (hay que tocar ese boton para seguir) o "next" (se lee y se toca "¡Entendido!"), "card" =
## un dibujo extra ("growth": las etapas del Pompon). {name} = el nombre del Pompon, {days} = dias
## que faltan para que sea niño. "text" es la clave del texto en locale/textos.csv.
## "wait" = cuanto esperar despues del capitulo anterior: segundos jugando, o "day" (otro dia).

const CHAPTERS := [
	{"id": "cuidar", "wait": 0, "steps": [
		{"target": "", "mode": "next", "text": "tut.cuidar.0"},
		{"target": "dock:Caricia", "mode": "tap", "text": "tut.cuidar.1"},
		{"target": "dock:Comer", "mode": "tap", "text": "tut.cuidar.2"},
		{"target": "info", "mode": "next", "text": "tut.cuidar.3"},
		{"target": "top:Diario", "mode": "next", "text": "tut.cuidar.4"},
	]},
	{"id": "crecer", "wait": 40, "steps": [
		{"target": "", "mode": "next", "card": "growth", "text": "tut.crecer.0"},
		{"target": "info", "mode": "next", "text": "tut.crecer.1"},
	]},
	{"id": "casa", "wait": 180, "steps": [
		{"target": "tab:Casa", "mode": "tap", "text": "tut.casa.0"},
		{"target": "dock:Tienda", "mode": "next", "text": "tut.casa.1"},
		{"target": "dock:Decorar", "mode": "next", "text": "tut.casa.2"},
		{"target": "tab:Pompon", "mode": "tap", "text": "tut.casa.3"},
	]},
	{"id": "amigos", "wait": "day", "steps": [
		{"target": "top:Vecinos", "mode": "tap", "text": "tut.amigos.0"},
		{"target": "friends_card", "mode": "next", "screen": "neighbors", "text": "tut.amigos.1"},
	]},
	{"id": "jugar", "wait": 240, "steps": [
		{"target": "dock:Juegos", "mode": "next", "text": "tut.jugar.0"},
		{"target": "top:Misiones", "mode": "next", "text": "tut.jugar.1"},
	]},
	{"id": "pueblo", "wait": "day", "steps": [
		{"target": "door", "mode": "next", "text": "tut.pueblo.0"},
		{"target": "top:Trabajo", "mode": "next", "text": "tut.pueblo.1"},
		{"target": "", "mode": "next", "text": "tut.pueblo.2"},
	]},
]
# Avisos sueltos que el tutorial ya explica (no se repiten)
const COVERS_TIPS := ["care", "pet", "decor", "coins", "friends", "growth", "town1"]


static func chapter(i: int) -> Dictionary:
	return CHAPTERS[i] if i >= 0 and i < CHAPTERS.size() else {}


static func index_of(id: String) -> int:
	for i in CHAPTERS.size():
		if CHAPTERS[i]["id"] == id:
			return i
	return -1


## El texto (en el idioma actual) con el nombre y los dias.
static func fill(text: String, pompon_name: String, days: int) -> String:
	return T.t(text).replace("{name}", pompon_name).replace("{days_word}", T.t("tut.day") if days == 1 else T.t("tut.days")).replace("{days}", str(days))
