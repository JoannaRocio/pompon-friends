class_name TutorialSteps
extends RefCounted
## El tutorial guiado, por capitulos cortos y repartidos en varios dias (para no agobiar y para que
## siempre haya algo nuevo por descubrir). Empieza cuando el Pompon ya nacio y tiene nombre.
##
## Cada capitulo tiene pasos: "target" = que boton se resalta (ver Home._tutorial_target), "mode" =
## "tap" (hay que tocar ese boton para seguir) o "next" (se lee y se toca "¡Entendido!"), "card" =
## un dibujo extra ("growth": las etapas del Pompon). {name} = el nombre del Pompon, {days} = dias
## que faltan para que sea niño.
## "wait" = cuanto esperar despues del capitulo anterior: segundos jugando, o "day" (otro dia).

const CHAPTERS := [
	{"id": "cuidar", "wait": 0, "steps": [
		{"target": "", "mode": "next", "text": "¡Hola! Te muestro en un ratito cómo cuidar a {name}. Toca los botones que brillan."},
		{"target": "dock:Caricia", "mode": "tap", "text": "Los mimos le dan confianza. ¡Toca Caricia!"},
		{"target": "dock:Comer", "mode": "tap", "text": "Cuando tenga hambre, toca Comer y elige algo rico."},
		{"target": "info", "mode": "next", "text": "Estas barras son lo que necesita: comida, agua, baño, diversión y sueño. Si una baja, ¡atiéndela!"},
		{"target": "top:Diario", "mode": "next", "text": "En el Diario se anota lo que {name} piensa y siente. ¡Léelo cada tanto!"},
	]},
	{"id": "crecer", "wait": 40, "steps": [
		{"target": "", "mode": "next", "card": "growth", "text": "En {days} {days_word} {name} va a ser niño. ¡Cuídalo mucho estos días: así aprende a hablar y confía en ti!"},
		{"target": "info", "mode": "next", "text": "La barra verde de Crecimiento muestra qué tan bien lo estás cuidando."},
	]},
	{"id": "casa", "wait": 180, "steps": [
		{"target": "tab:Casa", "mode": "tap", "text": "Aquí está todo para tu casa. Toca Casa."},
		{"target": "dock:Tienda", "mode": "next", "text": "En la Tienda hay muebles, ropa y comida. Cada día cambian las ofertas."},
		{"target": "dock:Decorar", "mode": "next", "text": "Con Decorar acomodas tus cosas. ¡{name} va a usarlas: se sienta, toca el piano, mira los cuadros!"},
		{"target": "tab:Pompon", "mode": "tap", "text": "Toca Pompon para volver a sus cuidados."},
	]},
	{"id": "amigos", "wait": "day", "steps": [
		{"target": "top:Vecinos", "mode": "tap", "text": "¡Hoy toca hacer amigos! Toca Vecinos."},
		{"target": "friends_card", "mode": "next", "screen": "neighbors", "text": "Cada jugador tiene un código (su ID). Comparte el tuyo y agrega el de tus amigos: se visitan y se regalan dibujos."},
	]},
	{"id": "jugar", "wait": 240, "steps": [
		{"target": "dock:Juegos", "mode": "next", "text": "Los minijuegos le enseñan cosas a {name} y suben sus habilidades."},
		{"target": "top:Misiones", "mode": "next", "text": "En Misiones hay tareas nuevas cada día, logros y un sello por cada día de la semana que entras."},
	]},
	{"id": "pueblo", "wait": "day", "steps": [
		{"target": "door", "mode": "next", "text": "Esta puerta sale al pueblo: el cine con películas nuevas cada semana, la tienda y las casas de tus vecinos."},
		{"target": "top:Trabajo", "mode": "next", "text": "En Trabajo puedes enseñar Matemáticas, Inglés y Geografía. ¡Más clases, más monedas!"},
		{"target": "", "mode": "next", "text": "¡Ya conoces todo lo importante! Cada semana hay algo nuevo. ¡Que lo disfrutes con {name}!"},
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


## El texto con el nombre y los dias.
static func fill(text: String, pompon_name: String, days: int) -> String:
	return text.replace("{name}", pompon_name).replace("{days_word}", "día" if days == 1 else "días").replace("{days}", str(days))
