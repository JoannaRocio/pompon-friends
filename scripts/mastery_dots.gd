class_name MasteryDots
extends Control
## Las ultimas 8 respuestas de un nivel como puntitos: verde = bien y rapido, amarillo = bien pero
## despacio, rojo = error, vacio = todavia falta. Con 8 verdes seguidos se domina el nivel.

const GREEN := Color("6bbf7a")
const YELLOW := Color("f2c14e")
const RED := Color("e57373")
const EMPTY := Color("efe6d8")

var history: Array = []
var fast_limit := 5.0


func set_data(entries: Array, fast_seconds: float) -> void:
	history = entries
	fast_limit = fast_seconds
	queue_redraw()


func _draw() -> void:
	var n := MathProblems.WINDOW
	var recent := history.slice(maxi(0, history.size() - n), history.size())
	var step := minf(size.x / n, size.y * 1.3)
	var r := step * 0.36
	var x0 := (size.x - step * n) * 0.5 + step * 0.5
	for i in n:
		var c := Vector2(x0 + step * i, size.y * 0.5)
		var color := EMPTY
		if i < recent.size():
			var h: Dictionary = recent[i]
			if not h["c"]:
				color = RED
			elif float(h["t"]) <= fast_limit:
				color = GREEN
			else:
				color = YELLOW
		draw_circle(c, r, color)
		draw_arc(c, r, 0.0, TAU, 20, Color("5b3a4a"), 2.5, true)
