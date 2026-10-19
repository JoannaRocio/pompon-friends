class_name Movies
extends RefCounted
## Las peliculas del Cine Pompon: tres cortitos que rotan cada dia. Cada uno es una lista de escenas
## (fondo, actores, objetos y el subtitulo) que dibuja MovieScreen. Los actores son Pompons de muestra.
##
## Escena: {"bg", "text", "actors": [[quien, x, y, {opciones}]], "props": [[tipo, x, y, tamaño, ...]]}
##   opciones del actor: "mood" ("happy"/"shy"/""), "face" (1/-1), "jump", "walk", "lean", "hidden"
## Coordenadas en fracciones de la pantalla (y = donde pisa el actor).

const TICKET := 15        # monedas por entrada (con pochoclos)
const SCENE_SECONDS := 4.6

const MOVIES := [
	{
		"id": "luna", "title": "Viaje a la Luna", "genre": "Aventura", "color": "5b6fc4",
		"tagline": "Una conejita construye un cohete para conocer la Luna.",
		"cast": {"hero": ["Conejo", "ffc2d9", "fff3f8", "brillantes"], "brillo": ["Ave", "ffe066", "fff8d6", "tiernos"]},
		"scenes": [
			{"bg": "night_room", "text": "Lulú miraba la Luna todas las noches desde su ventana.",
				"actors": [["hero", 0.42, 0.88, {"face": 1}]], "props": [["window", 0.72, 0.38, 0.3], ["moon", 0.72, 0.36, 0.08]]},
			{"bg": "night_room", "text": "Un día decidió construir un cohete… ¡con cajas de cartón!",
				"actors": [["hero", 0.3, 0.88, {"mood": "happy", "jump": true}]], "props": [["boxes", 0.66, 0.88, 0.22], ["window", 0.82, 0.3, 0.2], ["moon", 0.82, 0.28, 0.05]]},
			{"bg": "night_field", "text": "3… 2… 1… ¡Despegue!",
				"actors": [], "props": [["rocket", 0.5, 0.86, 0.32, "launch"], ["moon", 0.82, 0.18, 0.07]]},
			{"bg": "space", "text": "Voló entre las estrellas, más lejos que nadie.",
				"actors": [], "props": [["rocket", 0.2, 0.55, 0.26, "fly"], ["planet", 0.78, 0.3, 0.1]]},
			{"bg": "moon", "text": "En la Luna conoció a Brillo, un Pompon de luz.",
				"actors": [["hero", 0.32, 0.86, {"face": 1}], ["brillo", 0.68, 0.86, {"mood": "shy", "face": -1}]], "props": [["earth", 0.8, 0.2, 0.09]]},
			{"bg": "moon", "text": "¡Saltaban altísimo! En la Luna casi no se pesa nada.",
				"actors": [["hero", 0.32, 0.7, {"mood": "happy", "jump": true}], ["brillo", 0.68, 0.62, {"mood": "happy", "jump": true}]], "props": [["earth", 0.8, 0.2, 0.09]]},
			{"bg": "night_room", "text": "Volvió a casa con un regalo: una estrella para su ventana. FIN",
				"actors": [["hero", 0.42, 0.88, {"mood": "happy"}]], "props": [["window", 0.72, 0.38, 0.3], ["star", 0.72, 0.36, 0.07]]},
		],
		"reactions": ["¡ahora quiero ser astronauta!", "¡qué lindo era Brillo!", "¡yo también quiero saltar en la Luna!"],
	},
	{
		"id": "torta", "title": "El misterio de la torta", "genre": "Comedia", "color": "e0609e",
		"tagline": "¿Quién se comió la torta de cumpleaños? ¡Un caso para Tomi!",
		"cast": {"tomi": ["Felino", "ffb26b", "fff1e0", "redondos"], "chef": ["Canino", "f4eef2", "ffffff", "tiernos"], "bizcocho": ["Canino", "c9925f", "f3d9b1", "brillantes"]},
		"scenes": [
			{"bg": "kitchen", "text": "Era el cumpleaños de Tomi y había una torta enorme.",
				"actors": [["tomi", 0.28, 0.88, {"mood": "happy", "face": 1}], ["chef", 0.72, 0.88, {"face": -1}]], "props": [["table", 0.5, 0.88, 0.2], ["cake", 0.5, 0.66, 0.1]]},
			{"bg": "kitchen", "text": "Pero cuando volvieron… ¡la torta había desaparecido!",
				"actors": [["tomi", 0.28, 0.88, {"mood": "shy", "face": 1}], ["chef", 0.72, 0.88, {"mood": "shy", "face": -1}]], "props": [["table", 0.5, 0.88, 0.2], ["crumbs", 0.5, 0.7, 0.06], ["question", 0.5, 0.35, 0.08]]},
			{"bg": "kitchen", "text": "Tomi se puso su gorra y sacó su lupa de detective.",
				"actors": [["tomi", 0.45, 0.88, {"face": 1, "lean": 0.12}]], "props": [["magnifier", 0.62, 0.62, 0.08], ["crumbs", 0.75, 0.86, 0.05]]},
			{"bg": "garden", "text": "Siguió las miguitas por todo el jardín…",
				"actors": [["tomi", 0.25, 0.88, {"face": 1, "walk": true}]], "props": [["crumbs", 0.45, 0.88, 0.04], ["crumbs", 0.62, 0.88, 0.04], ["crumbs", 0.8, 0.88, 0.04], ["bush", 0.88, 0.86, 0.12]]},
			{"bg": "garden", "text": "¡Era Bizcocho! Tenía la nariz llena de crema.",
				"actors": [["tomi", 0.3, 0.88, {"face": 1}], ["bizcocho", 0.7, 0.88, {"mood": "happy", "face": -1, "jump": true}]], "props": [["cream", 0.68, 0.7, 0.035], ["bush", 0.9, 0.86, 0.1]]},
			{"bg": "kitchen", "text": "Al final cocinaron otra torta, todos juntos. ¡Feliz cumpleaños! FIN",
				"actors": [["tomi", 0.22, 0.88, {"mood": "happy", "jump": true}], ["chef", 0.5, 0.88, {"mood": "happy"}], ["bizcocho", 0.78, 0.88, {"mood": "happy", "jump": true}]],
				"props": [["cake", 0.5, 0.52, 0.11], ["confetti", 0.5, 0.3, 0.4]]},
		],
		"reactions": ["¡me reí muchísimo con Bizcocho!", "ahora tengo ganas de comer torta", "¡quiero ser detective como Tomi!"],
	},
	{
		"id": "nube", "title": "Nubecita", "genre": "Ternura", "color": "4cb782",
		"tagline": "La nube más chiquita del cielo quiere ayudar a las flores.",
		"cast": {"pipo": ["Conejo", "c9f0d2", "f2fff5", "tiernos"]},
		"scenes": [
			{"bg": "sky", "text": "Nubecita era la nube más chiquita de todo el cielo.",
				"actors": [], "props": [["cloud_face", 0.5, 0.4, 0.12, "sad"]]},
			{"bg": "sky", "text": "Las nubes grandes hacían lluvia… pero ella no podía.",
				"actors": [], "props": [["big_cloud", 0.24, 0.26, 0.2], ["rain", 0.24, 0.38, 0.18], ["big_cloud", 0.78, 0.3, 0.2], ["rain", 0.78, 0.42, 0.18], ["cloud_face", 0.5, 0.62, 0.08, "sad"]]},
			{"bg": "field", "text": "Abajo, las flores de Pipo tenían mucha sed.",
				"actors": [["pipo", 0.3, 0.88, {"mood": "shy", "face": 1}]], "props": [["flowers", 0.68, 0.88, 0.3, "dry"]]},
			{"bg": "sky", "text": "Nubecita juntó fuerzas… ¡y lo intentó con todas sus ganas!",
				"actors": [], "props": [["cloud_face", 0.5, 0.42, 0.13, "try"]]},
			{"bg": "field", "text": "¡Plic, plic, plic! ¡Le salió una lluvia chiquita!",
				"actors": [["pipo", 0.28, 0.88, {"mood": "happy", "face": 1}]], "props": [["cloud_face", 0.66, 0.22, 0.08, "happy"], ["rain", 0.66, 0.32, 0.12], ["flowers", 0.66, 0.88, 0.3, "dry"]]},
			{"bg": "field", "text": "Las flores crecieron y apareció un arcoíris. FIN",
				"actors": [["pipo", 0.28, 0.88, {"mood": "happy", "jump": true}]], "props": [["rainbow", 0.5, 0.5, 0.5], ["cloud_face", 0.82, 0.2, 0.07, "happy"], ["flowers", 0.66, 0.88, 0.3, "fresh"]]},
		],
		"reactions": ["me emocioné un poquito", "¡las flores quedaron hermosas!", "¡Nubecita es mi favorita!"],
	},
]


## La pelicula de hoy (cambia cada dia, una detras de la otra) y la de mañana.
static func of_day(day: int) -> Dictionary:
	return MOVIES[posmod(day, MOVIES.size())]


static func get_movie(id: String) -> Dictionary:
	for m in MOVIES:
		if m["id"] == id:
			return m
	return {}


static func cast_pompon(movie: Dictionary, who: String) -> Pompon:
	var c: Array = movie["cast"][who]
	var p := PomponView.make_sample(c[0], Color(c[1]), Color(c[2]), c[3])
	p.born_at = int(Time.get_unix_time_from_system()) - 40 * 86400   # actores grandes
	p.hatched = true
	return p
