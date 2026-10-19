class_name PomponPlay
extends RefCounted
## Lo que el Pompon hace con los objetos de su cuarto: se sienta en el sofa, toca el piano un buen
## rato, admira los cuadros, mira los peces, lee en la biblioteca... Y lo que dice cuando le ponen
## algo nuevo. Todo por forma de dibujo (`Catalog.shape_of`), asi los objetos especiales hacen lo
## mismo que su version comun. La casa (`home.gd`) se encarga de caminar hasta ahi y de la pose.
##
## Poses: "side" (parado al lado, mirandolo), "sit" (sentado encima), "lie" (acostado en la cama, sin
## dormir), "look" (debajo de algo de la pared o de un adorno chico, mirando hacia arriba),
## "run" (corre en el lugar: la rueda) y "swing" (sentado, se hamaca).
## fx: "note" (notas musicales), "sparkle" (brillitos), "heart", "bubble" (burbujas), "zzz".

const PLAYS := {
	"furn_piano": {"pose": "side", "secs": [22.0, 34.0], "fx": "note", "text": "toca el piano", "bob": 0.06,
		"stats": {"diversion": 12.0}, "say": ["¡Un piano! ¿Me escuchas tocar?", "¡Voy a componer una canción para ti!", "¡Do, re, mi! ¡Qué lindo suena!"]},
	"furn_sofa": {"pose": "sit", "seat": 0.36, "secs": [16.0, 26.0], "fx": "heart", "text": "descansa en el sofá",
		"stats": {"comodidad": 15.0}, "say": ["¡Un sofá! Qué suavecito…", "¡Me voy a sentar aquí todo el día!", "Ahh… qué cómodo."]},
	"furn_beanbag": {"pose": "sit", "seat": 0.42, "secs": [14.0, 22.0], "fx": "heart", "text": "se hunde en el puff",
		"stats": {"comodidad": 12.0}, "say": ["¡Un puff! ¡Me hundo!", "¡Es como sentarse en una nube!"]},
	"furn_stool": {"pose": "sit", "seat": 0.5, "secs": [8.0, 14.0], "fx": "", "text": "se sienta en el banquito",
		"stats": {"comodidad": 5.0}, "say": ["¡Un banquito justo de mi tamaño!"]},
	"furn_cushion": {"pose": "sit", "seat": 0.55, "secs": [14.0, 22.0], "fx": "heart", "text": "se acurruca en el cojín",
		"stats": {"comodidad": 12.0}, "say": ["¡Un cojín calentito!", "Mmm… qué tibio."]},
	"furn_bed": {"pose": "lie", "secs": [16.0, 24.0], "fx": "zzz", "text": "descansa en la cama",
		"stats": {"comodidad": 15.0, "sueno": 4.0}, "say": ["¡Una cama grande para mí!", "¡Voy a probarla ahora mismo!"]},
	"furn_swing": {"pose": "swing", "seat": 0.2, "secs": [14.0, 22.0], "fx": "heart", "text": "se hamaca en el columpio",
		"stats": {"diversion": 12.0}, "say": ["¡Un columpio! ¡Más alto, más alto!"]},
	"furn_wheel": {"pose": "run", "seat": 0.12, "secs": [12.0, 18.0], "fx": "", "text": "corre en la rueda",
		"stats": {"diversion": 10.0}, "say": ["¡Una rueda! ¡A correr!", "¡Voy a ponerme fuerte!"]},
	"furn_tunnel": {"pose": "side", "secs": [10.0, 16.0], "fx": "heart", "text": "juega en el túnel", "bob": 0.1,
		"stats": {"diversion": 10.0}, "say": ["¡Un túnel! ¿Jugamos a las escondidas?"]},
	"furn_scratcher": {"pose": "side", "secs": [10.0, 16.0], "fx": "", "text": "se rasca en el rascador", "bob": 0.12,
		"stats": {"comodidad": 10.0}, "say": ["¡Un rascador! ¡Justo lo que quería!"]},
	"furn_heat": {"pose": "side", "secs": [12.0, 20.0], "fx": "heart", "text": "se calienta bajo la lámpara",
		"stats": {"comodidad": 10.0}, "say": ["¡Qué calorcito!"]},
	"furn_fireplace": {"pose": "side", "secs": [16.0, 26.0], "fx": "heart", "text": "se calienta junto a la chimenea",
		"stats": {"comodidad": 12.0}, "say": ["¡Una chimenea! Qué calentito.", "Me encanta mirar el fuego."]},
	"furn_aquarium": {"pose": "side", "secs": [14.0, 24.0], "fx": "bubble", "text": "mira los peces", "near": true,
		"stats": {"diversion": 8.0}, "say": ["¡Peces! ¡Hola, pececitos!", "¡Mira cómo nadan!"]},
	"furn_bookshelf": {"pose": "side", "secs": [18.0, 28.0], "fx": "sparkle", "text": "lee un libro de la biblioteca",
		"stats": {"diversion": 6.0}, "say": ["¡Cuántos libros! ¿Cuál leo primero?", "¡Me encantan los cuentos!"]},
	"furn_desk": {"pose": "side", "secs": [14.0, 22.0], "fx": "sparkle", "text": "dibuja en el escritorio",
		"stats": {"diversion": 6.0}, "say": ["¡Un escritorio! Voy a dibujar algo lindo."]},
	"furn_globe": {"pose": "side", "secs": [10.0, 16.0], "fx": "sparkle", "text": "hace girar el globo terráqueo", "near": true,
		"stats": {"diversion": 6.0}, "say": ["¡El mundo entero! ¿Dónde vivimos?"]},
	"furn_toybox": {"pose": "side", "secs": [14.0, 22.0], "fx": "heart", "text": "juega con sus juguetes", "bob": 0.1,
		"stats": {"diversion": 12.0}, "say": ["¡Un baúl lleno de juguetes!", "¡A jugar!"]},
	"furn_teddy": {"pose": "side", "secs": [10.0, 18.0], "fx": "heart", "text": "abraza al osito", "near": true,
		"stats": {"comodidad": 8.0}, "say": ["¡Un osito! Le voy a dar un abrazo.", "¡Tú serás mi mejor amigo!"]},
	"furn_plant": {"pose": "side", "secs": [8.0, 12.0], "fx": "sparkle", "text": "huele la planta", "near": true,
		"stats": {}, "say": ["¡Una planta! Huele a bosque."]},
	"furn_table": {"pose": "side", "secs": [10.0, 16.0], "fx": "heart", "text": "toma un tecito en la mesita",
		"stats": {"comodidad": 6.0}, "say": ["¡Una mesita! ¿Tomamos un té?"]},
	"furn_dresser": {"pose": "side", "secs": [8.0, 12.0], "fx": "sparkle", "text": "ordena su cómoda",
		"stats": {}, "say": ["¡Una cómoda para guardar mis cosas!"]},
	"furn_wardrobe": {"pose": "side", "secs": [8.0, 12.0], "fx": "sparkle", "text": "elige ropa del armario",
		"stats": {}, "say": ["¡Un armario! ¿Qué me pongo hoy?"]},
	"furn_lamp": {"pose": "look", "secs": [6.0, 9.0], "fx": "sparkle", "text": "mira la luz de la lámpara",
		"stats": {}, "say": ["¡Qué linda luz!"]},
	"furn_lamp_stars": {"pose": "look", "secs": [10.0, 16.0], "fx": "sparkle", "text": "mira las estrellitas de la lámpara",
		"stats": {"comodidad": 6.0}, "say": ["¡Estrellitas! ¡Como el cielo de noche!"]},
	# en la pared
	"deco_picture": {"pose": "look", "secs": [14.0, 22.0], "fx": "sparkle", "text": "admira el cuadro",
		"stats": {"comodidad": 5.0}, "say": ["¡Qué cuadro tan lindo!", "¡Es una obra de arte!", "Mmm… ¿qué habrá querido pintar?"]},
	"deco_window": {"pose": "look", "secs": [12.0, 20.0], "fx": "sparkle", "text": "mira por la ventana",
		"stats": {"comodidad": 4.0}, "say": ["¡Una ventana! ¡Se ve todo el barrio!"]},
	"deco_clock": {"pose": "look", "secs": [6.0, 9.0], "fx": "", "text": "mira el reloj",
		"stats": {}, "say": ["Tic, tac… ¿ya es hora de comer?"]},
	"deco_rainbow": {"pose": "look", "secs": [8.0, 12.0], "fx": "heart", "text": "mira el arcoíris",
		"stats": {}, "say": ["¡Un arcoíris! ¡Mi color favorito es… todos!"]},
	"deco_balloons": {"pose": "look", "secs": [8.0, 12.0], "fx": "heart", "text": "mira los globos",
		"stats": {"diversion": 4.0}, "say": ["¡Globos! ¿Es una fiesta?"]},
	"deco_garland": {"pose": "look", "secs": [6.0, 10.0], "fx": "sparkle", "text": "mira la guirnalda",
		"stats": {}, "say": ["¡Qué alegre se ve todo!"]},
	"deco_moon": {"pose": "look", "secs": [8.0, 12.0], "fx": "sparkle", "text": "mira la luna y las estrellas",
		"stats": {"comodidad": 4.0}, "say": ["¡La luna! Me da sueñito…"]},
	# adornos chicos (en estantes y mesas)
	"toy_blocks": {"pose": "look", "secs": [12.0, 18.0], "fx": "sparkle", "text": "arma una torre con los cubos",
		"stats": {"diversion": 8.0}, "say": ["¡Cubos! Voy a hacer la torre más alta."]},
	"toy_books": {"pose": "look", "secs": [12.0, 18.0], "fx": "sparkle", "text": "hojea sus libros",
		"stats": {"diversion": 5.0}, "say": ["¡Libros nuevos para leer!"]},
	"toy_vase": {"pose": "look", "secs": [6.0, 10.0], "fx": "sparkle", "text": "huele las flores",
		"stats": {}, "say": ["¡Flores! Huelen riquísimo."]},
	"toy_cactus": {"pose": "look", "secs": [5.0, 8.0], "fx": "", "text": "mira el cactus con cuidado",
		"stats": {}, "say": ["Un cactus… ¡mejor no lo toco!"]},
	"toy_cake": {"pose": "look", "secs": [6.0, 10.0], "fx": "heart", "text": "mira la tarta con ganas",
		"stats": {}, "say": ["¡Una tarta! ¿Es mi cumpleaños?"]},
	"toy_frame": {"pose": "look", "secs": [8.0, 12.0], "fx": "heart", "text": "mira el portarretrato",
		"stats": {"comodidad": 4.0}, "say": ["¡Una foto! ¡Qué lindo recuerdo!"]},
	"toy_musicbox": {"pose": "look", "secs": [14.0, 22.0], "fx": "note", "text": "escucha la caja musical",
		"stats": {"diversion": 8.0}, "say": ["¡Una caja musical! ¡Qué melodía tan dulce!"]},
	"toy_robot": {"pose": "look", "secs": [12.0, 18.0], "fx": "sparkle", "text": "juega con su robot",
		"stats": {"diversion": 10.0}, "say": ["¡Un robot! Bip, bup… ¡hola, amigo!"]},
	"toy_trophy": {"pose": "look", "secs": [6.0, 10.0], "fx": "sparkle", "text": "admira la copa",
		"stats": {}, "say": ["¡Una copa! ¡Soy un campeón!"]},
}

# Comentarios para lo que no tiene uno propio.
const GENERIC_SAY := ["¡Qué lindo! ¿Es para mí?", "¡Algo nuevo en mi cuarto!", "¡Me encanta cómo queda!"]
const COOLDOWN := 25.0   # segundos entre una actividad y la siguiente (camina un rato entre medio)


static func play_of(item_id: String) -> Dictionary:
	if PLAYS.has(item_id):
		return PLAYS[item_id]
	if Catalog.is_bed(item_id):   # la cama de nube (dibujo propio) descansa como la cama amplia
		return PLAYS["furn_bed"]
	return PLAYS.get(Catalog.shape_of(item_id), {})


static func can_play(item_id: String) -> bool:
	return not play_of(item_id).is_empty()


## "Mochi toca el piano"
static func activity_text(p: Pompon, item_id: String) -> String:
	return "%s %s" % [p.display_name(), play_of(item_id).get("text", "mira " + PomponThoughts._poss(item_id))]


## Lo que dice al ver algo nuevo en su cuarto (los especiales lo dicen con mas emocion).
static func comment(item_id: String, rng: RandomNumberGenerator) -> String:
	var pool: Array = play_of(item_id).get("say", GENERIC_SAY)
	var text: String = pool[rng.randi() % pool.size()]
	if Catalog.is_special(item_id):
		text = "¡Wow! " + text
	return text


## Elige con que jugar entre los objetos del cuarto (`items` = ids colocados en esta habitacion),
## sin repetir el ultimo si hay otros. "" si no hay nada.
static func pick(items: Array, last: String, rng: RandomNumberGenerator, small_baby := false) -> String:
	var options := items.filter(func(id): return can_play(id) and not (small_baby and play_of(id)["pose"] in ["run", "swing"]))
	if options.size() > 1:
		options.erase(last)
	if options.is_empty():
		return ""
	return options[rng.randi() % options.size()]


## Cuanto dura (segundos).
static func duration(item_id: String, rng: RandomNumberGenerator) -> float:
	var secs: Array = play_of(item_id).get("secs", [8.0, 12.0])
	return rng.randf_range(secs[0], secs[1])


## ¿Tiene en su casa algo para descansar (cama, cuna, sofa, puff, cojin...)? Sostiene su comodidad
## y lo hace dormir mejor. (Antes cada especie exigia un mueble propio, como el rascador.)
static func cozy(placed_ids: Array) -> bool:
	for id in placed_ids:
		if id == "furn_crib" or Catalog.is_bed(id) or play_of(id).get("pose", "") in ["sit", "lie"]:
			return true
	return false


## Lo que suma al terminar (comodidad, diversion...).
static func apply_stats(p: Pompon, item_id: String) -> void:
	var stats: Dictionary = play_of(item_id).get("stats", {})
	for s in stats:
		p.add_stat(s, stats[s])
