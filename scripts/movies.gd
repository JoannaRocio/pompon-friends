class_name Movies
extends RefCounted
## Las peliculas del Cine Pompon: tres cortos para todo publico que rotan cada semana (cambian los
## lunes): uno de terror, uno romantico y uno de accion, cada uno con un mensaje. Cada pelicula es una
## lista de escenas (fondo, actores, objetos y el subtitulo) que dibuja MovieScreen. Los actores son
## Pompons de muestra.
##
## Escena: {"bg", "text", "actors": [[quien, x, y, {opciones}]], "props": [[tipo, x, y, tamaño, ...]]}
##   opciones del actor: "mood" ("happy"/"shy"/""), "face" (1/-1), "jump", "walk", "lean", "hidden"
## Coordenadas en fracciones de la pantalla (y = donde pisa el actor).

const TICKET := 15        # monedas por entrada (con pochoclos)

const MOVIES := [
	{
		"id": "colina", "title": "La casa de la colina", "genre": "Terror", "color": "6b5a8f",
		"tagline": "Todos dicen que ahí vive un monstruo. Nico va a averiguarlo.",
		"message": "A veces lo que nos asusta es alguien que nadie se animó a conocer.",
		"cast": {"nico": ["Felino", "9aa0b5", "e8ebf2", "brillantes"], "bruma": ["Conejo", "d8cfe8", "f6f2fb", "tiernos"]},
		"scenes": [
			{"bg": "hill_night", "text": "En el pueblo todos decían lo mismo: en la casa de la colina vivía un monstruo.",
				"actors": [], "props": [["house_hill", 0.62, 0.62, 0.34], ["moon", 0.18, 0.18, 0.07], ["thunder", 0.0, 0.0, 0.0]]},
			{"bg": "hill_night", "text": "Nico decía que no creía en monstruos. Igual le temblaban un poco las patitas.",
				"actors": [["nico", 0.3, 0.9, {"mood": "shy", "face": 1}]], "props": [["house_hill", 0.75, 0.55, 0.26], ["flashlight", 0.37, 0.72, 0.3]]},
			{"bg": "haunted", "text": "La puerta crujió. Adentro, dos ojos lo miraban desde la oscuridad.",
				"actors": [["nico", 0.25, 0.9, {"mood": "shy", "face": 1, "lean": -0.12}]], "props": [["eyes", 0.72, 0.42, 0.06], ["flashlight", 0.32, 0.72, 0.25]]},
			{"bg": "haunted", "text": "¡Una sombra gigante se levantó en la pared! Nico quiso correr… pero se quedó.",
				"actors": [["nico", 0.22, 0.9, {"mood": "shy", "face": 1}]], "props": [["shadow", 0.66, 0.5, 0.42], ["thunder", 0.0, 0.0, 0.0]]},
			{"bg": "haunted_lit", "text": "No era un monstruo. Era Bruma, que hacía sombras con su farol para no sentirse tan sola.",
				"actors": [["nico", 0.28, 0.9, {"face": 1}], ["bruma", 0.68, 0.9, {"mood": "shy", "face": -1}]], "props": [["lantern", 0.8, 0.62, 0.08]]},
			{"bg": "haunted_lit", "text": "Hacía años que nadie tocaba su puerta. Todos le tenían miedo… sin conocerla.",
				"actors": [["nico", 0.32, 0.9, {"face": 1}], ["bruma", 0.64, 0.9, {"face": -1, "lean": 0.08}]], "props": [["lantern", 0.82, 0.62, 0.08], ["cup", 0.48, 0.74, 0.05]]},
			{"bg": "hill_day", "text": "Desde ese día, la casa de la colina tiene visitas todas las tardes. A veces lo que nos asusta es alguien que nadie se animó a conocer. FIN",
				"actors": [["nico", 0.3, 0.9, {"mood": "happy", "jump": true}], ["bruma", 0.55, 0.9, {"mood": "happy"}]], "props": [["house_hill", 0.8, 0.6, 0.24, "day"], ["flowers", 0.82, 0.9, 0.24, "fresh"]]},
		],
		"reactions": ["me dio un poquito de miedo… ¡pero el final fue hermoso!", "voy a saludar más a los vecinos que no conozco", "¡Bruma no era un monstruo! Me quedé pensando"],
	},
	{
		"id": "cartas", "title": "Cartas bajo la lluvia", "genre": "Romántica", "color": "e0609e",
		"tagline": "Dos vecinos, cartas sin firma y una tarde de lluvia.",
		"message": "Lo que sentimos vale más cuando nos animamos a decirlo.",
		"cast": {"ema": ["Conejo", "ffc2d9", "fff3f8", "tiernos"], "leo": ["Canino", "c9925f", "f3d9b1", "brillantes"]},
		"scenes": [
			{"bg": "street", "text": "Ema hacía pan en la esquina. Leo tocaba la guitarra en la plaza. Se veían todos los días… y nunca se hablaban.",
				"actors": [["ema", 0.22, 0.9, {"face": 1}], ["leo", 0.78, 0.9, {"face": -1}]], "props": [["shop_front", 0.2, 0.62, 0.3], ["guitar", 0.86, 0.78, 0.1], ["lamp_post", 0.5, 0.9, 0.5]]},
			{"bg": "street", "text": "Una mañana, Ema encontró una carta sin firma: \"Tu pan huele a domingo\".",
				"actors": [["ema", 0.4, 0.9, {"mood": "shy", "face": 1}]], "props": [["shop_front", 0.2, 0.62, 0.3], ["letter", 0.55, 0.6, 0.07], ["hearts", 0.5, 0.35, 0.2]]},
			{"bg": "street", "text": "Esa tarde, Leo también encontró una: \"Tu música hace sonreír a la calle\".",
				"actors": [["leo", 0.6, 0.9, {"mood": "shy", "face": -1}]], "props": [["guitar", 0.78, 0.78, 0.1], ["letter", 0.45, 0.6, 0.07], ["hearts", 0.5, 0.35, 0.2]]},
			{"bg": "street_rain", "text": "Los dos querían saber quién las escribía. Pero ninguno se animaba a preguntar.",
				"actors": [["ema", 0.2, 0.9, {"face": 1, "lean": -0.06}], ["leo", 0.8, 0.9, {"face": -1, "lean": 0.06}]], "props": [["lamp_post", 0.5, 0.9, 0.5], ["rain_all", 0.0, 0.0, 0.0]]},
			{"bg": "street_rain", "text": "Una tarde de lluvia se refugiaron bajo el mismo toldo… y las cartas se les cayeron al piso.",
				"actors": [["ema", 0.4, 0.9, {"mood": "shy", "face": 1}], ["leo", 0.6, 0.9, {"mood": "shy", "face": -1}]], "props": [["awning", 0.5, 0.42, 0.3], ["letter", 0.44, 0.92, 0.05], ["letter", 0.58, 0.93, 0.05], ["rain_all", 0.0, 0.0, 0.0]]},
			{"bg": "sunset", "text": "Eran la misma letra. Se rieron un montón y hablaron hasta que salieron las estrellas.",
				"actors": [["ema", 0.42, 0.9, {"mood": "happy", "face": 1}], ["leo", 0.58, 0.9, {"mood": "happy", "face": -1}]], "props": [["hearts", 0.5, 0.35, 0.3]]},
			{"bg": "sunset", "text": "Lo que sentimos vale más cuando nos animamos a decirlo. FIN",
				"actors": [["ema", 0.38, 0.9, {"mood": "happy", "jump": true}], ["leo", 0.62, 0.9, {"mood": "happy", "jump": true}]], "props": [["hearts", 0.5, 0.3, 0.35], ["guitar", 0.75, 0.8, 0.08]]},
		],
		"reactions": ["¡qué lindo final! Hay que animarse a decir las cosas", "me puse colorad{a} con la parte de las cartas", "voy a escribirle una carta linda a alguien"],
	},
	{
		"id": "tormenta", "title": "Operación Tormenta", "genre": "Acción", "color": "ff8a3d",
		"tagline": "Una tormenta va a romper el puente del valle. Rayo quiere salvarlo… solo.",
		"message": "Nadie es un héroe solo.",
		"cast": {"rayo": ["Felino", "ffd84d", "fff6c9", "brillantes"], "roca": ["Canino", "a39bb0", "e6e1ec", "redondos"], "chispa": ["Ave", "7cc8ff", "e6f6ff", "tiernos"]},
		"scenes": [
			{"bg": "valley", "text": "Rayo era el Pompon más rápido del valle. Y estaba seguro de que no necesitaba a nadie.",
				"actors": [["rayo", 0.3, 0.9, {"mood": "happy", "face": 1, "jump": true}], ["roca", 0.62, 0.9, {"face": -1}], ["chispa", 0.82, 0.9, {"face": -1}]], "props": [["bridge", 0.5, 0.66, 0.4, "ok"]]},
			{"bg": "storm", "text": "Una noche llegó la tormenta más fuerte en cien años. ¡El puente empezó a romperse!",
				"actors": [], "props": [["bridge", 0.5, 0.66, 0.4, "crack"], ["lightning", 0.7, 0.1, 0.4], ["rain_all", 0.0, 0.0, 0.0], ["thunder", 0.0, 0.0, 0.0]]},
			{"bg": "storm", "text": "—¡Yo puedo solo! —gritó Rayo, y salió corriendo hacia el puente.",
				"actors": [["rayo", 0.2, 0.9, {"face": 1, "walk": true}]], "props": [["bridge", 0.62, 0.66, 0.36, "crack"], ["rain_all", 0.0, 0.0, 0.0]]},
			{"bg": "storm", "text": "Pero el viento lo empujó una y otra vez. Para uno solo, era demasiado.",
				"actors": [["rayo", 0.4, 0.9, {"mood": "shy", "face": 1, "lean": -0.3}]], "props": [["bridge", 0.66, 0.66, 0.36, "broken"], ["wind", 0.5, 0.5, 0.4], ["rain_all", 0.0, 0.0, 0.0]]},
			{"bg": "storm", "text": "Entonces llegaron Roca, que sostuvo las vigas, y Chispa, que armó un plan con una soga.",
				"actors": [["rayo", 0.28, 0.9, {"face": 1}], ["roca", 0.52, 0.9, {"face": 1, "lean": 0.1}], ["chispa", 0.76, 0.9, {"face": -1, "jump": true}]], "props": [["bridge", 0.55, 0.66, 0.36, "broken"], ["rope", 0.5, 0.7, 0.4], ["rain_all", 0.0, 0.0, 0.0]]},
			{"bg": "storm", "text": "Rayo cruzó corriendo con la soga. ¡Esta vez su velocidad sirvió para el equipo!",
				"actors": [["rayo", 0.4, 0.88, {"mood": "happy", "face": 1, "walk": true}], ["roca", 0.2, 0.9, {"face": 1}]], "props": [["bridge", 0.55, 0.66, 0.36, "fixing"], ["rope", 0.5, 0.7, 0.4], ["rain_all", 0.0, 0.0, 0.0]]},
			{"bg": "valley", "text": "Al amanecer, el puente seguía en pie. Rayo aprendió algo que no le enseñó la velocidad: nadie es un héroe solo. FIN",
				"actors": [["rayo", 0.3, 0.9, {"mood": "happy", "jump": true}], ["roca", 0.5, 0.9, {"mood": "happy", "jump": true}], ["chispa", 0.7, 0.9, {"mood": "happy", "jump": true}]], "props": [["bridge", 0.5, 0.66, 0.4, "ok"], ["confetti", 0.5, 0.3, 0.4]]},
		],
		"reactions": ["¡qué emocionante! Juntos se puede más", "me encantó cuando cruzó con la soga", "¡quiero ser parte de un equipo como ese!"],
	},
]


## Semana del juego (cambia los lunes): el dia 0 de Missions.today fue un jueves.
static func week_of(day: int) -> int:
	return floori((day + 3) / 7.0)


## La pelicula de esta semana y de la que viene.
static func of_day(day: int) -> Dictionary:
	return MOVIES[posmod(week_of(day), MOVIES.size())]


static func next_of(day: int) -> Dictionary:
	return MOVIES[posmod(week_of(day) + 1, MOVIES.size())]


## Dias que faltan para que cambie la pelicula (1 a 7).
static func days_left(day: int) -> int:
	return 7 - posmod(day + 3, 7)


## Cuanto dura una escena en pantalla: mas si el subtitulo es largo (para que se alcance a leer).
static func scene_seconds(text: String) -> float:
	return clampf(2.6 + text.length() / 17.0, 4.0, 10.0)


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
