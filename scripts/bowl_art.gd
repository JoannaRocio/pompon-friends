class_name BowlArt
extends RefCounted
## Tazones de comida y de agua, dibujados por codigo. El de siempre (id vacio) es feo a proposito:
## abollado, rajado y desportillado. Los de la tienda son de colores y con dibujitos.

const OUT := Color("5b3a4a")

# id -> {body, rim, accent, pattern}
const STYLES := {
	"bowl_food_pink": {"body": "ffb3cc", "rim": "ff8fb1", "accent": "ffffff", "pattern": "dots"},
	"bowl_food_star": {"body": "ffe27a", "rim": "f2c14e", "accent": "ff9b54", "pattern": "stars"},
	"bowl_food_mint": {"body": "9be3d0", "rim": "6fc9b3", "accent": "ffffff", "pattern": "paw"},
	"bowl_food_gold": {"body": "ffd34d", "rim": "e0a000", "accent": "fff3b0", "pattern": "shine"},
	"bowl_water_blue": {"body": "8ecae6", "rim": "5bb8f5", "accent": "ffffff", "pattern": "waves"},
	"bowl_water_heart": {"body": "ff9ecb", "rim": "ff7aa8", "accent": "ffffff", "pattern": "heart"},
	"bowl_water_lilac": {"body": "d2b8f0", "rim": "b08be0", "accent": "ffffff", "pattern": "dots"},
	"bowl_water_fish": {"body": "7fd0f0", "rim": "4aa8d8", "accent": "ffffff", "pattern": "fish"},
	"bowl_food_diamond": {"body": "cfefff", "rim": "8ecae6", "accent": "ffffff", "pattern": "shine"},
	"bowl_water_crystal": {"body": "e0d7ff", "rim": "b39ddb", "accent": "ffffff", "pattern": "stars"},
}


static func _ell(cv: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, outline := true, w := 4.0) -> void:
	var pts := PackedVector2Array()
	for i in 36:
		var a := TAU * i / 36.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	cv.draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		cv.draw_polyline(pts, OUT, w, true)


## Dibuja el tazon con el borde superior en y = 0 (ancho ~148 unidades). `k` = avance de la comida (0..1).
static func draw_bowl(cv: CanvasItem, id: String, food: bool, k: float, t: float) -> void:
	var nice: bool = STYLES.has(id)
	var st: Dictionary = STYLES.get(id, {})
	var body := Color(st["body"]) if nice else Color("a79a8f")
	var rim := Color(st["rim"]) if nice else Color("8d8077")
	var inside := rim.darkened(0.35) if nice else Color("6f645c")
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI * float(i) / 20.0
		var dent := 1.0 if nice else 1.0 - 0.07 * sin(a * 3.0)
		pts.append(Vector2(cos(a) * 74.0 * dent, sin(a) * 44.0 * dent))
	cv.draw_colored_polygon(pts, body)
	cv.draw_polyline(pts, OUT, 4.0, true)
	if nice:
		_decorate(cv, st)
	else:
		cv.draw_line(Vector2(-60, 14), Vector2(60, 14), Color("c9a07a"), 7.0)  # franja desteñida
		cv.draw_polyline(PackedVector2Array([Vector2(-26, 4), Vector2(-18, 16), Vector2(-26, 24), Vector2(-16, 38)]), OUT, 3.0, true)
	_ell(cv, Vector2.ZERO, 74.0, 17.0, rim)
	_ell(cv, Vector2(0, 1), 64.0, 12.0, inside, false)
	if not nice:
		cv.draw_colored_polygon(PackedVector2Array([Vector2(46, -15), Vector2(60, -9), Vector2(52, -4)]), Color("e9d9c8"))  # desportillado
	if food:
		var left := 1.0 - k
		for i in 9:
			var px := -34.0 + float(i % 5) * 17.0 + float(i / 5) * 8.0
			var py := -6.0 - float(i / 5) * 9.0 * left
			var r := 8.0 * (0.5 + 0.5 * left)
			var c1 := Color("7d5230") if not nice else Color("c98a4b")
			var c2 := Color("9c6b3f") if not nice else Color("e0a665")
			cv.draw_circle(Vector2(px, py), r, c1 if i % 2 == 0 else c2)
			cv.draw_circle(Vector2(px - 2, py - 2), r * 0.35, Color("b98354") if not nice else Color("ffd9a8"))
	else:
		var level := 1.0 - 0.45 * k
		var water := Color("7f9aa0") if not nice else Color("a8e3ff")
		_ell(cv, Vector2(0, 1), 60.0 * level, 9.0 * level, water, false)
		if nice:
			cv.draw_arc(Vector2(-18, 0), 14.0, PI * 1.1, PI * 1.7, 8, Color(1, 1, 1, 0.8), 3.0, true)
		else:
			cv.draw_circle(Vector2(-18, -1), 3.0, Color("a6bcc1"))
			cv.draw_circle(Vector2(26, 3), 2.0, Color("5f7a80"))  # una motita flotando
		for i in 2:
			var rp := fmod(t * 1.6 + float(i) * 0.5, 1.0)
			cv.draw_arc(Vector2(0, 1), 12.0 + rp * 40.0, 0.0, TAU, 28, Color(1, 1, 1, 0.45 * (1.0 - rp)), 3.0, true)


## Dibujito del frente del tazon (lunares, estrellas, huellita, corazon...).
static func _decorate(cv: CanvasItem, st: Dictionary) -> void:
	var a := Color(st["accent"])
	cv.draw_line(Vector2(-62, 12), Vector2(62, 12), Color(st["rim"]), 6.0)
	match st["pattern"]:
		"dots":
			for p in [Vector2(-42, 26), Vector2(-14, 32), Vector2(16, 32), Vector2(42, 26), Vector2(0, 22)]:
				cv.draw_circle(p, 6.0, a)
		"stars":
			for p in [Vector2(-34, 28), Vector2(0, 32), Vector2(34, 28)]:
				var sp := PackedVector2Array()
				for i in 10:
					var ang := -PI / 2.0 + PI * i / 5.0
					sp.append(p + Vector2(cos(ang), sin(ang)) * (9.0 if i % 2 == 0 else 4.0))
				cv.draw_colored_polygon(sp, a)
		"paw":
			var c := Vector2(0, 30)
			cv.draw_circle(c + Vector2(0, 4), 9.0, a)
			for p in [Vector2(-12, -6), Vector2(-4, -12), Vector2(5, -12), Vector2(13, -6)]:
				cv.draw_circle(c + p, 4.0, a)
		"shine":
			cv.draw_line(Vector2(-44, 20), Vector2(-20, 38), a, 5.0, true)
			cv.draw_line(Vector2(-30, 18), Vector2(-14, 30), a, 3.0, true)
		"waves":
			for y in [24.0, 36.0]:
				var pts := PackedVector2Array()
				for i in 13:
					pts.append(Vector2(-48.0 + i * 8.0, y + sin(float(i) * 1.3) * 3.0))
				cv.draw_polyline(pts, a, 3.0, true)
		"heart":
			var hp := PackedVector2Array()
			for i in 32:
				var ang2 := TAU * i / 32.0
				hp.append(Vector2(0, 30) + Vector2(16.0 * pow(sin(ang2), 3.0), -(13.0 * cos(ang2) - 5.0 * cos(2.0 * ang2) - 2.0 * cos(3.0 * ang2) - cos(4.0 * ang2))) * 0.8)
			cv.draw_colored_polygon(hp, a)
		"fish":
			cv.draw_colored_polygon(PackedVector2Array([Vector2(-18, 30), Vector2(-26, 22), Vector2(-26, 38)]), a)
			_ell(cv, Vector2(-2, 30), 20.0, 10.0, a, false)
			cv.draw_circle(Vector2(8, 28), 2.5, OUT)
