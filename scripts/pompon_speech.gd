class_name PomponSpeech
extends RefCounted
## Lo que dice el Pompon segun etapa, necesidades, personalidad e inteligencia.

const NEED_LINES := {
	"alimentacion": ["Tengo hambre", "Mi pancita hace ruido", "Quiero comer algo rico"],
	"hidratacion": ["Tengo sed", "Quiero agua", "Agua, por favor"],
	"aseo": ["Estoy sucio", "Quiero bañarme", "Necesito un baño"],
	"diversion": ["Juguemos", "Me aburro", "Quiero jugar"],
	"amor": ["¿Me quieres?", "Mimos, por favor", "¿Estás ahí?"],
}
const BABY_HAPPY := [":)", "Pi pi!", "^_^", "Mmm~", "<3"]
const BABY_NEED := [":(", "Buaaa", "T_T", "Pi... pi..."]

const PERSONALITY_LINES := {
	"Energico": ["¡Vamos a correr!", "¡No puedo quedarme quieto!"],
	"Timido": ["Hola... bajito", "Me da vergüenza"],
	"Curioso": ["¿Qué es eso?", "Quiero explorar"],
	"Gloton": ["Pensaba en comida", "¿Hay algo para picar?"],
	"Artistico": ["Mira, dibujé algo", "Me inspiré hoy"],
}
const SMART_LINES := [
	"Dos más dos son cuatro, lo aprendí hoy",
	"Me gusta resolver patrones contigo",
	"Cada día entiendo más cosas",
]


## Devuelve la frase mas urgente. `pick` permite elegir variante (para pruebas).
static func line(p: Pompon, now: int, pick := -1) -> String:
	var stage := p.stage_index(now)
	if stage == 0:
		return "¡Necesito una cuna para nacer!"
	var need := _most_urgent_need(p)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if stage == 1:  # Bebe: solo sonidos y emoticonos.
		var pool: Array = BABY_NEED if need != "" else BABY_HAPPY
		return pool[(pick if pick >= 0 else rng.randi()) % pool.size()]
	if need != "":
		var lines: Array = NEED_LINES[need]
		return lines[(pick if pick >= 0 else rng.randi()) % lines.size()]
	# Sin urgencias: la inteligencia define la calidad de las respuestas.
	var pool: Array = PERSONALITY_LINES.get(p.personality, ["Hola!"])
	if p.stats["inteligencia"] >= 5.0 and stage >= 2:
		pool = pool + SMART_LINES
	return pool[(pick if pick >= 0 else rng.randi()) % pool.size()]


static func _most_urgent_need(p: Pompon) -> String:
	var worst := ""
	var worst_value := 30.0
	for s in NEED_LINES:
		if p.stats[s] < worst_value:
			worst = s
			worst_value = p.stats[s]
	return worst
