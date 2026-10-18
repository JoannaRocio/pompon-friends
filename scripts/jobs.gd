class_name Jobs
extends RefCounted
## Los trabajos que se ofrecen en el periodico. Hoy solo el de matematicas esta disponible;
## ingles y geografia estan bloqueados ("proximamente") y se agregaran despues.
## El titulo depende de como el jugador quiere que lo llamen (profesora, profesor o profesor/a).

const JOBS := [
	{
		"id": "math", "available": true, "scene": "res://scenes/job_menu.tscn", "color": "e0609e",
		"title": {"f": "Profesora de Matemáticas", "m": "Profesor de Matemáticas", "n": "Profesor/a de Matemáticas"},
		"blurb": "Resuelve cuentas con tus alumnos",
	},
	{
		"id": "english", "available": false, "scene": "", "color": "5aa9e6",
		"title": {"f": "Profesora de Inglés", "m": "Profesor de Inglés", "n": "Profesor/a de Inglés"},
		"blurb": "Palabras y frases",
	},
	{
		"id": "geography", "available": false, "scene": "", "color": "4cb782",
		"title": {"f": "Profesora de Geografía", "m": "Profesor de Geografía", "n": "Profesor/a de Geografía"},
		"blurb": "Países y mapas",
	},
]

# Pronombres del jugador (se pregunta una vez); sin elegir, el puesto dice "Profesor/a".
const TITLE_CHOICES := [
	{"key": "f", "label": "Soy ella"},
	{"key": "m", "label": "Soy él"},
]


static func get_job(id: String) -> Dictionary:
	for j in JOBS:
		if j["id"] == id:
			return j
	return {}


## "f", "m" o "n" (neutro). Cualquier otra cosa cuenta como neutro.
static func normalize(gender: String) -> String:
	return gender if gender in ["f", "m", "n"] else "n"


static func title(job_id: String, gender: String) -> String:
	var job := get_job(job_id)
	return "" if job.is_empty() else job["title"][normalize(gender)]


## Palabra suelta: "Profesora", "Profesor" o "Profesor/a".
static func teacher_word(gender: String) -> String:
	match normalize(gender):
		"f":
			return "Profesora"
		"m":
			return "Profesor"
	return "Profesor/a"


## "Profesora Ana", "Profesor Ana" o "Profesor/a Ana" (sin nombre: solo la palabra).
static func full_title(gender: String, player_name: String = "") -> String:
	var word := teacher_word(gender)
	return word if player_name.strip_edges() == "" else "%s %s" % [word, player_name.strip_edges()]


static func greeting(gender: String, player_name: String = "") -> String:
	var who := player_name.strip_edges()
	match normalize(gender):
		"f":
			return "¡Bienvenida a la escuela, profesora%s!" % ("" if who == "" else " " + who)
		"m":
			return "¡Bienvenido a la escuela, profesor%s!" % ("" if who == "" else " " + who)
	return "¡Te damos la bienvenida a la escuela%s!" % ("" if who == "" else ", " + who)


# ------------------------------------------------------------------ carrera (niveles de profesor/a)
# Se asciende por turnos terminados en total: nivel 2 a los 5, nivel 3 a los 10, nivel 4 a los 20 y
# despues uno cada 10 turnos mas, hasta el nivel 100. La paga por turno sube de 50 (nivel 1) a 500.

const CAREER_MAX := 100
const PAY_MIN := 50
const PAY_MAX := 500


## Turnos totales que hacen falta para llegar a `level`.
static func shifts_for_level(level: int) -> int:
	level = clampi(level, 1, CAREER_MAX)
	match level:
		1:
			return 0
		2:
			return 5
		3:
			return 10
	return 20 + 10 * (level - 4)


static func career_level(shifts: int) -> int:
	if shifts < 5:
		return 1
	if shifts < 10:
		return 2
	if shifts < 20:
		return 3
	return mini(CAREER_MAX, 4 + (shifts - 20) / 10)


## Monedas por turno en ese nivel (sube parejo de PAY_MIN a PAY_MAX).
static func pay_for_level(level: int) -> int:
	var k := float(clampi(level, 1, CAREER_MAX) - 1) / float(CAREER_MAX - 1)
	return int(round(lerpf(PAY_MIN, PAY_MAX, k)))
