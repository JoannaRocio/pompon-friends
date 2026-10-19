class_name FlagArt
extends Control
## Banderas dibujadas por codigo (proporcion 3:2), para el trabajo de Geografia. Cada bandera es una
## lista de pasos sencillos (franjas, cruces, circulos, estrellas...); los escudos complicados se
## simplifican a un circulo o una estrella para que se reconozcan de un vistazo.
## Coordenadas en fracciones de la bandera (x del ancho, y del alto); los radios en fraccion del alto.

const OUT := Color("5b3a4a")
const C := {
	"red": "d52b1e", "white": "ffffff", "blue": "0b3d91", "sky": "74acdf", "yellow": "fcd116", "green": "009b3a",
	"black": "1a1a1a", "gold": "f4b400", "orange": "ff883e", "navy": "002868", "darkgreen": "006233", "brown": "8b5a2b",
	"saffron": "ff9933", "lightblue": "4189dd", "crimson": "c8102e", "darkred": "a51931", "teal": "00a3a1",
}

const FLAGS := {
	# Sudamerica
	"argentina": [["h", ["sky", "white", "sky"]], ["circle", 0.5, 0.5, 0.11, "gold"]],
	"brasil": [["h", ["green"]], ["rhombus", "yellow", 0.1], ["circle", 0.5, 0.5, 0.22, "navy"]],
	"chile": [["h", ["white", "red"]], ["rect", 0.0, 0.0, 0.333, 0.5, "blue"], ["star", 0.167, 0.25, 0.12, "white"]],
	"uruguay": [["h", ["white", "lightblue", "white", "lightblue", "white", "lightblue", "white", "lightblue", "white"]],
		["rect", 0.0, 0.0, 0.38, 0.556, "white"], ["circle", 0.19, 0.278, 0.15, "gold"]],
	"paraguay": [["h", ["red", "white", "blue"]], ["ring", 0.5, 0.5, 0.11, "black", 0.025]],
	"peru": [["v", ["red", "white", "red"]]],
	"colombia": [["h", ["yellow", "blue", "red"], [2, 1, 1]]],
	"venezuela": [["h", ["yellow", "blue", "red"]], ["arc_dots", 0.5, 0.62, 0.22, "white", 8]],
	"ecuador": [["h", ["yellow", "blue", "red"], [2, 1, 1]], ["circle", 0.5, 0.45, 0.12, "brown"]],
	# Norte y Centroamerica
	"mexico": [["v", ["darkgreen", "white", "crimson"]], ["circle", 0.5, 0.5, 0.13, "brown"]],
	"eeuu": [["h", ["crimson", "white", "crimson", "white", "crimson", "white", "crimson", "white", "crimson", "white", "crimson", "white", "crimson"]],
		["rect", 0.0, 0.0, 0.4, 0.54, "navy"], ["dots", 0.0, 0.0, 0.4, 0.54, "white", 6, 5]],
	"canada": [["v", ["red", "white", "red"], [1, 2, 1]], ["star", 0.5, 0.5, 0.3, "red", 7]],
	"cuba": [["h", ["blue", "white", "blue", "white", "blue"]], ["tri", "red", 0.43], ["star", 0.14, 0.5, 0.12, "white"]],
	"costa_rica": [["h", ["blue", "white", "red", "white", "blue"], [1, 1, 2, 1, 1]]],
	"panama": [["rect", 0.0, 0.0, 0.5, 0.5, "white"], ["rect", 0.5, 0.0, 0.5, 0.5, "red"], ["rect", 0.0, 0.5, 0.5, 0.5, "blue"],
		["rect", 0.5, 0.5, 0.5, 0.5, "white"], ["star", 0.25, 0.25, 0.1, "blue"], ["star", 0.75, 0.75, 0.1, "red"]],
	"guatemala": [["v", ["sky", "white", "sky"]], ["circle", 0.5, 0.5, 0.11, "green"]],
	"honduras": [["h", ["blue", "white", "blue"]], ["star", 0.5, 0.5, 0.06, "blue"], ["star", 0.4, 0.43, 0.05, "blue"],
		["star", 0.6, 0.43, 0.05, "blue"], ["star", 0.4, 0.57, 0.05, "blue"], ["star", 0.6, 0.57, 0.05, "blue"]],
	"jamaica": [["h", ["green"]], ["side_tris", "black"], ["saltire", "yellow", 0.13]],
	"dominicana": [["rect", 0.0, 0.0, 0.5, 0.5, "blue"], ["rect", 0.5, 0.0, 0.5, 0.5, "red"], ["rect", 0.0, 0.5, 0.5, 0.5, "red"],
		["rect", 0.5, 0.5, 0.5, 0.5, "blue"], ["cross", "white", 0.16]],
	# Europa
	"espana": [["h", ["red", "yellow", "red"], [1, 2, 1]]],
	"francia": [["v", ["blue", "white", "red"]]],
	"italia": [["v", ["green", "white", "red"]]],
	"alemania": [["h", ["black", "red", "gold"]]],
	"portugal": [["v", ["darkgreen", "red"], [2, 3]], ["circle", 0.4, 0.5, 0.16, "gold"]],
	"reino_unido": [["union", 0.0, 0.0, 1.0, 1.0]],
	"irlanda": [["v", ["green", "white", "orange"]]],
	"paises_bajos": [["h", ["red", "white", "blue"]]],
	"suecia": [["h", ["lightblue"]], ["nordic", "yellow", 0.2, 0.36]],
	"grecia": [["h", ["lightblue", "white", "lightblue", "white", "lightblue", "white", "lightblue", "white", "lightblue"]],
		["rect", 0.0, 0.0, 0.37, 0.556, "lightblue"], ["rect", 0.0, 0.222, 0.37, 0.111, "white"], ["rect", 0.148, 0.0, 0.074, 0.556, "white"]],
	"suiza": [["h", ["red"]], ["rect", 0.42, 0.2, 0.16, 0.6, "white"], ["rect", 0.28, 0.4, 0.44, 0.2, "white"]],
	"rusia": [["h", ["white", "blue", "red"]]],
	# Asia
	"japon": [["h", ["white"]], ["circle", 0.5, 0.5, 0.3, "crimson"]],
	"china": [["h", ["red"]], ["star", 0.17, 0.27, 0.15, "yellow"], ["star", 0.33, 0.1, 0.05, "yellow"], ["star", 0.4, 0.2, 0.05, "yellow"],
		["star", 0.4, 0.35, 0.05, "yellow"], ["star", 0.33, 0.45, 0.05, "yellow"]],
	"corea_sur": [["h", ["white"]], ["taeguk", 0.5, 0.5, 0.25], ["bars", "black"]],
	"india": [["h", ["saffron", "white", "green"]], ["ring", 0.5, 0.5, 0.12, "navy", 0.02]],
	"tailandia": [["h", ["red", "white", "navy", "white", "red"], [1, 1, 2, 1, 1]]],
	"vietnam": [["h", ["red"]], ["star", 0.5, 0.5, 0.3, "yellow"]],
	"indonesia": [["h", ["red", "white"]]],
	"filipinas": [["h", ["blue", "red"]], ["tri", "white", 0.45], ["circle", 0.14, 0.5, 0.1, "gold"]],
	"turquia": [["h", ["red"]], ["crescent", 0.38, 0.5, 0.25, "white", "red"], ["star", 0.55, 0.5, 0.1, "white"]],
	"banglades": [["h", ["darkgreen"]], ["circle", 0.45, 0.5, 0.3, "red"]],
	# Africa y Oceania
	"egipto": [["h", ["red", "white", "black"]], ["circle", 0.5, 0.5, 0.1, "gold"]],
	"marruecos": [["h", ["darkred"]], ["star", 0.5, 0.5, 0.25, "darkgreen"]],
	"nigeria": [["v", ["green", "white", "green"]]],
	"ghana": [["h", ["red", "yellow", "green"]], ["star", 0.5, 0.5, 0.14, "black"]],
	"kenia": [["h", ["black", "white", "red", "white", "green"], [6, 1, 6, 1, 6]], ["ellipse", 0.5, 0.5, 0.1, 0.32, "red"]],
	"senegal": [["v", ["green", "yellow", "red"]], ["star", 0.5, 0.5, 0.13, "green"]],
	"etiopia": [["h", ["green", "yellow", "red"]], ["circle", 0.5, 0.5, 0.2, "blue"], ["star", 0.5, 0.5, 0.13, "yellow"]],
	"australia": [["h", ["navy"]], ["union", 0.0, 0.0, 0.5, 0.5], ["star", 0.25, 0.75, 0.12, "white", 7], ["star", 0.75, 0.25, 0.06, "white", 7],
		["star", 0.65, 0.5, 0.06, "white", 7], ["star", 0.83, 0.45, 0.06, "white", 7], ["star", 0.75, 0.82, 0.06, "white", 7]],
	"nueva_zelanda": [["h", ["navy"]], ["union", 0.0, 0.0, 0.5, 0.5], ["star", 0.75, 0.28, 0.07, "red"], ["star", 0.68, 0.5, 0.07, "red"],
		["star", 0.84, 0.46, 0.07, "red"], ["star", 0.75, 0.78, 0.08, "red"]],
	"madagascar": [["h", ["red", "green"]], ["rect", 0.0, 0.0, 0.333, 1.0, "white"]],
}

var flag := ""


static func has_flag(id: String) -> bool:
	return FLAGS.has(id)


static func _col(name) -> Color:
	return Color(C.get(name, name))


func show_flag(id: String) -> void:
	flag = id
	queue_redraw()


func _draw() -> void:
	if flag == "":
		return
	var w := minf(size.x, size.y * 1.5)
	var r := Rect2((size - Vector2(w, w / 1.5)) * 0.5, Vector2(w, w / 1.5))
	draw_flag(self, r, flag)


## Dibuja la bandera `id` en `r`.
static func draw_flag(cv: CanvasItem, r: Rect2, id: String) -> void:
	for op in FLAGS.get(id, []):
		_op(cv, r, op)
	cv.draw_rect(r, OUT, false, maxf(2.0, r.size.y * 0.025))


static func _p(r: Rect2, x: float, y: float) -> Vector2:
	return r.position + Vector2(x * r.size.x, y * r.size.y)


static func _stripes(cv: CanvasItem, r: Rect2, cols: Array, weights: Array, vertical: bool) -> void:
	var total := 0.0
	for i in cols.size():
		total += float(weights[i]) if i < weights.size() else 1.0
	var at := 0.0
	for i in cols.size():
		var k := (float(weights[i]) if i < weights.size() else 1.0) / total
		if vertical:
			cv.draw_rect(Rect2(r.position + Vector2(at * r.size.x, 0), Vector2(k * r.size.x + 0.5, r.size.y)), _col(cols[i]))
		else:
			cv.draw_rect(Rect2(r.position + Vector2(0, at * r.size.y), Vector2(r.size.x, k * r.size.y + 0.5)), _col(cols[i]))
		at += k


static func _star_pts(c: Vector2, rad: float, points := 5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		var a := -PI / 2.0 + PI * i / points
		pts.append(c + Vector2(cos(a), sin(a)) * (rad if i % 2 == 0 else rad * 0.42))
	return pts


static func _op(cv: CanvasItem, r: Rect2, op: Array) -> void:
	var h := r.size.y
	match op[0]:
		"h":
			_stripes(cv, r, op[1], op[2] if op.size() > 2 else [], false)
		"v":
			_stripes(cv, r, op[1], op[2] if op.size() > 2 else [], true)
		"rect":
			cv.draw_rect(Rect2(_p(r, op[1], op[2]), Vector2(op[3] * r.size.x, op[4] * h)), _col(op[5]))
		"circle":
			cv.draw_circle(_p(r, op[1], op[2]), op[3] * h, _col(op[4]))
		"ellipse":
			var pts := PackedVector2Array()
			for i in 32:
				var a := TAU * i / 32.0
				pts.append(_p(r, op[1], op[2]) + Vector2(cos(a) * op[3] * h, sin(a) * op[4] * h))
			cv.draw_colored_polygon(pts, _col(op[5]))
		"ring":
			cv.draw_arc(_p(r, op[1], op[2]), op[3] * h, 0.0, TAU, 32, _col(op[4]), op[5] * h, true)
		"star":
			cv.draw_colored_polygon(_star_pts(_p(r, op[1], op[2]), op[3] * h, op[5] if op.size() > 5 else 5), _col(op[4]))
		"cross":
			var t: float = op[2] * h
			cv.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.5 - t * 0.5, 0), Vector2(t, h)), _col(op[1]))
			cv.draw_rect(Rect2(r.position + Vector2(0, h * 0.5 - t * 0.5), Vector2(r.size.x, t)), _col(op[1]))
		"nordic":
			var t2: float = op[2] * h
			cv.draw_rect(Rect2(r.position + Vector2(r.size.x * op[3] - t2 * 0.5, 0), Vector2(t2, h)), _col(op[1]))
			cv.draw_rect(Rect2(r.position + Vector2(0, h * 0.5 - t2 * 0.5), Vector2(r.size.x, t2)), _col(op[1]))
		"saltire":
			var t3: float = op[2] * h
			cv.draw_line(r.position, r.end, _col(op[1]), t3)
			cv.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), _col(op[1]), t3)
		"tri":
			cv.draw_colored_polygon(PackedVector2Array([r.position, _p(r, op[2], 0.5), Vector2(r.position.x, r.end.y)]), _col(op[1]))
		"side_tris":
			cv.draw_colored_polygon(PackedVector2Array([r.position, _p(r, 0.5, 0.5), Vector2(r.position.x, r.end.y)]), _col(op[1]))
			cv.draw_colored_polygon(PackedVector2Array([Vector2(r.end.x, r.position.y), _p(r, 0.5, 0.5), r.end]), _col(op[1]))
		"rhombus":
			var m: float = op[2]
			cv.draw_colored_polygon(PackedVector2Array([_p(r, 0.5, m), _p(r, 1.0 - m * 0.66, 0.5), _p(r, 0.5, 1.0 - m), _p(r, m * 0.66, 0.5)]), _col(op[1]))
		"crescent":
			var c: Vector2 = _p(r, op[1], op[2])
			cv.draw_circle(c, op[3] * h, _col(op[4]))
			cv.draw_circle(c + Vector2(op[3] * h * 0.25, 0), op[3] * h * 0.8, _col(op[5]))
		"dots":
			var area := Rect2(_p(r, op[1], op[2]), Vector2(op[3] * r.size.x, op[4] * h))
			var cols: int = op[6]
			var rows: int = op[7]
			for yy in rows:
				for xx in cols:
					var pos := area.position + Vector2((xx + 0.5) / cols * area.size.x, (yy + 0.5) / rows * area.size.y)
					cv.draw_colored_polygon(_star_pts(pos, area.size.y / rows * 0.32), _col(op[5]))
		"arc_dots":
			var cc: Vector2 = _p(r, op[1], op[2])
			var n: int = op[5]
			for i in n:
				var a := PI + PI * (i + 0.5) / n
				cv.draw_colored_polygon(_star_pts(cc + Vector2(cos(a), sin(a)) * op[3] * h, h * 0.035), _col(op[4]))
		"union":   # bandera del Reino Unido (entera o en la esquina)
			var u := Rect2(_p(r, op[1], op[2]), Vector2(op[3] * r.size.x, op[4] * h))
			cv.draw_rect(u, _col("navy"))
			var uh := u.size.y
			cv.draw_line(u.position, u.end, Color.WHITE, uh * 0.2)
			cv.draw_line(Vector2(u.position.x, u.end.y), Vector2(u.end.x, u.position.y), Color.WHITE, uh * 0.2)
			cv.draw_line(u.position, u.end, _col("crimson"), uh * 0.07)
			cv.draw_line(Vector2(u.position.x, u.end.y), Vector2(u.end.x, u.position.y), _col("crimson"), uh * 0.07)
			cv.draw_rect(Rect2(u.position + Vector2(u.size.x * 0.5 - uh * 0.17, 0), Vector2(uh * 0.34, uh)), Color.WHITE)
			cv.draw_rect(Rect2(u.position + Vector2(0, uh * 0.33), Vector2(u.size.x, uh * 0.34)), Color.WHITE)
			cv.draw_rect(Rect2(u.position + Vector2(u.size.x * 0.5 - uh * 0.1, 0), Vector2(uh * 0.2, uh)), _col("crimson"))
			cv.draw_rect(Rect2(u.position + Vector2(0, uh * 0.4), Vector2(u.size.x, uh * 0.2)), _col("crimson"))
		"taeguk":   # circulo rojo y azul de Corea
			var tc: Vector2 = _p(r, op[1], op[2])
			var tr: float = op[3] * h
			cv.draw_circle(tc, tr, _col("crimson"))
			var lower := PackedVector2Array()
			for i in 17:
				var a := PI * i / 16.0
				lower.append(tc + Vector2(cos(a), sin(a)) * tr)
			cv.draw_colored_polygon(lower, _col("navy"))
			cv.draw_circle(tc + Vector2(-tr * 0.5, 0), tr * 0.5, _col("crimson"))
			cv.draw_circle(tc + Vector2(tr * 0.5, 0), tr * 0.5, _col("navy"))
		"bars":   # las cuatro rayitas negras en las esquinas
			for corner in [Vector2(0.18, 0.22), Vector2(0.82, 0.22), Vector2(0.18, 0.78), Vector2(0.82, 0.78)]:
				var bc: Vector2 = _p(r, corner.x, corner.y)
				var ang := -0.6 if (corner.x < 0.5) == (corner.y < 0.5) else 0.6
				for k in 3:
					var off := Vector2(cos(ang), sin(ang)) * (k - 1) * h * 0.05
					var dir := Vector2(-sin(ang), cos(ang)) * h * 0.09
					cv.draw_line(bc + off - dir, bc + off + dir, _col(op[1]), h * 0.03)
