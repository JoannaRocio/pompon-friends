class_name Progress
extends RefCounted
## Progreso de largo plazo (para volver cada dia, o al menos una vez por semana):
##
## - Calendario semanal: cada dia distinto que entras en la semana pone un sello (no hace falta que
##   sean seguidos: faltar un dia no borra nada). Cada sello tiene su premio y el septimo es el grande.
##   La semana empieza el lunes (igual que el cine).
## - Logros: metas largas con medallas de bronce, plata y oro (dias jugados, clases dadas, peliculas,
##   dibujos, figuritas, amigos...). Cada medalla se reclama con monedas.
## Los datos viven en GameState (`week_visits`, `days_visited`, `achievements_claimed` y contadores);
## aca estan las reglas.

const WEEK_REWARDS := [10, 10, 15, 15, 20, 25, 60]   # monedas por el sello 1..7 de la semana
const WEEK_XP := 5                                   # puntos del Pase por cada sello
const TIER_NAMES := ["Bronce", "Plata", "Oro"]
const TIER_COLORS := [Color("d08a4f"), Color("b8c2cf"), Color("ffcf3f")]
const TIER_COINS := [25, 60, 150]

# Logros: {"id", "name", "text" (con {n}), "icon", "goals": [bronce, plata, oro]}
const ACHIEVEMENTS := [
	{"id": "days", "name": "Siempre presente", "text": "Entra {n} días distintos", "icon": "check", "goals": [3, 14, 60]},
	{"id": "growth", "name": "Creciendo juntos", "text": "Que tu Pompon llegue a {stage}", "icon": "sprout", "goals": [2, 3, 4]},
	{"id": "jobs", "name": "Profe estrella", "text": "Da {n} clases", "icon": "case", "goals": [10, 50, 200]},
	{"id": "career", "name": "Carrera brillante", "text": "Llega al nivel {n} de profesor/a", "icon": "star", "goals": [5, 15, 30]},
	{"id": "games", "name": "Gran jugador", "text": "Juega {n} minijuegos", "icon": "game", "goals": [10, 50, 200]},
	{"id": "art", "name": "Artista", "text": "Pinta {n} dibujos", "one": "Pinta tu primer dibujo", "icon": "palette", "goals": [1, 5, 20]},
	{"id": "movies", "name": "Cinéfilo", "text": "Ve {n} películas en el cine", "one": "Ve una película en el cine", "icon": "moon", "goals": [1, 5, 15]},
	{"id": "album", "name": "Coleccionista", "text": "Consigue {n} figuritas del álbum", "icon": "book", "goals": [10, 25, 36]},
	{"id": "friends", "name": "Amigos de verdad", "text": "Ten {n} amigos de verdad", "one": "Agrega a tu primer amigo de verdad", "icon": "people", "goals": [1, 3, 10]},
	{"id": "neighbors", "name": "Buen vecino", "text": "Suma {n} puntos de amistad", "icon": "house", "goals": [25, 100, 300]},
	{"id": "decor", "name": "Decorador", "text": "Consigue {n} cosas de la tienda", "icon": "bag", "goals": [10, 30, 60]},
]
const STAGE_WORDS := {2: "niño", 3: "adolescente", 4: "grande"}


static func get_def(id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if a["id"] == id:
			return a
	return {}


## Medallas ganadas (0 a 3) con este valor.
static func tier_for(def: Dictionary, value: int) -> int:
	var tier := 0
	for g in def["goals"]:
		if value >= int(g):
			tier += 1
	return tier


## La meta siguiente (o la ultima si ya tiene oro).
static func next_goal(def: Dictionary, value: int) -> int:
	for g in def["goals"]:
		if value < int(g):
			return int(g)
	return int(def["goals"][-1])


## "Da 50 clases", "Que tu Pompon llegue a adolescente"...
static func goal_text(def: Dictionary, goal: int) -> String:
	if goal == 1 and def.has("one"):
		return def["one"]
	return String(def["text"]).replace("{n}", str(goal)).replace("{stage}", STAGE_WORDS.get(goal, "grande"))
