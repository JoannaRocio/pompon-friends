class_name EnglishProblems
extends RefCounted
## Ingles del trabajo en el periodico (la otra materia de la Escuela Pompon).
##
## Tres caminos de 10 niveles: "Palabras" (se ve la palabra en español, muchas con dibujo, y se
## elige como se dice en ingles), "¿Qué significa?" (al reves: la palabra en ingles y su significado)
## y "Frases" (completar una frase corta: am/is/are, a/an, have/has...). Cada palabra trae como se
## pronuncia escrito a la española. El dominio del nivel, los premios y el turno son los mismos que
## en matematicas (ver MathProblems): no se paga por saber, sino por intentarlo.

const TRACKS := ["en_words", "en_meaning", "en_phrases"]
const LABELS := {"en_words": "Palabras", "en_meaning": "¿Qué significa?", "en_phrases": "Frases"}
const MAX_LEVEL := 10

const LEVEL_NAMES := {
	"en_words": ["Colores", "Números", "Animales", "Comida", "La familia", "El cuerpo", "La ropa", "La casa", "La escuela", "La naturaleza"],
	"en_meaning": ["Saludos", "Cómo me siento", "Opuestos", "Acciones", "Días", "El clima", "Lugares", "Juguetes", "Meses", "Preguntas"],
	"en_phrases": ["Am, is, are", "A o an", "Uno y muchos", "Have y has", "He, she, it, they", "There is, there are",
		"Can y can't", "In, on, under", "Likes, plays", "Preguntas"],
}
const FAST_SECONDS := {"en_words": 5.0, "en_meaning": 5.0, "en_phrases": 8.0}

# lo mismo que en matematicas (asi el aula y el turno funcionan igual)
const WINDOW := MathProblems.WINDOW
const HISTORY_KEEP := MathProblems.HISTORY_KEEP
const QUESTIONS_PER_SHIFT := MathProblems.QUESTIONS_PER_SHIFT
const SHIFT_SECONDS := MathProblems.SHIFT_SECONDS
const FULL_SHIFT_BONUS := MathProblems.FULL_SHIFT_BONUS
const LEVEL_UP_BONUS := MathProblems.LEVEL_UP_BONUS

static var current_track := "en_words"   # camino elegido en el aula

# Palabras: "ingles|español|como se pronuncia|dibujo" (dibujo opcional, ver EnglishPicture).
const WORDS := [
	["red|rojo|red|c:ef4444", "blue|azul|blu|c:3b82f6", "yellow|amarillo|iélou|c:facc15", "green|verde|grin|c:22c55e",
		"orange|naranja|óranch|c:fb923c", "pink|rosa|pink|c:f472b6", "purple|violeta|pérpol|c:a855f7",
		"black|negro|blak|c:2b2b2b", "white|blanco|uáit|c:ffffff", "brown|marrón|bráun|c:92633a"],
	["one|uno|uán|n:1", "two|dos|tu|n:2", "three|tres|zri|n:3", "four|cuatro|for|n:4", "five|cinco|fáiv|n:5",
		"six|seis|siks|n:6", "seven|siete|séven|n:7", "eight|ocho|éit|n:8", "nine|nueve|náin|n:9", "ten|diez|ten|n:10"],
	["cat|gato|kat|cat", "dog|perro|dog|dog", "fish|pez|fish|fish", "bird|pájaro|berd|bird", "rabbit|conejo|rábit|rabbit",
		"horse|caballo|jors|", "cow|vaca|káu|", "duck|pato|dak|duck", "mouse|ratón|máus|mouse", "bear|oso|ber|bear"],
	["apple|manzana|ápol|apple", "banana|banana|banána|banana", "bread|pan|bred|bread", "milk|leche|milk|milk",
		"water|agua|uóter|water", "cheese|queso|chis|cheese", "egg|huevo|eg|egg", "cake|pastel|kéik|cake",
		"juice|jugo|yus|", "cookie|galleta|kúki|cookie"],
	["mother|mamá|máder|", "father|papá|fáder|", "sister|hermana|síster|", "brother|hermano|bráder|", "baby|bebé|béibi|",
		"grandmother|abuela|gránmader|", "grandfather|abuelo|gránfader|", "family|familia|fámili|", "friend|amigo|frend|", "aunt|tía|ant|"],
	["head|cabeza|jed|", "eyes|ojos|áis|", "nose|nariz|nóus|", "mouth|boca|máuz|", "ears|orejas|íers|",
		"hands|manos|jands|", "feet|pies|fit|", "hair|pelo|jer|", "arm|brazo|arm|", "leg|pierna|leg|"],
	["shirt|camiseta|shert|shirt", "pants|pantalón|pants|pants", "shoes|zapatos|shus|", "hat|sombrero|jat|hat",
		"dress|vestido|dres|dress", "socks|calcetines|soks|", "jacket|chaqueta|yáket|", "skirt|falda|skert|",
		"glasses|anteojos|glásis|glasses", "scarf|bufanda|skarf|"],
	["house|casa|jáus|house", "door|puerta|dor|door", "window|ventana|uíndou|window", "bed|cama|bed|bed",
		"table|mesa|téibol|table", "chair|silla|cher|chair", "kitchen|cocina|kítchen|", "lamp|lámpara|lamp|lamp",
		"sofa|sofá|sóufa|", "bathroom|baño|bázrum|"],
	["book|libro|buk|book", "pencil|lápiz|pénsil|pencil", "school|escuela|skul|", "teacher|maestro|tícher|",
		"desk|pupitre|desk|", "eraser|goma de borrar|iréiser|", "ruler|regla|rúler|ruler", "backpack|mochila|bákpak|",
		"notebook|cuaderno|nóutbuk|", "scissors|tijeras|sísors|"],
	["sun|sol|san|sun", "moon|luna|mun|moon", "star|estrella|star|star", "tree|árbol|tri|tree", "flower|flor|fláuer|flower",
		"rain|lluvia|réin|rain", "sea|mar|si|", "sky|cielo|skái|", "cloud|nube|kláud|cloud", "snow|nieve|snóu|snow"],
]

# ¿Qué significa?: "ingles|español|como se pronuncia".
const MEANINGS := [
	["hello|hola|jelóu", "goodbye|adiós|gudbái", "please|por favor|plis", "thank you|gracias|zénkiu", "yes|sí|iés",
		"good morning|buenos días|gud mórning", "good night|buenas noches|gud náit", "sorry|perdón|sóri",
		"how are you?|¿cómo estás?|jáu ar iú", "see you!|¡nos vemos!|si iú"],
	["happy|feliz|jápi", "sad|triste|sad", "angry|enojado|ángri", "tired|cansado|táierd", "scared|asustado|skerd",
		"hungry|con hambre|jángri", "sleepy|con sueño|slípi", "sick|enfermo|sik", "surprised|sorprendido|sorpráisd", "bored|aburrido|bord"],
	["big|grande|big", "small|pequeño|smol", "hot|caliente|jot", "cold|frío|kóuld", "fast|rápido|fast",
		"slow|lento|slóu", "tall|alto|tol", "short|bajo|short", "new|nuevo|niú", "old|viejo|óuld"],
	["run|correr|ran", "jump|saltar|yamp", "eat|comer|it", "drink|beber|drink", "sleep|dormir|slip",
		"read|leer|rid", "write|escribir|ráit", "sing|cantar|sing", "dance|bailar|dans", "swim|nadar|suím"],
	["Monday|lunes|mándei", "Tuesday|martes|tiúsdei", "Wednesday|miércoles|uénsdei", "Thursday|jueves|zérsdei",
		"Friday|viernes|fráidei", "Saturday|sábado|sáturdei", "Sunday|domingo|sándei", "today|hoy|tudéi",
		"tomorrow|mañana|tumórou", "week|semana|uík"],
	["weather|el clima|uéder", "sunny|soleado|sáni", "rainy|lluvioso|réini", "windy|ventoso|uíndi", "cloudy|nublado|kláudi",
		"rainbow|arcoíris|réinbou", "storm|tormenta|storm", "summer|verano|sámer", "winter|invierno|uínter", "spring|primavera|spring"],
	["park|parque|park", "beach|playa|bich", "city|ciudad|síti", "store|tienda|stor", "hospital|hospital|jóspital",
		"zoo|zoológico|zu", "library|biblioteca|láibreri", "street|calle|strit", "farm|granja|farm", "garden|jardín|gárden"],
	["ball|pelota|bol", "doll|muñeca|dol", "kite|cometa|káit", "game|juego|guéim", "toy|juguete|tói",
		"puzzle|rompecabezas|pásol", "bike|bicicleta|báik", "robot|robot|róubot", "blocks|bloques|bloks", "drum|tambor|dram"],
	["January|enero|yániueri", "February|febrero|fébrueri", "March|marzo|march", "April|abril|éipril", "May|mayo|méi",
		"June|junio|yun", "July|julio|yulái", "August|agosto|ógost", "September|septiembre|septémber",
		"October|octubre|októuber", "November|noviembre|novémber", "December|diciembre|disémber"],
	["what?|¿qué?|uát", "where?|¿dónde?|uér", "who?|¿quién?|ju", "when?|¿cuándo?|uén", "why?|¿por qué?|uái",
		"how many?|¿cuántos?|jáu méni", "how old are you?|¿cuántos años tienes?|jáu óuld ar iú",
		"what's your name?|¿cómo te llamas?|uáts iór néim", "what time is it?|¿qué hora es?|uát táim is it",
		"where are you from?|¿de dónde eres?|uér ar iú from"],
]

# Frases: "frase con ___|respuesta|opciones separadas por coma|en español".
const PHRASES := [
	["I ___ happy.|am|am,is,are|Estoy feliz.", "You ___ my friend.|are|am,is,are|Eres mi amigo.",
		"She ___ a teacher.|is|am,is,are|Ella es maestra.", "He ___ tall.|is|am,is,are|Él es alto.",
		"We ___ friends.|are|am,is,are|Somos amigos.", "It ___ a cat.|is|am,is,are|Es un gato.",
		"They ___ at school.|are|am,is,are|Están en la escuela.", "I ___ ten years old.|am|am,is,are|Tengo diez años."],
	["This is ___ apple.|an|a,an|Esta es una manzana.", "This is ___ dog.|a|a,an|Este es un perro.",
		"It is ___ egg.|an|a,an|Es un huevo.", "I have ___ ball.|a|a,an|Tengo una pelota.",
		"She has ___ umbrella.|an|a,an|Ella tiene un paraguas.", "He is ___ boy.|a|a,an|Él es un niño.",
		"I see ___ elephant.|an|a,an|Veo un elefante.", "It is ___ book.|a|a,an|Es un libro."],
	["One cat, two ___.|cats|cat,cats,cates|Un gato, dos gatos.", "One child, two ___.|children|childs,children,childrens|Un niño, dos niños.",
		"One mouse, two ___.|mice|mouses,mice,mices|Un ratón, dos ratones.", "One box, two ___.|boxes|boxs,boxes,box|Una caja, dos cajas.",
		"One baby, two ___.|babies|babys,babies,baby|Un bebé, dos bebés.", "One foot, two ___.|feet|foots,feet,feets|Un pie, dos pies.",
		"One book, three ___.|books|book,books,bookes|Un libro, tres libros.", "One man, two ___.|men|mans,men,mens|Un hombre, dos hombres."],
	["I ___ a dog.|have|have,has|Tengo un perro.", "She ___ a cat.|has|have,has|Ella tiene un gato.",
		"We ___ a big house.|have|have,has|Tenemos una casa grande.", "He ___ blue eyes.|has|have,has|Él tiene ojos azules.",
		"They ___ two balls.|have|have,has|Ellos tienen dos pelotas.", "My mom ___ a car.|has|have,has|Mi mamá tiene un auto.",
		"You ___ a nice hat.|have|have,has|Tienes un sombrero lindo.", "It ___ four legs.|has|have,has|Tiene cuatro patas."],
	["Ana is my friend. ___ is nice.|She|He,She,It|Ana es mi amiga. Ella es simpática.",
		"Tom is ten. ___ is tall.|He|He,She,It|Tom tiene diez años. Él es alto.",
		"The cat is small. ___ is cute.|It|He,She,It|El gato es chiquito. Es tierno.",
		"Ana and Tom are here. ___ are happy.|They|He,She,They|Ana y Tom están aquí. Están felices.",
		"My dad is a doctor. ___ works a lot.|He|He,She,It|Mi papá es doctor. Él trabaja mucho.",
		"The ball is red. ___ is new.|It|He,She,It|La pelota es roja. Es nueva.",
		"My sister likes music. ___ sings.|She|He,She,It|A mi hermana le gusta la música. Ella canta.",
		"The dogs are big. ___ run fast.|They|It,She,They|Los perros son grandes. Corren rápido."],
	["There ___ a cat on the bed.|is|is,are|Hay un gato en la cama.", "There ___ two dogs in the park.|are|is,are|Hay dos perros en el parque.",
		"There ___ an apple on the table.|is|is,are|Hay una manzana en la mesa.", "There ___ three books.|are|is,are|Hay tres libros.",
		"There ___ many stars in the sky.|are|is,are|Hay muchas estrellas en el cielo.", "There ___ a bird in the tree.|is|is,are|Hay un pájaro en el árbol.",
		"There ___ five chairs.|are|is,are|Hay cinco sillas.", "There ___ a big tree.|is|is,are|Hay un árbol grande."],
	["Fish ___ swim.|can|can,can't|Los peces pueden nadar.", "Dogs ___ fly.|can't|can,can't|Los perros no pueden volar.",
		"Birds ___ fly.|can|can,can't|Los pájaros pueden volar.", "A cat ___ read.|can't|can,can't|Un gato no puede leer.",
		"I ___ jump.|can|can,can't|Puedo saltar.", "A baby ___ drive a car.|can't|can,can't|Un bebé no puede manejar un auto.",
		"Horses ___ run fast.|can|can,can't|Los caballos pueden correr rápido.", "Fish ___ walk.|can't|can,can't|Los peces no pueden caminar."],
	["The fish is ___ the water.|in|in,on,under|El pez está dentro del agua.", "The book is ___ the table.|on|in,on,under|El libro está encima de la mesa.",
		"The cat is ___ the bed.|under|in,on,under|El gato está debajo de la cama.", "The milk is ___ the glass.|in|in,on,under|La leche está dentro del vaso.",
		"The hat is ___ my head.|on|in,on,under|El sombrero está encima de mi cabeza.", "The ball is ___ the chair.|under|in,on,under|La pelota está debajo de la silla.",
		"The toys are ___ the box.|in|in,on,under|Los juguetes están dentro de la caja.", "The lamp is ___ the desk.|on|in,on,under|La lámpara está encima del escritorio."],
	["She ___ apples.|likes|like,likes|A ella le gustan las manzanas.", "I ___ milk.|like|like,likes|Me gusta la leche.",
		"He ___ to school.|goes|go,goes|Él va a la escuela.", "We ___ every day.|play|play,plays|Jugamos todos los días.",
		"My cat ___ a lot.|sleeps|sleep,sleeps|Mi gato duerme mucho.", "They ___ English.|speak|speak,speaks|Ellos hablan inglés.",
		"Tom ___ football.|plays|play,plays|Tom juega al fútbol.", "You ___ very well.|sing|sing,sings|Cantas muy bien."],
	["___ you like pizza?|Do|Do,Does,Is|¿Te gusta la pizza?", "___ she have a dog?|Does|Do,Does,Is|¿Ella tiene un perro?",
		"___ he your brother?|Is|Do,Is,Are|¿Él es tu hermano?", "___ they at home?|Are|Is,Are,Do|¿Están en casa?",
		"___ it a cat?|Is|Is,Are,Does|¿Es un gato?", "___ he play the piano?|Does|Do,Does,Is|¿Él toca el piano?",
		"___ we friends?|Are|Is,Are,Do|¿Somos amigos?", "___ your mom work?|Does|Do,Does,Are|¿Tu mamá trabaja?"],
]

# La regla de cada nivel de frases (leccion y explicacion cuando se falla).
const RULES := [
	"Con I va am. Con he, she, it va is. Con you, we, they va are.",
	"Antes de a, e, i, o, u se dice an: an apple. Si no, a: a dog.",
	"Para más de uno se agrega s: cat → cats. ¡Algunas cambian! child → children.",
	"Con I, you, we, they va have. Con he, she, it va has.",
	"Ella es she, él es he, una cosa o un animal es it, y varios son they.",
	"There is: hay uno. There are: hay varios.",
	"can = puede. can't = no puede.",
	"in = dentro. on = encima. under = debajo.",
	"Con he, she, it el verbo lleva s: she likes, he plays.",
	"Do con I, you, we, they. Does con he, she, it. Con ser o estar: is o are.",
]
const LESSON_TRICKS := {
	"en_words": "Aprende cómo se dicen en inglés.",
	"en_meaning": "Aprende qué significan.",
}


# ------------------------------------------------------------------ utilidades

static func level_name(track: String, level: int) -> String:
	return LEVEL_NAMES[track][clampi(level, 1, MAX_LEVEL) - 1]


static func fast_seconds(track: String, _level: int) -> float:
	return FAST_SECONDS[track]


## Las palabras o frases de un nivel, ya separadas en diccionarios.
static func items(track: String, level: int) -> Array:
	level = clampi(level, 1, MAX_LEVEL)
	var out: Array = []
	match track:
		"en_words":
			for line in WORDS[level - 1]:
				var f := String(line).split("|")
				out.append({"en": f[0], "es": f[1], "say": f[2], "pic": f[3]})
		"en_meaning":
			for line in MEANINGS[level - 1]:
				var f := String(line).split("|")
				out.append({"en": f[0], "es": f[1], "say": f[2], "pic": ""})
		"en_phrases":
			for line in PHRASES[level - 1]:
				var f := String(line).split("|")
				out.append({"en": f[0], "answer": f[1], "options": Array(f[2].split(",")), "es": f[3]})
	return out


## Identifica una palabra o frase (para recordar las que se fallan): "nivel:palabra".
static func item_key(level: int, item: Dictionary) -> String:
	return "%d:%s" % [level, item["en"]]


static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	MathProblems._shuffle(list, rng)


## Arma la pregunta de una palabra o frase.
static func build_problem(track: String, level: int, item: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var p := {"track": track, "level": level, "key": item_key(level, item), "es": item["es"], "en": item["en"]}
	var all := items(track, level)
	match track:
		"en_words", "en_meaning":
			var to_english := track == "en_words"
			var field := "en" if to_english else "es"
			var others := all.filter(func(it): return it[field] != item[field]).map(func(it): return it[field])
			_shuffle(others, rng)
			var options: Array = [item[field], others[0], others[1]]
			_shuffle(options, rng)
			p["options"] = options
			p["answer"] = item[field]
			p["say"] = item["say"]
			p["pic"] = item["pic"]
			p["prompt"] = item["es"] if to_english else item["en"]
			p["ask"] = "¿Cómo se dice en inglés?" if to_english else "¿Qué significa?"
			p["text"] = "%s = %s" % [item["en"], item["es"]]
		"en_phrases":
			var options2: Array = item["options"].duplicate()
			_shuffle(options2, rng)
			p["options"] = options2
			p["answer"] = item["answer"]
			p["say"] = ""
			p["pic"] = ""
			p["prompt"] = item["en"]
			p["ask"] = item["es"]
			p["text"] = String(item["en"]).replace("___", item["answer"])
	return p


## Busca una palabra o frase por su clave en cualquier nivel del camino ({} si ya no existe).
static func find_item(track: String, key: String) -> Dictionary:
	var parts := key.split(":", true, 1)
	if parts.size() < 2 or not parts[0].is_valid_int():
		return {}
	var level := int(parts[0])
	if level < 1 or level > MAX_LEVEL:
		return {}
	for it in items(track, level):
		if it["en"] == parts[1]:
			return it
	return {}


## Elige la proxima pregunta del turno: a veces repasa una que se fallo antes y si no, una del nivel
## que no haya salido hace poco. `weak` = [{"key", "streak"}].
static func pick_problem(track: String, level: int, rng: RandomNumberGenerator, weak: Array, recent: Array) -> Dictionary:
	if not weak.is_empty() and rng.randf() < 0.3:
		var options := weak.filter(func(w): return not recent.has(w["key"]))
		if not options.is_empty():
			options.sort_custom(func(x, y): return x["streak"] < y["streak"])
			var w: Dictionary = options[0]
			var item := find_item(track, w["key"])
			if not item.is_empty():
				var p := build_problem(track, int(String(w["key"]).get_slice(":", 0)), item, rng)
				p["review"] = true
				return p
	var pool := items(track, level)
	var fresh := pool.filter(func(it): return not recent.has(item_key(level, it)))
	if fresh.is_empty():
		fresh = pool
	return build_problem(track, level, fresh[rng.randi() % fresh.size()], rng)


## Lo que se muestra cuando se falla (la pronunciacion y la frase completa ya se ven en el examen).
static func explanation(p: Dictionary) -> String:
	match p["track"]:
		"en_words":
			return "%s en inglés es %s." % [_cap(p["es"]), p["en"]]
		"en_meaning":
			return "%s quiere decir %s." % [_cap(p["en"]), p["es"]]
	return RULES[clampi(int(p["level"]), 1, MAX_LEVEL) - 1]


## Primera letra en mayuscula (sin tocar el resto: "¿cómo estás?" queda igual).
static func _cap(text: String) -> String:
	if text == "" or text[0] in ["¿", "¡"]:
		return text
	return text[0].to_upper() + text.substr(1)


# ------------------------------------------------------------------- lecciones

## Lo que se muestra antes de practicar un nivel: {"title", "lines"} (como MathProblems.lesson).
static func lesson(track: String, level: int) -> Dictionary:
	level = clampi(level, 1, MAX_LEVEL)
	var title := "Nivel %d: %s" % [level, level_name(track, level)]
	var list := items(track, level)
	var lines: Array = []
	if track == "en_phrases":
		var first: String = RULES[level - 1]
		for i in 2:
			first += "\n" + String(list[i]["en"]).replace("___", list[i]["answer"])
		lines.append(first)
		return {"title": title, "lines": lines}
	var head: String = LESSON_TRICKS[track]
	for i in 3:
		head += "\n%s = %s" % [list[i]["en"], list[i]["es"]]
	lines.append(head)
	var rest: Array = []
	for i in range(3, list.size()):
		rest.append("%s = %s" % [list[i]["en"], list[i]["es"]])
	for i in range(0, rest.size(), 3):
		lines.append("  ·  ".join(rest.slice(i, i + 3)))
	return {"title": title, "lines": lines}


# -------------------------------------------------------------- nota y dominio

static func grade(correct: int, total: int) -> Dictionary:
	var g := MathProblems.grade(correct, total)
	var note: int = g["note"]
	if note >= 9:
		g["message"] = "¡Hablas inglés como un campeón!"
	elif note >= 7:
		g["message"] = "¡Casi perfecto! Keep going!"
	elif note >= 5:
		g["message"] = "Vas por buen camino. ¡Practicando se aprende!"
	elif note >= 3:
		g["message"] = "Cada palabra que repasas se te queda."
	return g


static func evaluate(track: String, level: int, history: Array) -> Dictionary:
	return MathProblems.judge(fast_seconds(track, level), level, history, "respuestas")


static func good_streak(track: String, level: int, history: Array) -> int:
	return MathProblems.streak(fast_seconds(track, level), history)
