class_name ItemArt
extends RefCounted
## Dibujo por codigo de muebles, decoracion, paredes y pisos. Lo usan el cuarto (RoomView)
## y las miniaturas de la tienda (ItemIcon). Todas las funciones reciben el CanvasItem donde dibujar.

const OUTLINE := Color("5b3a4a")
const DEFAULT_WALL := Color("fff1d6")
const DEFAULT_FLOOR := Color("f2d3a4")
const STAR_COLORS := [Color("d9c8f5"), Color("ffd2b8"), Color("bfe8d8"), Color("ffc4dc"), Color("bfe0f5")]
const BOOK_COLORS := [Color("e76f51"), Color("f4a261"), Color("8ecae6"), Color("90be6d"), Color("b388f5"), Color("ffd166")]

# El cuarto actualiza estos valores segun la hora real antes de dibujar la ventana.
static var sky := Color("bfe3f5")
static var night_amount := 0.0

const DEFAULT_SIZE := Vector2(170, 135)
const SIZES := {
	"furn_sofa": Vector2(220, 130), "furn_plant": Vector2(100, 150), "furn_bookshelf": Vector2(150, 190),
	"furn_table": Vector2(170, 120), "furn_lamp": Vector2(80, 190), "furn_fireplace": Vector2(200, 170),
	"furn_toybox": Vector2(140, 110), "furn_crib": Vector2(200, 150),
	"deco_window": Vector2(150, 170), "deco_picture": Vector2(110, 130), "deco_clock": Vector2(100, 100),
	"deco_shelf": Vector2(170, 90), "deco_garland": Vector2(260, 80), "deco_moon": Vector2(120, 120),
	"furn_teddy": Vector2(110, 130), "furn_beanbag": Vector2(160, 110), "furn_globe": Vector2(110, 150),
	"furn_aquarium": Vector2(190, 140), "furn_piano": Vector2(200, 170),
	"deco_rainbow": Vector2(210, 110), "deco_balloons": Vector2(150, 190),
	"furn_dresser": Vector2(200, 150), "furn_desk": Vector2(230, 150), "furn_wardrobe": Vector2(150, 230),
	"furn_stool": Vector2(90, 80), "deco_shelf_long": Vector2(280, 90), "deco_shelf_cloud": Vector2(220, 100),
	"toy_blocks": Vector2(90, 80), "toy_books": Vector2(100, 62), "toy_vase": Vector2(70, 110),
	"toy_cactus": Vector2(70, 100), "toy_cake": Vector2(90, 90), "toy_frame": Vector2(80, 90),
	"toy_musicbox": Vector2(90, 80), "toy_robot": Vector2(80, 110), "toy_trophy": Vector2(70, 100),
	"furn_bed_cloud": Vector2(230, 150),
	# decoracion nueva (16/11/2026)
	"furn_chair": Vector2(90, 140), "furn_armchair": Vector2(160, 130), "furn_cushions": Vector2(170, 80),
	"furn_nightstand": Vector2(100, 110), "furn_tent": Vector2(190, 210), "furn_stove": Vector2(170, 170),
	"furn_fridge": Vector2(120, 220), "furn_telescope": Vector2(140, 190), "furn_fountain": Vector2(190, 160),
	"furn_bench": Vector2(210, 120), "furn_tree": Vector2(150, 230), "furn_flowers": Vector2(180, 90),
	"furn_easel": Vector2(130, 200), "furn_slide": Vector2(230, 180),
	"rug_round": Vector2(260, 84), "rug_stripes": Vector2(300, 80), "rug_star": Vector2(250, 92), "rug_cloud": Vector2(280, 92),
	"deco_mirror": Vector2(100, 140), "deco_plant_hanging": Vector2(110, 170), "deco_stars": Vector2(190, 110),
	"deco_board": Vector2(190, 130), "deco_map": Vector2(200, 130), "deco_cloud": Vector2(170, 140),
	"toy_lamp": Vector2(70, 100), "toy_alarm": Vector2(74, 74), "toy_teacup": Vector2(100, 62), "toy_dino": Vector2(100, 82),
	"toy_candles": Vector2(84, 84), "toy_duck": Vector2(72, 66), "toy_snowglobe": Vector2(78, 88), "toy_fruit": Vector2(100, 66),
}


static func size_of(id: String) -> Vector2:
	if PixelArt.is_art(id):
		return Vector2(120, 132)
	return SIZES.get(id, SIZES.get(Catalog.shape_of(id), DEFAULT_SIZE))


## Chispitas que titilan alrededor de un item especial (`t` = tiempo en segundos).
static func draw_shine(cv: CanvasItem, rect: Rect2, t: float) -> void:
	for i in 5:
		var k := fmod(t * 0.55 + i * 0.37, 1.0)
		var a := sin(k * PI)
		var p := rect.position + Vector2(fmod(i * 0.61 + 0.13, 1.0) * rect.size.x, fmod(i * 0.43 + 0.21, 1.0) * rect.size.y * 0.8)
		var r := (5.0 + 7.0 * a) * clampf(rect.size.x / 160.0, 0.5, 1.2)
		var col := Color(1.0, 0.78, 0.2, a)   # dorado (se ve sobre fondos claros y oscuros)
		cv.draw_line(p - Vector2(r, 0), p + Vector2(r, 0), col, 3.0, true)
		cv.draw_line(p - Vector2(0, r), p + Vector2(0, r), col, 3.0, true)
		cv.draw_circle(p, r * 0.32, Color(1, 1, 1, a))


const REF_ROOM := Vector2(720, 1280)   # cuarto de referencia para calcular choques entre items


## De entre `spots` (fracciones del cuarto) devuelve el primero donde `id` no se monta sobre
## ningun item de `placed` (lista de {"id","x","y"}); si todos chocan, el de menor choque.
static func best_spot(id: String, spots: Array, placed: Array, ref := REF_ROOM) -> Vector2:
	var item_size := size_of(id)
	var best: Vector2 = spots[0]
	var best_overlap := INF
	for s in spots:
		var r := Rect2(s * ref - item_size * 0.5, item_size)
		var overlap := 0.0
		for p in placed:
			var other := size_of(p["id"])
			overlap += r.intersection(Rect2(Vector2(p["x"], p["y"]) * ref - other * 0.5, other)).get_area()
		if overlap < best_overlap:
			best = s
			best_overlap = overlap
		if overlap <= 0.0:
			break
	return best


# ------------------------------------------------------------------ helpers

static func _ellipse(cv: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, outline := true, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry).rotated(rot) + c)
	cv.draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		cv.draw_polyline(pts, OUTLINE, 4.0, true)


static func _round(cv: CanvasItem, rect: Rect2, fill: Color, radius := 18) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = OUTLINE
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(radius)
	cv.draw_style_box(sb, rect)


static func _poly(cv: CanvasItem, points: Array, fill: Color, outline := true) -> void:
	var pts := PackedVector2Array(points)
	cv.draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		cv.draw_polyline(pts, OUTLINE, 4.0, true)


static func _star(cv: CanvasItem, c: Vector2, r: float, color: Color, points := 5) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var rr := r if i % 2 == 0 else r * 0.45
		var a := -PI / 2.0 + PI * i / points
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	cv.draw_colored_polygon(pts, color)


# ------------------------------------------------------- pared y piso

static func draw_wall(cv: CanvasItem, rect: Rect2, id: String, k := 1.0) -> void:
	var wc: Color = Catalog.color_of(id) if id != "" else DEFAULT_WALL
	var pattern: String = Catalog.get_item(id).get("pattern", "stars") if id != "" else "stars"
	cv.draw_rect(rect, wc)
	var end := rect.end
	match pattern:
		"stars":
			var step := 120.0 * k
			var row := 0
			var y := rect.position.y + 60.0 * k
			while y < end.y - 20.0 * k:
				var x := rect.position.x + 60.0 * k + (step * 0.5 if row % 2 == 1 else 0.0)
				var i := 0
				while x < end.x - 6.0 * k:
					var col: Color = STAR_COLORS[(i + row * 2) % STAR_COLORS.size()]
					col.a = 0.7
					_star(cv, Vector2(x, y), 18.0 * k, col)
					x += step
					i += 1
				y += 100.0 * k
				row += 1
		"dots":
			var step2 := 64.0 * k
			var row2 := 0
			var y2 := rect.position.y + 40.0 * k
			while y2 < end.y - 10.0 * k:
				var x2 := rect.position.x + 32.0 * k + (step2 * 0.5 if row2 % 2 == 1 else 0.0)
				while x2 < end.x - 4.0 * k:
					cv.draw_circle(Vector2(x2, y2), 8.0 * k, wc.darkened(0.08))
					x2 += step2
				y2 += 56.0 * k
				row2 += 1
		"clouds":
			var cy := rect.position.y + 70.0 * k
			var crow := 0
			while cy < end.y - 20.0 * k:
				var cx := rect.position.x + (80.0 if crow % 2 == 0 else 190.0) * k
				while cx < end.x:
					for part in [[-26, 6, 20], [0, -6, 28], [28, 6, 22], [0, 8, 24]]:
						cv.draw_circle(Vector2(cx + part[0] * k, cy + part[1] * k), part[2] * k, Color(1, 1, 1, 0.85))
					cx += 230.0 * k
				cy += 130.0 * k
				crow += 1
		"hearts":
			var hy := rect.position.y + 50.0 * k
			var hrow := 0
			while hy < end.y - 10.0 * k:
				var hx := rect.position.x + (50.0 if hrow % 2 == 0 else 110.0) * k
				while hx < end.x:
					var hp := PackedVector2Array()
					for i in 24:
						var ang := TAU * i / 24.0
						hp.append(Vector2(hx, hy) + Vector2(16.0 * pow(sin(ang), 3.0), -(13.0 * cos(ang) - 5.0 * cos(2.0 * ang) - 2.0 * cos(3.0 * ang) - cos(4.0 * ang))) * 0.9 * k)
					cv.draw_colored_polygon(hp, Color(1.0, 0.62, 0.74, 0.7))
					hx += 120.0 * k
				hy += 90.0 * k
				hrow += 1
		"space":
			for i in 38:
				var sx := rect.position.x + fmod(float(i) * 97.0, rect.size.x)
				var sy := rect.position.y + fmod(float(i) * 61.0 + float(i * i) * 7.0, rect.size.y)
				cv.draw_circle(Vector2(sx, sy), (2.5 + float(i % 3)) * k, Color(1, 1, 0.85, 0.85))
			cv.draw_circle(rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.3), 46.0 * k, Color("ff9b54"))
			cv.draw_arc(rect.position + Vector2(rect.size.x * 0.78, rect.size.y * 0.3), 66.0 * k, 3.6, 6.1, 20, Color("ffd9a0"), 6.0 * k, true)
			cv.draw_circle(rect.position + Vector2(rect.size.x * 0.2, rect.size.y * 0.68), 26.0 * k, Color("8fd1ff"))
			cv.draw_circle(rect.position + Vector2(rect.size.x * 0.2 - 8.0 * k, rect.size.y * 0.68 - 8.0 * k), 8.0 * k, Color(1, 1, 1, 0.5))
		"rainbow":  # bandas suaves de colores y nubecitas
			var bands := [Color("ffd6d6"), Color("ffe6c7"), Color("fff6c2"), Color("d8f5d0"), Color("d4ecff"), Color("e6dcff")]
			var bh := rect.size.y / bands.size()
			for i in bands.size():
				cv.draw_rect(Rect2(rect.position.x, rect.position.y + i * bh, rect.size.x, bh + 1.0), bands[i])
			var ccx := rect.position.x + 110.0 * k
			while ccx < end.x:
				for part in [[-22, 4, 18], [0, -4, 24], [24, 4, 18]]:
					cv.draw_circle(Vector2(ccx + part[0] * k, rect.position.y + rect.size.y * 0.3 + part[1] * k), part[2] * k, Color(1, 1, 1, 0.8))
				ccx += 300.0 * k
		"flowers":  # florcitas de cinco petalos en filas corridas
			var fy := rect.position.y + 50.0 * k
			var frow := 0
			var fcols := [Color("ffb3c8"), Color("ffd59e"), Color("c8b8f5"), Color("a8e0c8")]
			while fy < end.y - 16.0 * k:
				var fx := rect.position.x + (46.0 if frow % 2 == 0 else 106.0) * k
				var fi := frow
				while fx < end.x - 10.0 * k:
					var fc: Color = fcols[fi % fcols.size()]
					for pk in 5:
						var pa := TAU * pk / 5.0 - PI / 2.0
						cv.draw_circle(Vector2(fx, fy) + Vector2(cos(pa), sin(pa)) * 10.0 * k, 8.0 * k, fc)
					cv.draw_circle(Vector2(fx, fy), 6.0 * k, Color("fff6d6"))
					cv.draw_line(Vector2(fx + 30.0 * k, fy + 26.0 * k), Vector2(fx + 42.0 * k, fy + 20.0 * k), Color(0.45, 0.75, 0.5, 0.5), maxf(1.5, 4.0 * k), true)
					fx += 120.0 * k
					fi += 1
				fy += 96.0 * k
				frow += 1
		"brick":  # ladrillos suaves con junta clara
			var bh := 34.0 * k
			var bw := 82.0 * k
			var brow := 0
			var by := rect.position.y
			while by < end.y:
				var bx := rect.position.x - (bw * 0.5 if brow % 2 == 1 else 0.0)
				var bi := brow
				while bx < end.x:
					var br := Rect2(Vector2(maxf(bx, rect.position.x) + 3.0 * k, by + 3.0 * k), Vector2(minf(bx + bw, end.x) - maxf(bx, rect.position.x) - 6.0 * k, minf(bh, end.y - by) - 6.0 * k))
					if br.size.x > 1.0 and br.size.y > 1.0:
						cv.draw_rect(br, wc.darkened(0.04 + 0.05 * float((bi * 7 + brow * 3) % 3)))
					bx += bw
					bi += 1
				by += bh
				brow += 1
		"panels":  # tablas verticales de madera con vetas
			var pw := 70.0 * k
			var px := rect.position.x
			var pn := 0
			while px < end.x:
				cv.draw_rect(Rect2(px, rect.position.y, minf(pw, end.x - px), rect.size.y), wc.darkened(0.03 * float(pn % 3)))
				cv.draw_line(Vector2(px, rect.position.y), Vector2(px, end.y), wc.darkened(0.16), maxf(1.0, 3.0 * k))
				cv.draw_arc(Vector2(px + pw * 0.5, rect.position.y + rect.size.y * (0.3 + 0.2 * float(pn % 2))), 9.0 * k, 0.0, TAU, 10, wc.darkened(0.1), maxf(1.0, 2.0 * k))
				px += pw
				pn += 1
		"tiles":  # azulejos cuadrados con una florcita cada tanto
			var ts := 64.0 * k
			var ty := rect.position.y
			var trow := 0
			while ty < end.y:
				var tx := rect.position.x
				var tcol := 0
				while tx < end.x:
					var tr := Rect2(Vector2(tx + 2.0 * k, ty + 2.0 * k), Vector2(minf(ts, end.x - tx) - 4.0 * k, minf(ts, end.y - ty) - 4.0 * k))
					if tr.size.x > 1.0 and tr.size.y > 1.0:
						cv.draw_rect(tr, wc.lightened(0.3))
						if (trow + tcol) % 3 == 0 and tr.size.x > ts * 0.6 and tr.size.y > ts * 0.6:
							var tc := tr.get_center()
							for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
								cv.draw_circle(tc + d * 8.0 * k, 6.0 * k, Color(0.55, 0.78, 0.92, 0.55))
							cv.draw_circle(tc, 4.0 * k, Color(1.0, 0.85, 0.5, 0.8))
					tx += ts
					tcol += 1
				ty += ts
				trow += 1
		"stripes":
			var w := 56.0 * k
			var x3 := rect.position.x
			var n := 0
			while x3 < end.x:
				if n % 2 == 1:
					cv.draw_rect(Rect2(x3, rect.position.y, minf(w, end.x - x3), rect.size.y), wc.darkened(0.05))
				x3 += w
				n += 1


static func draw_floor(cv: CanvasItem, rect: Rect2, id: String, k := 1.0) -> void:
	var fc: Color = Catalog.color_of(id) if id != "" else DEFAULT_FLOOR
	var pattern: String = Catalog.get_item(id).get("pattern", "planks") if id != "" else "planks"
	cv.draw_rect(rect, fc)
	var seam := fc.darkened(0.12)
	var end := rect.end
	if pattern == "checker":
		var s := 90.0 * k
		var row := 0
		var y := rect.position.y
		while y < end.y:
			var x := rect.position.x
			var n := row % 2
			while x < end.x:
				if n % 2 == 0:
					cv.draw_rect(Rect2(x, y, minf(s, end.x - x), minf(s, end.y - y)), fc.darkened(0.07))
				x += s
				n += 1
			y += s
			row += 1
		return
	if pattern == "grass":
		var gy := rect.position.y + 24.0 * k
		var grow := 0
		while gy < end.y:
			var gx := rect.position.x + (10.0 if grow % 2 == 0 else 34.0) * k
			while gx < end.x:
				var gc := fc.darkened(0.18)
				cv.draw_line(Vector2(gx, gy), Vector2(gx - 6.0 * k, gy - 14.0 * k), gc, maxf(1.5, 3.0 * k))
				cv.draw_line(Vector2(gx, gy), Vector2(gx + 7.0 * k, gy - 12.0 * k), gc, maxf(1.5, 3.0 * k))
				cv.draw_line(Vector2(gx, gy), Vector2(gx, gy - 17.0 * k), gc, maxf(1.5, 3.0 * k))
				gx += 68.0 * k
			gy += 44.0 * k
			grow += 1
		return
	if pattern == "tiles":  # baldosas claras con junta
		var ts := 80.0 * k
		var ty := rect.position.y
		var trow := 0
		while ty < end.y:
			var tx := rect.position.x
			var tcol := 0
			while tx < end.x:
				var tr := Rect2(Vector2(tx + 2.0 * k, ty + 2.0 * k), Vector2(minf(ts, end.x - tx) - 4.0 * k, minf(ts, end.y - ty) - 4.0 * k))
				if tr.size.x > 1.0 and tr.size.y > 1.0:
					cv.draw_rect(tr, fc.darkened(0.06) if (trow + tcol) % 2 == 0 else fc.lightened(0.2))
				tx += ts
				tcol += 1
			ty += ts
			trow += 1
		return
	if pattern == "stones":  # pasto con un camino de piedras
		var sy := rect.position.y + 30.0 * k
		var srow := 0
		while sy < end.y:
			var sx := rect.position.x + (30.0 if srow % 2 == 0 else 90.0) * k
			while sx < end.x:
				_ellipse(cv, Vector2(sx, sy + 3.0 * k), 31.0 * k, 17.0 * k, fc.darkened(0.2), false)
				_ellipse(cv, Vector2(sx, sy), 30.0 * k, 16.0 * k, Color("ebe4d6"), false)
				_ellipse(cv, Vector2(sx - 6.0 * k, sy - 4.0 * k), 12.0 * k, 5.0 * k, Color(1, 1, 1, 0.45), false)
				sx += 120.0 * k
			sy += 58.0 * k
			srow += 1
		return
	if pattern == "starry":  # alfombrado oscuro con estrellitas
		var st := 0
		var yy := rect.position.y + 30.0 * k
		while yy < end.y:
			var xx := rect.position.x + (30.0 + float(st % 3) * 26.0) * k
			while xx < end.x:
				_star(cv, Vector2(xx, yy), 8.0 * k, Color(1.0, 0.92, 0.6, 0.75))
				xx += 110.0 * k
				st += 1
			yy += 64.0 * k
		return
	if pattern == "carpet":
		var inset := 14.0 * k
		cv.draw_rect(Rect2(rect.position + Vector2(inset, inset), rect.size - Vector2(inset, inset) * 2.0), fc.lightened(0.18), false, maxf(2.0, 5.0 * k))
		var dx := rect.position.x + 40.0 * k
		while dx < end.x - 20.0 * k:
			var dy := rect.position.y + 40.0 * k
			while dy < end.y - 20.0 * k:
				cv.draw_circle(Vector2(dx, dy), 6.0 * k, fc.darkened(0.08))
				dy += 56.0 * k
			dx += 56.0 * k
		return
	var ry := rect.position.y + 70.0 * k
	var r := 0
	while ry < end.y:
		cv.draw_line(Vector2(rect.position.x, ry), Vector2(end.x, ry), seam, maxf(1.0, 2.0 * k))
		var sx := rect.position.x + (90.0 if r % 2 == 0 else 20.0) * k
		var next := ry + (70.0 + r * 18.0) * k
		while sx < end.x:
			cv.draw_line(Vector2(sx, ry), Vector2(sx - r * 6.0 * k, minf(next, end.y)), seam, maxf(1.0, 2.0 * k))
			sx += (190.0 + r * 30.0) * k
		ry = next
		r += 1


# ------------------------------------------------------- muebles y deco

## Dibuja el item `id` centrado en `center` (tamano fijo de size_of(id)).
static func draw_item(cv: CanvasItem, id: String, center: Vector2) -> void:
	var size := size_of(id)
	var r := Rect2(center - size * 0.5, size)
	if PixelArt.is_art(id):
		PixelArt.draw_framed(cv, id, r)
		return
	var col := Catalog.color_of(id)
	var light := col.lightened(0.35)
	var dark := col.darkened(0.25)
	var pos := r.position
	var c := r.get_center()
	match Catalog.shape_of(id):
		"furn_bed_cloud":  # cama de nube: colchon de nubes, almohada y mantita con estrellas
			for part in [[-78, 30, 42], [-30, 18, 50], [26, 20, 48], [76, 32, 40], [0, 44, 56]]:
				_ellipse(cv, c + Vector2(part[0], part[1]), part[2], part[2] * 0.75, col.darkened(0.06))
			for part in [[-78, 24, 36], [-30, 12, 44], [26, 14, 42], [76, 26, 34], [0, 36, 50]]:
				_ellipse(cv, c + Vector2(part[0], part[1]), part[2], part[2] * 0.72, Color.WHITE, false)
			_ellipse(cv, c + Vector2(-62, -6), 34.0, 20.0, Color("fff8fb"))
			_round(cv, Rect2(c + Vector2(-34, -2), Vector2(122, 40)), Color("c8b8f5"), 18)
			for sp in [Vector2(-12, 16), Vector2(28, 10), Vector2(64, 20)]:
				_star(cv, c + sp, 7.0, Color("fff3a0"))
			_star(cv, c + Vector2(90, -38), 12.0, Color("ffe066"))
		"furn_bed":
			_round(cv, Rect2(pos + Vector2(0, 50), Vector2(r.size.x, 80)), dark, 22)
			_round(cv, Rect2(pos + Vector2(8, 28), Vector2(r.size.x - 16, 70)), col, 22)
			_round(cv, Rect2(pos + Vector2(16, 20), Vector2(52, 36)), Color("fff1d6"), 16)
			cv.draw_line(pos + Vector2(90, 40), pos + Vector2(90, 96), light, 5.0)
			cv.draw_line(pos + Vector2(116, 40), pos + Vector2(116, 96), light, 5.0)
		"furn_scratcher":
			_round(cv, Rect2(pos + Vector2(20, 112), Vector2(r.size.x - 40, 22)), dark, 12)
			_round(cv, Rect2(c + Vector2(-14, -50), Vector2(28, 166)), Color("e2c79a"), 6)
			for yy in range(-30, 100, 20):
				cv.draw_line(c + Vector2(-14, yy), c + Vector2(14, yy + 8), OUTLINE, 2.0)
			_round(cv, Rect2(c + Vector2(-56, -66), Vector2(112, 24)), col, 12)
		"furn_tunnel":
			var pts := PackedVector2Array()
			for i in 25:
				var a := PI + PI * i / 24.0
				pts.append(Vector2(c.x + cos(a) * 78.0, r.end.y - 14.0 + sin(a) * 100.0))
			cv.draw_colored_polygon(pts, col)
			pts.append(pts[0])
			cv.draw_polyline(pts, OUTLINE, 4.0, true)
			_ellipse(cv, Vector2(c.x, r.end.y - 16.0), 44.0, 52.0, Color("3d2a2a"), false)
			for kx in [-44.0, 0.0, 44.0]:
				cv.draw_line(Vector2(c.x + kx, r.end.y - 100.0 + absf(kx) * 0.4), Vector2(c.x + kx * 1.6, r.end.y - 30.0), dark, 3.0)
		"furn_swing":
			cv.draw_line(c + Vector2(-70, 60), c + Vector2(0, -62), OUTLINE, 9.0, true)
			cv.draw_line(c + Vector2(70, 60), c + Vector2(0, -62), OUTLINE, 9.0, true)
			cv.draw_line(c + Vector2(-70, 60), c + Vector2(0, -62), col, 5.0, true)
			cv.draw_line(c + Vector2(70, 60), c + Vector2(0, -62), col, 5.0, true)
			cv.draw_line(c + Vector2(-20, -40), c + Vector2(-20, 20), OUTLINE, 3.0)
			cv.draw_line(c + Vector2(20, -40), c + Vector2(20, 20), OUTLINE, 3.0)
			_round(cv, Rect2(c + Vector2(-34, 20), Vector2(68, 14)), light, 7)
		"furn_wheel":
			_round(cv, Rect2(c + Vector2(-40, 38), Vector2(80, 22)), dark, 10)
			_ellipse(cv, c + Vector2(0, -22), 56.0, 56.0, light, false)
			cv.draw_arc(c + Vector2(0, -22), 56.0, 0.0, TAU, 40, OUTLINE, 6.0, true)
			for kk in 6:
				var a2 := TAU * kk / 6.0
				cv.draw_line(c + Vector2(0, -22), c + Vector2(0, -22) + Vector2(cos(a2), sin(a2)) * 52.0, col, 3.0, true)
			cv.draw_circle(c + Vector2(0, -22), 8.0, OUTLINE)
		"furn_cushion":
			_round(cv, Rect2(pos + Vector2(10, 30), Vector2(r.size.x - 20, 84)), col, 28)
			cv.draw_circle(c + Vector2(0, -8), 8.0, light)
			for p in [Vector2(10, 30), Vector2(r.size.x - 10, 30), Vector2(10, 114), Vector2(r.size.x - 10, 114)]:
				cv.draw_circle(pos + p, 9.0, Color("ffd9a0"))
				cv.draw_arc(pos + p, 9.0, 0.0, TAU, 12, OUTLINE, 2.0)
		"furn_heat":
			cv.draw_circle(c + Vector2(20, -20), 62.0, Color(1.0, 0.8, 0.4, 0.22))
			_round(cv, Rect2(c + Vector2(-34, 52), Vector2(68, 14)), dark, 7)
			cv.draw_line(c + Vector2(0, 52), c + Vector2(0, -42), OUTLINE, 9.0)
			cv.draw_line(c + Vector2(0, 52), c + Vector2(0, -42), col.darkened(0.1), 5.0)
			_poly(cv, [c + Vector2(-8, -60), c + Vector2(48, -60), c + Vector2(66, -22), c + Vector2(-26, -22)], col)
			cv.draw_circle(c + Vector2(20, -12), 9.0, Color("fff3b0"))
		"furn_crib":  # cuna con barrotes, manta y osito
			var wood := Color("d8a56f")
			for lx in [16.0, r.size.x - 16.0]:
				cv.draw_line(pos + Vector2(lx, 114), pos + Vector2(lx, 146), OUTLINE, 11.0, true)
				cv.draw_line(pos + Vector2(lx, 114), pos + Vector2(lx, 146), wood.darkened(0.15), 6.0, true)
			_round(cv, Rect2(pos + Vector2(8, 80), Vector2(r.size.x - 16, 42)), Color("fff1f5"), 14)
			_round(cv, Rect2(pos + Vector2(40, 66), Vector2(r.size.x - 56, 38)), col, 16)
			for sx in [0.0, 1.0]:  # franjas de la manta
				cv.draw_line(pos + Vector2(58 + sx * 40.0, 72), pos + Vector2(58 + sx * 40.0, 100), light, 5.0, true)
			_ellipse(cv, pos + Vector2(30, 64), 17.0, 16.0, Color("e6b88a"))  # osito
			_ellipse(cv, pos + Vector2(18, 50), 7.0, 7.0, Color("e6b88a"))
			_ellipse(cv, pos + Vector2(42, 50), 7.0, 7.0, Color("e6b88a"))
			cv.draw_circle(pos + Vector2(26, 62), 2.2, OUTLINE)
			cv.draw_circle(pos + Vector2(35, 62), 2.2, OUTLINE)
			for i in 9:
				var bx := 24.0 + i * ((r.size.x - 48.0) / 8.0)
				cv.draw_line(pos + Vector2(bx, 26), pos + Vector2(bx, 100), OUTLINE, 8.0, true)
				cv.draw_line(pos + Vector2(bx, 26), pos + Vector2(bx, 100), wood, 4.0, true)
			_round(cv, Rect2(pos + Vector2(6, 16), Vector2(r.size.x - 12, 16)), wood, 8)
			_round(cv, Rect2(pos + Vector2(6, 96), Vector2(r.size.x - 12, 14)), wood, 7)
			_round(cv, Rect2(pos + Vector2(0, 2), Vector2(20, 124)), wood.darkened(0.08), 9)
			_round(cv, Rect2(pos + Vector2(r.size.x - 20, 2), Vector2(20, 124)), wood.darkened(0.08), 9)
		"furn_sofa":
			_round(cv, Rect2(pos + Vector2(14, 6), Vector2(r.size.x - 28, 70)), dark, 28)
			_round(cv, Rect2(pos + Vector2(0, 40), Vector2(r.size.x, 64)), col, 26)
			_round(cv, Rect2(pos + Vector2(-4, 32), Vector2(42, 84)), dark, 20)
			_round(cv, Rect2(pos + Vector2(r.size.x - 38, 32), Vector2(42, 84)), dark, 20)
			_round(cv, Rect2(pos + Vector2(50, 24), Vector2(54, 44)), light, 16)
			_round(cv, Rect2(pos + Vector2(116, 24), Vector2(54, 44)), light.lightened(0.1), 16)
			_round(cv, Rect2(pos + Vector2(16, 110), Vector2(24, 16)), OUTLINE, 6)
			_round(cv, Rect2(pos + Vector2(r.size.x - 40, 110), Vector2(24, 16)), OUTLINE, 6)
		"furn_plant":
			var green := Color("6bbf7a")
			for leaf in [[Vector2(50, 62), 14.0, 46.0, 0.0], [Vector2(30, 80), 12.0, 38.0, -0.7], [Vector2(70, 80), 12.0, 38.0, 0.7],
					[Vector2(38, 50), 12.0, 36.0, -0.35], [Vector2(62, 50), 12.0, 36.0, 0.35]]:
				_ellipse(cv, pos + leaf[0], leaf[1], leaf[2], green.darkened(0.06 * (int(leaf[3] * 10.0) % 3)), true, leaf[3])
			_poly(cv, [pos + Vector2(22, 104), pos + Vector2(78, 104), pos + Vector2(70, 148), pos + Vector2(30, 148)], Color("e0885c"))
			cv.draw_rect(Rect2(pos + Vector2(18, 98), Vector2(64, 12)), Color("e9996d"))
			cv.draw_rect(Rect2(pos + Vector2(18, 98), Vector2(64, 12)), OUTLINE, false, 4.0)
		"furn_bookshelf":
			_round(cv, Rect2(pos, r.size), col.darkened(0.1), 12)
			cv.draw_rect(Rect2(pos + Vector2(10, 10), r.size - Vector2(20, 20)), col.lightened(0.15))
			for row in 3:
				var top := 12.0 + row * 60.0
				var x := 14.0
				var n := 0
				while x < r.size.x - 34.0:
					var w := 12.0 + float((n * 7 + row * 3) % 4) * 3.0
					var h := 36.0 + float((n * 5 + row * 2) % 3) * 6.0
					cv.draw_rect(Rect2(pos + Vector2(x, top + 48.0 - h), Vector2(w, h)), BOOK_COLORS[(n + row) % BOOK_COLORS.size()])
					cv.draw_rect(Rect2(pos + Vector2(x, top + 48.0 - h), Vector2(w, h)), OUTLINE, false, 2.0)
					x += w + 3.0
					n += 1
				cv.draw_rect(Rect2(pos + Vector2(8, top + 48.0), Vector2(r.size.x - 16, 8)), col.darkened(0.2))
		"furn_table":
			for lx in [-52.0, 0.0, 52.0]:
				cv.draw_line(c + Vector2(lx, 6), c + Vector2(lx * 1.25, 52), OUTLINE, 10.0, true)
				cv.draw_line(c + Vector2(lx, 6), c + Vector2(lx * 1.25, 52), dark, 5.0, true)
			_ellipse(cv, c + Vector2(0, 0), 78.0, 22.0, col)
			_ellipse(cv, c + Vector2(-20, -18), 18.0, 14.0, Color("fff1f5"))
			_poly(cv, [c + Vector2(-4, -22), c + Vector2(10, -34), c + Vector2(8, -20)], Color("fff1f5"))
			cv.draw_circle(c + Vector2(-20, -34), 5.0, Color("ff9ecb"))
			_ellipse(cv, c + Vector2(30, -8), 11.0, 8.0, Color("fff1f5"))
		"furn_lamp":
			cv.draw_circle(c + Vector2(0, -50), 58.0, Color(1.0, 0.85, 0.5, 0.2))
			_ellipse(cv, Vector2(c.x, r.end.y - 10.0), 30.0, 9.0, dark)
			cv.draw_line(Vector2(c.x, r.end.y - 12.0), Vector2(c.x, pos.y + 70.0), OUTLINE, 9.0)
			cv.draw_line(Vector2(c.x, r.end.y - 12.0), Vector2(c.x, pos.y + 70.0), dark, 5.0)
			_poly(cv, [Vector2(c.x - 22, pos.y + 14), Vector2(c.x + 22, pos.y + 14), Vector2(c.x + 36, pos.y + 74), Vector2(c.x - 36, pos.y + 74)], col)
		"furn_fireplace":
			_round(cv, Rect2(pos + Vector2(0, 30), Vector2(r.size.x, r.size.y - 30)), col, 10)
			for by in range(44, 160, 22):
				cv.draw_line(pos + Vector2(4, by), pos + Vector2(r.size.x - 4, by), col.darkened(0.2), 2.0)
			_round(cv, Rect2(pos + Vector2(-8, 8), Vector2(r.size.x + 16, 26)), col.lightened(0.15), 8)
			var fire := Rect2(pos + Vector2(46, 70), Vector2(108, 96))
			_round(cv, fire, Color("3d2a2a"), 40)
			_poly(cv, [pos + Vector2(100, 90), pos + Vector2(126, 126), pos + Vector2(118, 160), pos + Vector2(82, 160), pos + Vector2(74, 126)], Color("ff8a3d"), false)
			_poly(cv, [pos + Vector2(100, 112), pos + Vector2(114, 138), pos + Vector2(108, 160), pos + Vector2(92, 160), pos + Vector2(86, 138)], Color("ffd23d"), false)
			_round(cv, Rect2(pos + Vector2(62, 152), Vector2(76, 12)), Color("8a5a3c"), 6)
		"furn_toybox":
			for blk in [[Vector2(36, 12), Color("ff8fb1")], [Vector2(70, 4), Color("8ecae6")], [Vector2(98, 14), Color("ffd166")]]:
				cv.draw_rect(Rect2(pos + blk[0], Vector2(26, 26)), blk[1])
				cv.draw_rect(Rect2(pos + blk[0], Vector2(26, 26)), OUTLINE, false, 3.0)
			_star(cv, pos + Vector2(70, 0), 12.0, Color("ffd33d"))
			_round(cv, Rect2(pos + Vector2(0, 34), Vector2(r.size.x, 76)), col, 14)
			_round(cv, Rect2(pos + Vector2(-6, 28), Vector2(r.size.x + 12, 22)), col.lightened(0.2), 10)
			_star(cv, c + Vector2(0, 26), 14.0, Color("fff1d6"))
		"deco_window":
			var curtain := col if Catalog.is_special(id) else Color("ffb3c8")   # la ventana magica tiene cortinas de su color
			_poly(cv, [pos + Vector2(0, 0), pos + Vector2(44, 0), pos + Vector2(36, 150), pos + Vector2(0, 150)], curtain)
			_poly(cv, [pos + Vector2(r.size.x, 0), pos + Vector2(r.size.x - 44, 0), pos + Vector2(r.size.x - 36, 150), pos + Vector2(r.size.x, 150)], curtain)
			_round(cv, Rect2(pos + Vector2(26, 8), Vector2(98, 134)), Color("fff6e6"), 10)
			for px in 2:
				for py in 2:
					var pane := Rect2(pos + Vector2(34 + px * 44, 16 + py * 60), Vector2(40, 54))
					cv.draw_rect(pane, sky)
					if night_amount > 0.4:
						_star(cv, pane.position + Vector2(12 + py * 8, 14), 5.0, Color(1, 0.97, 0.75, night_amount))
						_star(cv, pane.position + Vector2(30, 36 - px * 6), 4.0, Color(1, 0.97, 0.75, night_amount))
					else:
						cv.draw_line(pane.position + Vector2(8, 40), pane.position + Vector2(20, 14), Color(1, 1, 1, 0.6), 4.0)
			_round(cv, Rect2(pos + Vector2(18, 142), Vector2(114, 14)), Color("e9d3b4"), 6)
		"deco_picture":
			_round(cv, Rect2(pos, r.size), Color("e8b04a"), 8)
			var canvas := Rect2(pos + Vector2(12, 12), r.size - Vector2(24, 24))
			cv.draw_rect(canvas, Color("bfe3f5"))
			cv.draw_circle(canvas.position + Vector2(66, 26), 12.0, Color("ffe066"))
			_ellipse(cv, canvas.position + Vector2(24, 96), 62.0, 34.0, Color("8fd19e"), false)
			_ellipse(cv, canvas.position + Vector2(78, 108), 50.0, 30.0, Color("6bbf7a"), false)
			cv.draw_rect(canvas, OUTLINE, false, 3.0)
		"deco_clock":
			_ellipse(cv, c, 46.0, 46.0, Color("fff6e6"))
			for h in 12:
				var a3 := TAU * h / 12.0
				cv.draw_line(c + Vector2(sin(a3), -cos(a3)) * 36.0, c + Vector2(sin(a3), -cos(a3)) * 42.0, OUTLINE, 3.0)
			cv.draw_line(c, c + Vector2(sin(TAU * 10.0 / 12.0), -cos(TAU * 10.0 / 12.0)) * 22.0, OUTLINE, 5.0, true)
			cv.draw_line(c, c + Vector2(sin(TAU * 2.0 / 12.0), -cos(TAU * 2.0 / 12.0)) * 32.0, OUTLINE, 3.0, true)
			cv.draw_circle(c, 5.0, Color("ff7aa0"))
		"deco_shelf":
			_poly(cv, [pos + Vector2(20, 64), pos + Vector2(44, 64), pos + Vector2(20, 88)], dark)
			_poly(cv, [pos + Vector2(r.size.x - 20, 64), pos + Vector2(r.size.x - 44, 64), pos + Vector2(r.size.x - 20, 88)], dark)
			_round(cv, Rect2(pos + Vector2(0, 48), Vector2(r.size.x, 18)), col, 8)
			_poly(cv, [pos + Vector2(14, 48), pos + Vector2(46, 48), pos + Vector2(40, 22), pos + Vector2(20, 22)], Color("e0885c"))
			_ellipse(cv, pos + Vector2(30, 14), 20.0, 14.0, Color("6bbf7a"))
			for i in 3:
				cv.draw_rect(Rect2(pos + Vector2(70, 48 - 12 * (i + 1)), Vector2(48, 12)), BOOK_COLORS[(i * 2) % BOOK_COLORS.size()])
				cv.draw_rect(Rect2(pos + Vector2(70, 48 - 12 * (i + 1)), Vector2(48, 12)), OUTLINE, false, 2.0)
			_round(cv, Rect2(pos + Vector2(132, 24), Vector2(24, 24)), Color("fff1f5"), 6)
		"deco_garland":
			var pts2 := PackedVector2Array()
			for i in 41:
				var t := float(i) / 40.0
				pts2.append(pos + Vector2(t * r.size.x, 10.0 + sin(t * PI) * 36.0))
			cv.draw_polyline(pts2, OUTLINE, 3.0, true)
			var flag_colors := [Color("ff9ecb"), Color("ffd166"), Color("8ecae6"), Color("90be6d"), Color("b388f5")]
			for i in range(1, 10):
				var t2 := float(i) / 10.0
				var p := pos + Vector2(t2 * r.size.x, 10.0 + sin(t2 * PI) * 36.0)
				_poly(cv, [p + Vector2(-13, 0), p + Vector2(13, 0), p + Vector2(0, 28)], flag_colors[i % flag_colors.size()])
		"deco_moon":
			var outer := []
			for a in range(95, 266, 10):
				outer.append(c + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 46.0 + Vector2(-6, 0))
			var d := c + Vector2(24, 0)
			for a in range(233, 126, -10):
				outer.append(d + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 57.0)
			_poly(cv, outer, Color("ffe08a"))
			_star(cv, c + Vector2(34, -26), 10.0, Color("ffe08a"))
			_star(cv, c + Vector2(44, 20), 7.0, Color("ffe08a"))
		"furn_teddy":
			var fur := col
			_ellipse(cv, pos + Vector2(26, 98), 18.0, 14.0, fur.darkened(0.08))
			_ellipse(cv, pos + Vector2(84, 98), 18.0, 14.0, fur.darkened(0.08))
			_ellipse(cv, c + Vector2(0, 24), 40.0, 44.0, fur)
			_ellipse(cv, c + Vector2(0, 30), 24.0, 28.0, fur.lightened(0.3), false)
			_ellipse(cv, pos + Vector2(14, 66), 13.0, 22.0, fur, true, 0.5)
			_ellipse(cv, pos + Vector2(96, 66), 13.0, 22.0, fur, true, -0.5)
			for ex in [-30.0, 30.0]:
				_ellipse(cv, c + Vector2(ex, -34), 14.0, 14.0, fur)
			_ellipse(cv, c + Vector2(0, -14), 38.0, 34.0, fur)
			_ellipse(cv, c + Vector2(0, -4), 18.0, 13.0, fur.lightened(0.35), false)
			cv.draw_circle(c + Vector2(-14, -20), 3.5, OUTLINE)
			cv.draw_circle(c + Vector2(14, -20), 3.5, OUTLINE)
			_ellipse(cv, c + Vector2(0, -8), 5.0, 4.0, OUTLINE, false)
			_poly(cv, [c + Vector2(-16, 12), c + Vector2(0, 20), c + Vector2(-16, 28)], Color("ff6b8b"))
			_poly(cv, [c + Vector2(16, 12), c + Vector2(0, 20), c + Vector2(16, 28)], Color("ff6b8b"))
		"furn_beanbag":
			_ellipse(cv, Vector2(c.x, r.end.y - 12.0), 76.0, 12.0, Color(0, 0, 0, 0.12), false)
			_ellipse(cv, Vector2(c.x + 12.0, r.end.y - 70.0), 48.0, 32.0, col, true, 0.25)
			_ellipse(cv, Vector2(c.x, r.end.y - 42.0), 78.0, 42.0, col)
			cv.draw_arc(Vector2(c.x - 6.0, r.end.y - 44.0), 50.0, 0.4, 2.7, 14, col.darkened(0.22), 3.0, true)
			cv.draw_arc(Vector2(c.x + 30.0, r.end.y - 50.0), 34.0, 0.2, 2.2, 12, col.darkened(0.22), 3.0, true)
			_ellipse(cv, Vector2(c.x - 24.0, r.end.y - 56.0), 20.0, 8.0, Color(1, 1, 1, 0.45), false, -0.5)
		"furn_globe":
			_ellipse(cv, Vector2(c.x, r.end.y - 10.0), 34.0, 9.0, dark)
			cv.draw_line(Vector2(c.x, r.end.y - 12.0), Vector2(c.x, r.end.y - 44.0), OUTLINE, 9.0)
			cv.draw_line(Vector2(c.x, r.end.y - 12.0), Vector2(c.x, r.end.y - 44.0), Color("d8a56f"), 5.0)
			var gc := Vector2(c.x, pos.y + 56.0)
			_ellipse(cv, gc, 46.0, 46.0, col)
			_ellipse(cv, gc + Vector2(-14, -10), 16.0, 12.0, Color("7bd389"), false, 0.4)
			_ellipse(cv, gc + Vector2(16, 12), 14.0, 18.0, Color("7bd389"), false, -0.3)
			cv.draw_arc(gc, 46.0, 0.0, TAU, 36, OUTLINE, 4.0, true)
			cv.draw_arc(gc, 58.0, 2.2, 5.2, 24, Color("d8a56f"), 5.0, true)
			_ellipse(cv, gc + Vector2(-16, -18), 8.0, 5.0, Color(1, 1, 1, 0.5), false, -0.6)
		"furn_aquarium":
			_round(cv, Rect2(pos + Vector2(10, 108), Vector2(r.size.x - 20, 30)), Color("c9985f"), 8)
			_round(cv, Rect2(pos + Vector2(4, 16), Vector2(r.size.x - 8, 100)), Color(0.72, 0.9, 1.0, 0.85), 14)
			cv.draw_rect(Rect2(pos + Vector2(10, 22), Vector2(r.size.x - 20, 14)), Color(1, 1, 1, 0.35))
			cv.draw_rect(Rect2(pos + Vector2(10, 92), Vector2(r.size.x - 20, 18)), Color("f2dca8"))
			for px2 in [26.0, 150.0]:
				cv.draw_line(pos + Vector2(px2, 94), pos + Vector2(px2 - 4.0, 56), Color("6bbf7a"), 6.0, true)
				cv.draw_line(pos + Vector2(px2 + 10.0, 94), pos + Vector2(px2 + 14.0, 64), Color("5fae7e"), 5.0, true)
			_ellipse(cv, pos + Vector2(98, 60), 18.0, 11.0, Color("ff9b54"))
			_poly(cv, [pos + Vector2(114, 60), pos + Vector2(130, 48), pos + Vector2(130, 72)], Color("ff9b54"))
			cv.draw_circle(pos + Vector2(90, 57), 2.5, OUTLINE)
			_ellipse(cv, pos + Vector2(66, 78), 12.0, 8.0, Color("ff7aa8"))
			_poly(cv, [pos + Vector2(54, 78), pos + Vector2(44, 70), pos + Vector2(44, 86)], Color("ff7aa8"))
			cv.draw_circle(pos + Vector2(74, 40), 4.0, Color(1, 1, 1, 0.8))
			cv.draw_circle(pos + Vector2(80, 28), 3.0, Color(1, 1, 1, 0.8))
			cv.draw_rect(Rect2(pos + Vector2(4, 16), Vector2(r.size.x - 8, 100)), OUTLINE, false, 4.0)
		"furn_piano":
			_round(cv, Rect2(pos + Vector2(14, 120), Vector2(172, 12)), dark, 5)
			_round(cv, Rect2(pos + Vector2(0, 10), Vector2(r.size.x, 100)), col, 12)
			_round(cv, Rect2(pos + Vector2(12, 24), Vector2(r.size.x - 24, 42)), col.darkened(0.25), 8)
			for i in 6:
				cv.draw_line(pos + Vector2(40 + i * 24, 28), pos + Vector2(40 + i * 24, 62), Color("c2b6d4"), 2.0)
			_round(cv, Rect2(pos + Vector2(8, 70), Vector2(r.size.x - 16, 34)), Color("fffaf0"), 6)
			for i in 13:
				cv.draw_line(pos + Vector2(14 + i * 14, 70), pos + Vector2(14 + i * 14, 104), OUTLINE, 2.0)
				if i % 7 != 2 and i % 7 != 6 and i < 12:
					cv.draw_rect(Rect2(pos + Vector2(8 + i * 14, 70), Vector2(12, 20)), Color("2b2433"))
			cv.draw_line(pos + Vector2(20, 110), pos + Vector2(20, 164), OUTLINE, 9.0)
			cv.draw_line(pos + Vector2(r.size.x - 20, 110), pos + Vector2(r.size.x - 20, 164), OUTLINE, 9.0)
			cv.draw_line(pos + Vector2(20, 110), pos + Vector2(20, 164), dark, 5.0)
			cv.draw_line(pos + Vector2(r.size.x - 20, 110), pos + Vector2(r.size.x - 20, 164), dark, 5.0)
		"deco_rainbow":
			var bands := [Color("ff6b7a"), Color("ffa94d"), Color("ffe066"), Color("7bd389"), Color("5bb8f5"), Color("a98bea")]
			for i in bands.size():
				cv.draw_arc(Vector2(c.x, r.end.y - 14.0), 92.0 - i * 11.0, PI, TAU, 28, bands[i], 11.0, true)
			cv.draw_arc(Vector2(c.x, r.end.y - 14.0), 98.0, PI, TAU, 28, OUTLINE, 3.0, true)
			cv.draw_arc(Vector2(c.x, r.end.y - 14.0), 26.0, PI, TAU, 20, OUTLINE, 3.0, true)
			for sx2 in [-1.0, 1.0]:
				var cc := Vector2(c.x + sx2 * 92.0, r.end.y - 18.0)
				for part2 in [[-14, 0, 15], [4, -8, 19], [20, 2, 14]]:
					_ellipse(cv, cc + Vector2(part2[0], part2[1]), part2[2], part2[2] * 0.8, Color("ffffff"))
		"deco_balloons":
			var cols := [Color("ff7aa8"), Color("5bb8f5"), Color("ffd24d")]
			for i in 3:
				var bc := pos + Vector2(32 + i * 44, 56 + (i % 2) * 22)
				cv.draw_line(bc + Vector2(0, 38), Vector2(c.x, r.end.y - 6.0), OUTLINE, 2.5)
				_ellipse(cv, bc, 30.0, 36.0, cols[i])
				_poly(cv, [bc + Vector2(-5, 36), bc + Vector2(5, 36), bc + Vector2(0, 44)], cols[i].darkened(0.1), false)
				_ellipse(cv, bc + Vector2(-10, -14), 7.0, 11.0, Color(1, 1, 1, 0.5), false, 0.4)
		"furn_dresser":
			for lx in [18.0, r.size.x - 18.0]:
				_round(cv, Rect2(pos + Vector2(lx - 8.0, 122), Vector2(16, 28)), dark, 5)
			_round(cv, Rect2(pos + Vector2(0, 40), Vector2(r.size.x, 90)), col, 14)
			for row in 3:
				_round(cv, Rect2(pos + Vector2(12, 52 + row * 26), Vector2(r.size.x - 24, 22)), light, 8)
				cv.draw_circle(pos + Vector2(r.size.x * 0.5, 63 + row * 26), 5.0, Color("fff1d6"))
				cv.draw_arc(pos + Vector2(r.size.x * 0.5, 63 + row * 26), 5.0, 0.0, TAU, 12, OUTLINE, 2.0)
			_round(cv, Rect2(pos + Vector2(-6, 30), Vector2(r.size.x + 12, 20)), light.lightened(0.1), 9)
		"furn_desk":
			for lx in [16.0, r.size.x - 34.0]:
				_round(cv, Rect2(pos + Vector2(lx, 66), Vector2(18, 84)), dark, 6)
			_round(cv, Rect2(pos + Vector2(26, 66), Vector2(86, 62)), col, 8)
			for row in 2:
				_round(cv, Rect2(pos + Vector2(34, 74 + row * 26), Vector2(70, 22)), light, 6)
				cv.draw_circle(pos + Vector2(69, 85 + row * 26), 4.5, Color("fff1d6"))
			_round(cv, Rect2(pos + Vector2(0, 50), Vector2(r.size.x, 22)), light.lightened(0.1), 10)
		"furn_wardrobe":
			for fx in [14.0, r.size.x - 38.0]:
				_round(cv, Rect2(pos + Vector2(fx, 212), Vector2(24, 18)), dark, 6)
			_round(cv, Rect2(pos + Vector2(0, 22), Vector2(r.size.x, 196)), col, 16)
			_round(cv, Rect2(pos + Vector2(10, 36), Vector2(r.size.x * 0.5 - 14.0, 168)), light, 12)
			_round(cv, Rect2(pos + Vector2(r.size.x * 0.5 + 4.0, 36), Vector2(r.size.x * 0.5 - 14.0, 168)), light, 12)
			for kx in [-12.0, 12.0]:
				cv.draw_circle(pos + Vector2(r.size.x * 0.5 + kx, 124), 5.0, Color("fff1d6"))
				cv.draw_arc(pos + Vector2(r.size.x * 0.5 + kx, 124), 5.0, 0.0, TAU, 12, OUTLINE, 2.0)
			_star(cv, pos + Vector2(r.size.x * 0.25 + 1.0, 80), 14.0, Color("fff1d6"))
			_star(cv, pos + Vector2(r.size.x * 0.75 - 1.0, 80), 14.0, Color("fff1d6"))
			_round(cv, Rect2(pos + Vector2(-6, 10), Vector2(r.size.x + 12, 20)), dark, 9)
		"furn_stool":
			for lx in [-1.0, 1.0]:
				cv.draw_line(pos + Vector2(45.0 + lx * 26.0, 40), pos + Vector2(45.0 + lx * 34.0, 78), OUTLINE, 10.0, true)
				cv.draw_line(pos + Vector2(45.0 + lx * 26.0, 40), pos + Vector2(45.0 + lx * 34.0, 78), dark, 6.0, true)
			_round(cv, Rect2(pos + Vector2(0, 20), Vector2(r.size.x, 24)), col, 11)
			cv.draw_circle(pos + Vector2(45, 32), 6.0, light)
		"deco_shelf_long":
			for bx in [44.0, r.size.x - 44.0]:
				_poly(cv, [pos + Vector2(bx - 14, 68), pos + Vector2(bx + 14, 68), pos + Vector2(bx, 88)], dark)
			_round(cv, Rect2(pos + Vector2(0, 50), Vector2(r.size.x, 18)), col, 8)
		"deco_shelf_cloud":
			for puff in [[Vector2(48, 76), 30.0, 20.0], [Vector2(110, 82), 40.0, 22.0], [Vector2(172, 76), 30.0, 20.0]]:
				_ellipse(cv, pos + puff[0], puff[1], puff[2], col)
			_round(cv, Rect2(pos + Vector2(8, 52), Vector2(r.size.x - 16, 28)), col, 14)
			cv.draw_circle(pos + Vector2(100, 70), 3.0, OUTLINE)
			cv.draw_circle(pos + Vector2(120, 70), 3.0, OUTLINE)
			cv.draw_arc(pos + Vector2(110, 72), 7.0, 0.3, PI - 0.3, 8, OUTLINE, 2.5, true)
			cv.draw_circle(pos + Vector2(88, 76), 5.0, Color(1.0, 0.7, 0.8, 0.8))
			cv.draw_circle(pos + Vector2(132, 76), 5.0, Color(1.0, 0.7, 0.8, 0.8))
		"toy_blocks":
			for blk in [[Vector2(6, 42), Color("ff9ecb")], [Vector2(46, 42), Color("8ecae6")], [Vector2(26, 4), Color("ffd166")]]:
				_round(cv, Rect2(pos + blk[0], Vector2(38, 38)), blk[1], 6)
				_star(cv, pos + blk[0] + Vector2(19, 19), 9.0, Color("fff1d6"))
		"toy_books":
			_round(cv, Rect2(pos + Vector2(4, 40), Vector2(92, 22)), Color("e76f51"), 6)
			_round(cv, Rect2(pos + Vector2(12, 20), Vector2(78, 20)), Color("8ecae6"), 6)
			_round(cv, Rect2(pos + Vector2(6, 2), Vector2(70, 18)), Color("ffd166"), 6)
			cv.draw_line(pos + Vector2(14, 51), pos + Vector2(84, 51), Color("fff1d6"), 3.0)
			cv.draw_line(pos + Vector2(22, 30), pos + Vector2(82, 30), Color("fff1d6"), 3.0)
			_star(cv, pos + Vector2(40, 11), 6.0, Color("fff1d6"))
		"toy_vase":
			for fl in [[Vector2(18, 24), Color("ff7aa8")], [Vector2(35, 14), Color("ffd24d")], [Vector2(52, 24), Color("b388f5")]]:
				cv.draw_line(pos + Vector2(35, 54), pos + fl[0], Color("5fae7e"), 4.0, true)
				for k in 5:
					var pa := TAU * k / 5.0
					cv.draw_circle(pos + fl[0] + Vector2(cos(pa), sin(pa)) * 7.0, 5.5, fl[1])
				cv.draw_circle(pos + fl[0], 4.5, Color("fff1d6"))
			_ellipse(cv, pos + Vector2(35, 84), 27.0, 26.0, col)
			_round(cv, Rect2(pos + Vector2(25, 50), Vector2(20, 22)), col, 6)
			_ellipse(cv, pos + Vector2(26, 78), 6.0, 10.0, Color(1, 1, 1, 0.5), false, 0.3)
			cv.draw_circle(pos + Vector2(35, 88), 5.0, Color("ff9ecb"))
		"toy_cactus":
			_round(cv, Rect2(pos + Vector2(4, 24), Vector2(14, 28)), col, 7)
			_round(cv, Rect2(pos + Vector2(4, 40), Vector2(26, 12)), col, 6)
			_round(cv, Rect2(pos + Vector2(52, 16), Vector2(14, 30)), col, 7)
			_round(cv, Rect2(pos + Vector2(40, 34), Vector2(26, 12)), col, 6)
			_round(cv, Rect2(pos + Vector2(20, 8), Vector2(30, 66)), col, 15)
			cv.draw_circle(pos + Vector2(35, 8), 6.0, Color("ff7aa8"))
			cv.draw_circle(pos + Vector2(29, 40), 2.6, OUTLINE)
			cv.draw_circle(pos + Vector2(41, 40), 2.6, OUTLINE)
			cv.draw_arc(pos + Vector2(35, 43), 5.0, 0.3, PI - 0.3, 8, OUTLINE, 2.0, true)
			_poly(cv, [pos + Vector2(12, 72), pos + Vector2(58, 72), pos + Vector2(52, 100), pos + Vector2(18, 100)], Color("e0885c"))
			_round(cv, Rect2(pos + Vector2(8, 66), Vector2(54, 12)), Color("e9996d"), 4)
		"toy_cake":
			_ellipse(cv, pos + Vector2(45, 80), 42.0, 9.0, Color("fff6e8"))
			_round(cv, Rect2(pos + Vector2(10, 44), Vector2(70, 36)), col, 10)
			_round(cv, Rect2(pos + Vector2(8, 40), Vector2(74, 16)), Color("fff6e8"), 8)
			for sx in [22.0, 38.0, 54.0, 68.0]:
				cv.draw_circle(pos + Vector2(sx, 66), 2.6, Color("ffb938") if int(sx) % 2 == 0 else Color("8ecae6"))
			_round(cv, Rect2(pos + Vector2(42, 14), Vector2(6, 26)), Color("8ecae6"), 3)
			_ellipse(cv, pos + Vector2(45, 8), 4.5, 7.0, Color("ffd23d"), false)
			for cx2 in [24.0, 66.0]:
				cv.draw_circle(pos + Vector2(cx2, 36), 7.0, Color("e63950"))
				cv.draw_arc(pos + Vector2(cx2, 36), 7.0, 0.0, TAU, 12, OUTLINE, 2.0)
		"toy_frame":
			_round(cv, Rect2(pos + Vector2(20, 72), Vector2(40, 16)), dark, 5)
			_round(cv, Rect2(pos + Vector2(4, 2), Vector2(72, 74)), col, 8)
			cv.draw_rect(Rect2(pos + Vector2(12, 10), Vector2(56, 58)), Color("ffe3ec"))
			cv.draw_circle(pos + Vector2(33, 34), 9.0, Color("ff7aa8"))
			cv.draw_circle(pos + Vector2(47, 34), 9.0, Color("ff7aa8"))
			_poly(cv, [pos + Vector2(24, 38), pos + Vector2(56, 38), pos + Vector2(40, 58)], Color("ff7aa8"), false)
			cv.draw_rect(Rect2(pos + Vector2(12, 10), Vector2(56, 58)), OUTLINE, false, 3.0)
		"toy_musicbox":
			_poly(cv, [pos + Vector2(45, 8), pos + Vector2(34, 30), pos + Vector2(56, 30)], Color("ff9ecb"))
			cv.draw_circle(pos + Vector2(45, 6), 5.0, Color("ffe0cc"))
			_round(cv, Rect2(pos + Vector2(4, 32), Vector2(82, 46)), col, 10)
			_round(cv, Rect2(pos + Vector2(0, 24), Vector2(90, 16)), light, 8)
			_star(cv, pos + Vector2(45, 57), 11.0, Color("fff1d6"))
			cv.draw_circle(pos + Vector2(45, 57), 3.0, OUTLINE)
		"toy_robot":
			for lx in [22.0, 46.0]:
				_round(cv, Rect2(pos + Vector2(lx, 92), Vector2(14, 18)), dark, 5)
			_round(cv, Rect2(pos + Vector2(0, 56), Vector2(12, 28)), dark, 6)
			_round(cv, Rect2(pos + Vector2(68, 56), Vector2(12, 28)), dark, 6)
			_round(cv, Rect2(pos + Vector2(12, 50), Vector2(56, 46)), col, 10)
			cv.draw_line(pos + Vector2(40, 14), pos + Vector2(40, 4), OUTLINE, 3.0)
			cv.draw_circle(pos + Vector2(40, 4), 4.0, Color("ff7aa8"))
			_round(cv, Rect2(pos + Vector2(16, 12), Vector2(48, 38)), light, 10)
			for ex in [30.0, 50.0]:
				cv.draw_circle(pos + Vector2(ex, 28), 6.5, Color.WHITE)
				cv.draw_circle(pos + Vector2(ex, 28), 3.0, OUTLINE)
			cv.draw_arc(pos + Vector2(40, 36), 8.0, 0.4, PI - 0.4, 8, OUTLINE, 2.5, true)
			cv.draw_circle(pos + Vector2(40, 72), 8.0, Color("ff7aa8"))
			cv.draw_arc(pos + Vector2(40, 72), 8.0, 0.0, TAU, 12, OUTLINE, 2.0)
		"toy_trophy":
			cv.draw_arc(pos + Vector2(10, 30), 14.0, PI * 0.5, PI * 1.5, 12, OUTLINE, 6.0, true)
			cv.draw_arc(pos + Vector2(60, 30), 14.0, -PI * 0.5, PI * 0.5, 12, OUTLINE, 6.0, true)
			cv.draw_arc(pos + Vector2(10, 30), 14.0, PI * 0.5, PI * 1.5, 12, col, 3.0, true)
			cv.draw_arc(pos + Vector2(60, 30), 14.0, -PI * 0.5, PI * 0.5, 12, col, 3.0, true)
			_round(cv, Rect2(pos + Vector2(14, 84), Vector2(42, 16)), Color("8a5a3c"), 5)
			_round(cv, Rect2(pos + Vector2(30, 62), Vector2(10, 24)), dark, 3)
			_poly(cv, [pos + Vector2(10, 12), pos + Vector2(60, 12), pos + Vector2(54, 48), pos + Vector2(46, 64), pos + Vector2(24, 64), pos + Vector2(16, 48)], col)
			_round(cv, Rect2(pos + Vector2(6, 6), Vector2(58, 10)), light, 5)
			_star(cv, pos + Vector2(35, 36), 10.0, Color("fff1d6"))
		# ---------------------------------------------- decoracion nueva (16/11/2026)
		"furn_chair":  # silla con respaldo redondo y almohadoncito
			for lx in [18.0, r.size.x - 18.0]:
				cv.draw_line(pos + Vector2(lx, 84), pos + Vector2(lx + (lx - c.x) * 0.12, r.size.y - 4.0), OUTLINE, 10.0, true)
				cv.draw_line(pos + Vector2(lx, 84), pos + Vector2(lx + (lx - c.x) * 0.12, r.size.y - 4.0), dark, 6.0, true)
			_round(cv, Rect2(pos + Vector2(10, 6), Vector2(r.size.x - 20, 76)), col, 30)
			_round(cv, Rect2(pos + Vector2(22, 18), Vector2(r.size.x - 44, 48)), light, 22)
			cv.draw_circle(pos + Vector2(c.x - pos.x, 42), 6.0, Color("fff1f5"))
			_round(cv, Rect2(pos + Vector2(2, 74), Vector2(r.size.x - 4, 20)), col.darkened(0.1), 10)
		"furn_armchair":  # sillon gordito con brazos y un almohadon
			_round(cv, Rect2(pos + Vector2(20, 2), Vector2(r.size.x - 40, 70)), dark, 30)
			_round(cv, Rect2(pos + Vector2(10, 52), Vector2(r.size.x - 20, 56)), col, 22)
			_round(cv, Rect2(pos + Vector2(0, 38), Vector2(38, 72)), col.darkened(0.08), 18)
			_round(cv, Rect2(pos + Vector2(r.size.x - 38, 38), Vector2(38, 72)), col.darkened(0.08), 18)
			_round(cv, Rect2(c + Vector2(-24, -44), Vector2(48, 40)), Color("fff1d6"), 14)
			_star(cv, c + Vector2(0, -24), 9.0, col)
			for lx in [24.0, r.size.x - 24.0]:
				_round(cv, Rect2(pos + Vector2(lx - 9.0, 106), Vector2(18, 20)), OUTLINE, 6)
		"furn_cushions":  # pila de almohadones en el piso
			var pcols := [col, Color("ffb3c8"), Color("9be3d0")]
			_round(cv, Rect2(pos + Vector2(0, 36), Vector2(98, 42)), pcols[0], 20)
			_round(cv, Rect2(pos + Vector2(70, 40), Vector2(100, 38)), pcols[1], 18)
			_round(cv, Rect2(pos + Vector2(38, 4), Vector2(86, 40)), pcols[2], 18)
			for cc in [pos + Vector2(49, 57), pos + Vector2(120, 59), pos + Vector2(81, 24)]:
				cv.draw_circle(cc, 4.5, Color(1, 1, 1, 0.75))
		"furn_nightstand":  # mesita de luz con un cajon
			for lx in [16.0, r.size.x - 16.0]:
				_round(cv, Rect2(pos + Vector2(lx - 6.0, 86), Vector2(12, 22)), dark, 4)
			_round(cv, Rect2(pos + Vector2(6, 30), Vector2(r.size.x - 12, 62)), col, 12)
			_round(cv, Rect2(pos + Vector2(16, 50), Vector2(r.size.x - 32, 28)), light, 8)
			cv.draw_circle(pos + Vector2(r.size.x * 0.5, 64), 5.0, Color("fff1d6"))
			cv.draw_arc(pos + Vector2(r.size.x * 0.5, 64), 5.0, 0.0, TAU, 12, OUTLINE, 2.0)
			_round(cv, Rect2(pos + Vector2(0, 22), Vector2(r.size.x, 16)), light.lightened(0.1), 8)
		"furn_tent":  # tipi de tela con banderines y entrada
			for pole in [-1.0, 1.0]:
				cv.draw_line(Vector2(c.x + pole * 14.0, pos.y + 2.0), Vector2(c.x - pole * 10.0, pos.y + 34.0), OUTLINE, 6.0, true)
			_poly(cv, [Vector2(c.x, pos.y + 18.0), Vector2(r.end.x - 4.0, r.end.y - 8.0), Vector2(pos.x + 4.0, r.end.y - 8.0)], col)
			for i in 4:   # rayitas de colores
				var ty2 := pos.y + 80.0 + i * 26.0
				var half := (ty2 - pos.y - 18.0) / (r.size.y - 26.0) * (r.size.x * 0.5 - 4.0)
				cv.draw_line(Vector2(c.x - half + 4.0, ty2), Vector2(c.x + half - 4.0, ty2), [Color("ff9ecb"), Color("8ecae6"), Color("ffd166"), Color("90be6d")][i], 6.0, true)
			_poly(cv, [Vector2(c.x, pos.y + 92.0), Vector2(c.x + 40.0, r.end.y - 8.0), Vector2(c.x - 40.0, r.end.y - 8.0)], Color("6b4a5a"))
			_poly(cv, [Vector2(c.x, pos.y + 92.0), Vector2(c.x - 40.0, r.end.y - 8.0), Vector2(c.x - 54.0, r.end.y - 8.0)], col.darkened(0.08))
			_star(cv, Vector2(c.x, pos.y + 60.0), 12.0, Color("ffd33d"))
		"furn_stove":  # cocinita de juguete: hornallas, horno y una ollita
			_round(cv, Rect2(pos + Vector2(4, 50), Vector2(r.size.x - 8, r.size.y - 54)), col, 14)
			_round(cv, Rect2(pos + Vector2(0, 40), Vector2(r.size.x, 18)), light, 8)
			for hx in [44.0, r.size.x - 44.0]:
				_ellipse(cv, pos + Vector2(hx, 46), 22.0, 6.0, Color("5b4a6a"), false)
			_round(cv, Rect2(pos + Vector2(26, 80), Vector2(r.size.x - 52, 62)), Color("fff6e6"), 10)
			_round(cv, Rect2(pos + Vector2(38, 92), Vector2(r.size.x - 76, 38)), Color(0.72, 0.85, 0.95, 0.9), 8)
			cv.draw_line(pos + Vector2(50, 84), pos + Vector2(r.size.x - 50, 84), OUTLINE, 4.0, true)
			for kx in [40.0, 70.0, 100.0, 130.0]:
				cv.draw_circle(pos + Vector2(kx, 68), 6.0, Color("ff9ecb"))
				cv.draw_arc(pos + Vector2(kx, 68), 6.0, 0.0, TAU, 12, OUTLINE, 2.0)
			_round(cv, Rect2(pos + Vector2(r.size.x - 74, 8), Vector2(48, 34)), Color("ff9b8a"), 10)
			cv.draw_line(pos + Vector2(r.size.x - 82, 18), pos + Vector2(r.size.x - 74, 18), OUTLINE, 4.0)
			for sx in [-8.0, 6.0]:   # vapor
				cv.draw_arc(pos + Vector2(r.size.x - 50 + sx, -2), 6.0, PI * 0.5, PI * 1.5, 8, Color(1, 1, 1, 0.8), 3.0, true)
		"furn_fridge":  # heladera redondeada con imanes
			_round(cv, Rect2(pos + Vector2(4, 4), Vector2(r.size.x - 8, r.size.y - 14)), col, 24)
			cv.draw_line(pos + Vector2(8, 82), pos + Vector2(r.size.x - 8, 82), OUTLINE, 4.0)
			for hy in [[40.0, 70.0], [104.0, 150.0]]:
				_round(cv, Rect2(pos + Vector2(r.size.x - 30, hy[0]), Vector2(10, hy[1] - hy[0])), Color("fff6f9"), 5)
			_star(cv, pos + Vector2(34, 40), 10.0, Color("ffd33d"))
			cv.draw_circle(pos + Vector2(52, 118), 9.0, Color("8ecae6"))
			cv.draw_circle(pos + Vector2(34, 136), 7.0, Color("90be6d"))
			_round(cv, Rect2(pos + Vector2(26, 100), Vector2(30, 22)), Color("fffaf0"), 4)
			for fx in [20.0, r.size.x - 20.0]:
				_round(cv, Rect2(pos + Vector2(fx - 8.0, r.size.y - 14), Vector2(16, 12)), OUTLINE, 4)
		"furn_telescope":  # telescopio en tripode mirando arriba
			for leg in [-1.0, 0.0, 1.0]:
				cv.draw_line(c + Vector2(0, 20), Vector2(c.x + leg * 50.0, r.end.y - 4.0), OUTLINE, 8.0, true)
				cv.draw_line(c + Vector2(0, 20), Vector2(c.x + leg * 50.0, r.end.y - 4.0), Color("d8a56f"), 4.0, true)
			var tdir := Vector2(0.62, -0.78)
			var tbase := c + Vector2(-28, 30)
			var tpts := [tbase + tdir.orthogonal() * 14.0, tbase - tdir.orthogonal() * 14.0,
				tbase + tdir * 120.0 - tdir.orthogonal() * 20.0, tbase + tdir * 120.0 + tdir.orthogonal() * 20.0]
			_poly(cv, tpts, col)
			_ellipse(cv, tbase + tdir * 120.0, 10.0, 21.0, light, true, tdir.angle())
			cv.draw_line(tbase + tdir * 50.0 - tdir.orthogonal() * 17.0, tbase + tdir * 50.0 + tdir.orthogonal() * 17.0, Color("ffd33d"), 6.0, true)
			cv.draw_circle(c + Vector2(0, 20), 9.0, dark)
			_star(cv, pos + Vector2(r.size.x - 14, 14), 9.0, Color("ffe066"))
		"furn_fountain":  # fuente de dos pisos con chorritos de agua
			_ellipse(cv, Vector2(c.x, r.end.y - 30.0), 90.0, 26.0, col.darkened(0.1))
			_ellipse(cv, Vector2(c.x, r.end.y - 38.0), 76.0, 18.0, Color("9fd8f0"), false)
			_round(cv, Rect2(Vector2(c.x - 14.0, pos.y + 60.0), Vector2(28, 70)), col, 8)
			_ellipse(cv, Vector2(c.x, pos.y + 62.0), 46.0, 14.0, col)
			_ellipse(cv, Vector2(c.x, pos.y + 58.0), 36.0, 8.0, Color("9fd8f0"), false)
			for side in [-1.0, 1.0]:
				cv.draw_arc(Vector2(c.x + side * 26.0, pos.y + 40.0), 26.0, PI if side < 0.0 else -PI * 0.5, -PI * 0.5 if side < 0.0 else 0.0, 12, Color("7fd0f0"), 5.0, true)
				cv.draw_arc(Vector2(c.x + side * 46.0, pos.y + 92.0), 34.0, PI if side < 0.0 else -PI * 0.5, -PI * 0.5 if side < 0.0 else 0.0, 12, Color("7fd0f0"), 5.0, true)
			cv.draw_circle(Vector2(c.x, pos.y + 18.0), 8.0, Color("7fd0f0"))
			cv.draw_line(Vector2(c.x, pos.y + 22.0), Vector2(c.x, pos.y + 54.0), Color("7fd0f0"), 6.0, true)
		"furn_bench":  # banco de plaza de tablas con patas de hierro
			for lx in [26.0, r.size.x - 26.0]:
				cv.draw_line(pos + Vector2(lx, 62), pos + Vector2(lx, r.size.y - 4.0), Color("4a3b4f"), 10.0, true)
				cv.draw_arc(pos + Vector2(lx + (12.0 if lx < c.x - pos.x else -12.0), r.size.y - 18.0), 10.0, 0.0, TAU, 12, Color("4a3b4f"), 4.0)
			for i in 2:
				_round(cv, Rect2(pos + Vector2(6, 6 + i * 24), Vector2(r.size.x - 12, 18)), col.darkened(0.05 * i), 8)
			_round(cv, Rect2(pos + Vector2(0, 62), Vector2(r.size.x, 20)), col, 9)
			_round(cv, Rect2(pos + Vector2(4, 78), Vector2(r.size.x - 8, 14)), col.darkened(0.15), 7)
		"furn_tree":  # arbolito en maceta con copa redonda y frutitas
			_poly(cv, [pos + Vector2(38, 176), pos + Vector2(r.size.x - 38, 176), pos + Vector2(r.size.x - 48, r.size.y - 2.0), pos + Vector2(48, r.size.y - 2.0)], Color("e0885c"))
			_round(cv, Rect2(pos + Vector2(32, 168), Vector2(r.size.x - 64, 16)), Color("e9996d"), 6)
			_round(cv, Rect2(Vector2(c.x - 10.0, pos.y + 100.0), Vector2(20, 72)), Color("a0704c"), 6)
			for blob in [[Vector2(0, 60), 62.0], [Vector2(-40, 82), 38.0], [Vector2(40, 82), 38.0], [Vector2(0, 30), 40.0]]:
				_ellipse(cv, Vector2(c.x, pos.y) + blob[0], blob[1], blob[1] * 0.9, col)
			for fr in [Vector2(-30, 60), Vector2(26, 44), Vector2(10, 92), Vector2(-14, 26), Vector2(44, 84)]:
				cv.draw_circle(Vector2(c.x, pos.y) + fr, 7.0, Color("ff8fa3"))
				cv.draw_circle(Vector2(c.x, pos.y) + fr + Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.7))
		"furn_flowers":  # cantero de madera lleno de flores
			for i in 7:
				var fx := pos.x + 20.0 + i * 23.0
				var fy := pos.y + 16.0 + float((i * 5) % 3) * 8.0
				cv.draw_line(Vector2(fx, fy), Vector2(fx, pos.y + 52.0), Color("5fae7e"), 4.0, true)
				var fc2: Color = [Color("ff7aa8"), Color("ffd24d"), Color("b388f5"), Color("ff9b54")][i % 4]
				for k2 in 5:
					var pa := TAU * k2 / 5.0
					cv.draw_circle(Vector2(fx, fy) + Vector2(cos(pa), sin(pa)) * 7.0, 6.0, fc2)
				cv.draw_circle(Vector2(fx, fy), 4.5, Color("fff1d6"))
			_round(cv, Rect2(pos + Vector2(0, 44), Vector2(r.size.x, r.size.y - 46)), col, 10)
			for i in 3:
				cv.draw_line(pos + Vector2(8, 58 + i * 12), pos + Vector2(r.size.x - 8, 58 + i * 12), col.darkened(0.18), 2.0)
		"furn_easel":  # atril con un lienzo a medio pintar
			cv.draw_line(Vector2(c.x - 34.0, r.end.y - 2.0), Vector2(c.x - 6.0, pos.y + 8.0), OUTLINE, 9.0, true)
			cv.draw_line(Vector2(c.x + 34.0, r.end.y - 2.0), Vector2(c.x + 6.0, pos.y + 8.0), OUTLINE, 9.0, true)
			cv.draw_line(Vector2(c.x - 34.0, r.end.y - 2.0), Vector2(c.x - 6.0, pos.y + 8.0), col, 5.0, true)
			cv.draw_line(Vector2(c.x + 34.0, r.end.y - 2.0), Vector2(c.x + 6.0, pos.y + 8.0), col, 5.0, true)
			cv.draw_line(Vector2(c.x, pos.y + 40.0), Vector2(c.x, r.end.y - 6.0), col.darkened(0.15), 5.0, true)
			_round(cv, Rect2(pos + Vector2(10, 22), Vector2(r.size.x - 20, 100)), Color("fffaf0"), 6)
			cv.draw_circle(pos + Vector2(44, 56), 14.0, Color("ffd24d"))
			_ellipse(cv, pos + Vector2(64, 100), 46.0, 16.0, Color("8fd19e"), false)
			cv.draw_arc(pos + Vector2(84, 76), 20.0, PI, TAU, 12, Color("ff7aa8"), 5.0, true)
			_round(cv, Rect2(pos + Vector2(4, 118), Vector2(r.size.x - 8, 12)), col.darkened(0.1), 5)
		"furn_slide":  # tobogan con escalera
			for lx in [24.0, 64.0]:
				cv.draw_line(pos + Vector2(lx, 30), pos + Vector2(lx, r.size.y - 4.0), OUTLINE, 9.0, true)
				cv.draw_line(pos + Vector2(lx, 30), pos + Vector2(lx, r.size.y - 4.0), Color("8ecae6"), 5.0, true)
			for i in 5:
				cv.draw_line(pos + Vector2(24, 54 + i * 26), pos + Vector2(64, 54 + i * 26), Color("8ecae6").darkened(0.15), 5.0, true)
			_round(cv, Rect2(pos + Vector2(14, 22), Vector2(70, 16)), Color("ffd166"), 7)
			var sl := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				sl.append(pos + Vector2(80.0 + t * (r.size.x - 86.0), 30.0 + (r.size.y - 52.0) * (t * t * (3.0 - 2.0 * t))))
			for i in range(16, -1, -1):
				var t2 := float(i) / 16.0
				sl.append(pos + Vector2(80.0 + t2 * (r.size.x - 86.0), 52.0 + (r.size.y - 52.0) * (t2 * t2 * (3.0 - 2.0 * t2)) - 4.0 * t2))
			cv.draw_colored_polygon(sl, col)
			sl.append(sl[0])
			cv.draw_polyline(sl, OUTLINE, 4.0, true)
		"rug_round":  # alfombra redonda con flecos y corazoncitos
			_ellipse(cv, c, r.size.x * 0.5 - 6.0, r.size.y * 0.5 - 4.0, col)
			_ellipse(cv, c, r.size.x * 0.5 - 26.0, r.size.y * 0.5 - 12.0, light, false)
			_ellipse(cv, c, r.size.x * 0.5 - 52.0, r.size.y * 0.5 - 22.0, col.lightened(0.1), false)
			for i in 8:
				var a := TAU * i / 8.0
				cv.draw_circle(c + Vector2(cos(a) * (r.size.x * 0.5 - 38.0), sin(a) * (r.size.y * 0.5 - 17.0)), 4.0, Color("fff6e8"))
		"rug_stripes":  # alfombra rectangular a rayas con flecos
			for fx in range(int(pos.x) + 14, int(r.end.x) - 10, 12):
				cv.draw_line(Vector2(fx, pos.y + 4.0), Vector2(fx, pos.y + 12.0), Color("fff6e8"), 3.0)
				cv.draw_line(Vector2(fx, r.end.y - 12.0), Vector2(fx, r.end.y - 4.0), Color("fff6e8"), 3.0)
			var rr := Rect2(pos + Vector2(6, 10), r.size - Vector2(12, 20))
			cv.draw_rect(rr, Color("fff6e8"))
			var stripe_cols := [col, Color("ffc2d9"), Color("ffe6a8")]
			for i in 5:
				cv.draw_rect(Rect2(rr.position + Vector2(20.0 + i * (rr.size.x - 40.0) / 5.0, 0), Vector2((rr.size.x - 40.0) / 10.0, rr.size.y)), stripe_cols[i % 3])
			cv.draw_rect(rr, OUTLINE, false, 3.0)
		"rug_star":  # alfombra en forma de estrella aplastada
			var spts := PackedVector2Array()
			for i in 10:
				var rad := 1.0 if i % 2 == 0 else 0.55
				var a := -PI / 2.0 + PI * i / 5.0
				spts.append(c + Vector2(cos(a) * (r.size.x * 0.5 - 4.0), sin(a) * (r.size.y * 0.5 - 2.0) + 6.0) * rad)
			cv.draw_colored_polygon(spts, col)
			spts.append(spts[0])
			cv.draw_polyline(spts, OUTLINE, 3.0, true)
			_ellipse(cv, c + Vector2(0, 4), 34.0, 12.0, light, false)
		"rug_cloud":  # alfombra nube con caritas
			for part in [[-90, 6, 44], [-40, -6, 54], [20, -8, 56], [80, 4, 46], [0, 14, 70]]:
				_ellipse(cv, c + Vector2(part[0], part[1]), part[2], part[2] * 0.48, col.darkened(0.05))
			for part in [[-90, 4, 38], [-40, -8, 48], [20, -10, 50], [80, 2, 40], [0, 12, 64]]:
				_ellipse(cv, c + Vector2(part[0], part[1]), part[2], part[2] * 0.44, col, false)
			cv.draw_circle(c + Vector2(-12, 0), 3.5, OUTLINE)
			cv.draw_circle(c + Vector2(12, 0), 3.5, OUTLINE)
			cv.draw_arc(c + Vector2(0, 4), 7.0, 0.3, PI - 0.3, 8, OUTLINE, 2.5, true)
			cv.draw_circle(c + Vector2(-24, 6), 5.0, Color(1.0, 0.7, 0.8, 0.8))
			cv.draw_circle(c + Vector2(24, 6), 5.0, Color(1.0, 0.7, 0.8, 0.8))
		"deco_mirror":  # espejo ovalado con marco dorado
			_ellipse(cv, c, r.size.x * 0.5 - 4.0, r.size.y * 0.5 - 4.0, col)
			_ellipse(cv, c, r.size.x * 0.5 - 14.0, r.size.y * 0.5 - 14.0, Color("dff3ff"))
			cv.draw_line(c + Vector2(-20, 20), c + Vector2(4, -30), Color(1, 1, 1, 0.8), 6.0, true)
			cv.draw_line(c + Vector2(-6, 30), c + Vector2(14, -10), Color(1, 1, 1, 0.6), 4.0, true)
			_star(cv, Vector2(c.x, pos.y + 6.0), 10.0, Color("fff1d6"))
		"deco_plant_hanging":  # maceta colgada del techo con hojas que caen
			for sx in [-1.0, 1.0]:
				cv.draw_line(Vector2(c.x, pos.y), Vector2(c.x + sx * 34.0, pos.y + 70.0), OUTLINE, 3.0, true)
			for vine in [[-30.0, 150.0], [-10.0, 166.0], [16.0, 140.0], [34.0, 120.0]]:
				var vx: float = c.x + vine[0]
				cv.draw_line(Vector2(vx, pos.y + 80.0), Vector2(vx + 4.0, pos.y + vine[1]), Color("5fae7e"), 4.0, true)
				var vy := pos.y + 92.0
				while vy < pos.y + vine[1] - 4.0:
					_ellipse(cv, Vector2(vx + 2.0 + (8.0 if int(vy) % 2 == 0 else -8.0), vy), 9.0, 5.0, Color("7bc98a"), false, 0.5 if int(vy) % 2 == 0 else -0.5)
					vy += 16.0
			_ellipse(cv, Vector2(c.x, pos.y + 66.0), 40.0, 14.0, Color("6bbf7a"))
			_poly(cv, [Vector2(c.x - 40.0, pos.y + 70.0), Vector2(c.x + 40.0, pos.y + 70.0), Vector2(c.x + 28.0, pos.y + 100.0), Vector2(c.x - 28.0, pos.y + 100.0)], col)
			cv.draw_circle(Vector2(c.x, pos.y), 5.0, OUTLINE)
		"deco_stars":  # estrellas que brillan (mas de noche)
			var glow := 0.25 + 0.6 * night_amount
			for st in [[Vector2(-60, -20), 22.0], [Vector2(10, -34), 16.0], [Vector2(62, -6), 26.0], [Vector2(-20, 26), 14.0], [Vector2(36, 34), 12.0], [Vector2(-74, 34), 10.0]]:
				cv.draw_circle(c + st[0], st[1] * 1.5, Color(1.0, 0.95, 0.6, glow * 0.35))
				_star(cv, c + st[0], st[1], col)
				_star(cv, c + st[0], st[1] * 0.45, Color(1, 1, 1, 0.7))
		"deco_board":  # pizarron con dibujitos de tiza
			_round(cv, Rect2(pos, r.size - Vector2(0, 14)), Color("c9985f"), 10)
			cv.draw_rect(Rect2(pos + Vector2(10, 10), r.size - Vector2(20, 34)), col)
			cv.draw_rect(Rect2(pos + Vector2(10, 10), r.size - Vector2(20, 34)), OUTLINE, false, 3.0)
			var chalk := Color(1, 1, 1, 0.85)
			cv.draw_string(ThemeDB.fallback_font, pos + Vector2(22, 54), "1+2=3", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, chalk)
			_star(cv, pos + Vector2(r.size.x - 40, 44), 14.0, Color(1.0, 0.9, 0.5, 0.85))
			cv.draw_arc(pos + Vector2(60, 84), 14.0, 0.0, TAU, 14, Color(1.0, 0.75, 0.85, 0.9), 3.0, true)
			cv.draw_line(pos + Vector2(100, 92), pos + Vector2(150, 80), chalk, 3.0, true)
			_round(cv, Rect2(pos + Vector2(4, r.size.y - 20), Vector2(r.size.x - 8, 14)), Color("c9985f").darkened(0.1), 5)
			_round(cv, Rect2(pos + Vector2(40, r.size.y - 26), Vector2(22, 8)), Color.WHITE, 3)
		"deco_map":  # mapa del mundo con continentes y una ruta
			_round(cv, Rect2(pos, r.size), Color("e9d3b4"), 8)
			cv.draw_rect(Rect2(pos + Vector2(10, 10), r.size - Vector2(20, 20)), col)
			for land in [[Vector2(48, 44), 30.0, 22.0, 0.3], [Vector2(62, 92), 16.0, 24.0, -0.2], [Vector2(112, 50), 22.0, 16.0, 0.0],
					[Vector2(120, 88), 16.0, 20.0, 0.2], [Vector2(152, 56), 30.0, 22.0, -0.3], [Vector2(166, 100), 14.0, 10.0, 0.0]]:
				_ellipse(cv, pos + land[0], land[1], land[2], Color("9fd19e"), false, land[3])
			for i in 6:
				cv.draw_circle(pos + Vector2(60 + i * 16, 70 - sin(i * 0.9) * 14.0), 2.5, Color("e5484d"))
			_star(cv, pos + Vector2(148, 52), 8.0, Color("e5484d"))
			cv.draw_rect(Rect2(pos + Vector2(10, 10), r.size - Vector2(20, 20)), OUTLINE, false, 3.0)
		"deco_cloud":  # nube colgante con gotitas y estrellas que cuelgan
			for hang in [[-40.0, 112.0, "drop"], [-10.0, 128.0, "star"], [22.0, 118.0, "drop"], [50.0, 132.0, "star"]]:
				var hx: float = c.x + hang[0]
				cv.draw_line(Vector2(hx, pos.y + 60.0), Vector2(hx, pos.y + hang[1] - 10.0), OUTLINE, 2.0)
				if hang[2] == "star":
					_star(cv, Vector2(hx, pos.y + hang[1]), 10.0, Color("ffe066"))
				else:
					_ellipse(cv, Vector2(hx, pos.y + hang[1]), 7.0, 9.0, Color("8ecae6"))
			for part in [[-44, 44, 28], [-12, 30, 36], [26, 34, 32], [52, 48, 22], [0, 52, 40]]:
				_ellipse(cv, Vector2(c.x + part[0], pos.y + part[1]), part[2], part[2] * 0.75, col)
			for part in [[-44, 44, 22], [-12, 30, 30], [26, 34, 26], [52, 48, 16], [0, 52, 34]]:
				_ellipse(cv, Vector2(c.x + part[0], pos.y + part[1]), part[2], part[2] * 0.72, col, false)
			cv.draw_circle(Vector2(c.x - 10.0, pos.y + 46.0), 3.0, OUTLINE)
			cv.draw_circle(Vector2(c.x + 10.0, pos.y + 46.0), 3.0, OUTLINE)
			cv.draw_arc(Vector2(c.x, pos.y + 50.0), 6.0, 0.3, PI - 0.3, 8, OUTLINE, 2.5, true)
		"toy_lamp":  # velador de mesa
			cv.draw_circle(c + Vector2(0, -20), 40.0, Color(1.0, 0.85, 0.5, 0.15 + 0.25 * night_amount))
			_ellipse(cv, Vector2(c.x, r.end.y - 8.0), 24.0, 7.0, col.darkened(0.2))
			_ellipse(cv, Vector2(c.x, r.end.y - 28.0), 16.0, 20.0, col)
			_poly(cv, [Vector2(c.x - 16.0, pos.y + 6.0), Vector2(c.x + 16.0, pos.y + 6.0), Vector2(c.x + 30.0, pos.y + 50.0), Vector2(c.x - 30.0, pos.y + 50.0)], Color("fff1d6"))
			cv.draw_line(Vector2(c.x - 24.0, pos.y + 40.0), Vector2(c.x + 24.0, pos.y + 40.0), Color("ff9ecb"), 4.0, true)
		"toy_alarm":  # despertador con campanitas
			for sx in [-1.0, 1.0]:
				_ellipse(cv, c + Vector2(sx * 20.0, -24.0), 12.0, 9.0, Color("ffd33d"), true, sx * 0.5)
				cv.draw_line(c + Vector2(sx * 18.0, 22.0), c + Vector2(sx * 24.0, 34.0), OUTLINE, 5.0, true)
			_ellipse(cv, c + Vector2(0, 4), 30.0, 30.0, col)
			_ellipse(cv, c + Vector2(0, 4), 22.0, 22.0, Color("fff6e6"))
			cv.draw_line(c + Vector2(0, 4), c + Vector2(0, -10), OUTLINE, 3.0, true)
			cv.draw_line(c + Vector2(0, 4), c + Vector2(10, 8), OUTLINE, 3.0, true)
		"toy_teacup":  # tetera y tacita
			_ellipse(cv, Vector2(pos.x + 34.0, r.end.y - 22.0), 26.0, 20.0, col)
			cv.draw_arc(Vector2(pos.x + 8.0, r.end.y - 26.0), 10.0, PI * 0.5, PI * 1.5, 10, OUTLINE, 4.0, true)
			_poly(cv, [Vector2(pos.x + 56.0, r.end.y - 28.0), Vector2(pos.x + 72.0, r.end.y - 40.0), Vector2(pos.x + 60.0, r.end.y - 18.0)], col)
			cv.draw_circle(Vector2(pos.x + 34.0, r.end.y - 44.0), 5.0, Color("ff9ecb"))
			cv.draw_circle(Vector2(pos.x + 34.0, r.end.y - 22.0), 5.0, Color("ff9ecb"))
			_ellipse(cv, Vector2(r.end.x - 18.0, r.end.y - 6.0), 16.0, 4.0, Color("ffd1e3"))
			_round(cv, Rect2(Vector2(r.end.x - 30.0, r.end.y - 24.0), Vector2(24, 18)), col, 7)
		"toy_dino":  # dinosaurio verde con pinches
			for sp in [Vector2(-20, -18), Vector2(-4, -26), Vector2(12, -24)]:
				_poly(cv, [c + sp + Vector2(-8, 4), c + sp + Vector2(8, 4), c + sp + Vector2(0, -10)], Color("ffd166"))
			_ellipse(cv, c + Vector2(-4, 6), 30.0, 22.0, col)
			_poly(cv, [c + Vector2(-30, 4), c + Vector2(-48, 22), c + Vector2(-24, 18)], col)
			_ellipse(cv, c + Vector2(30, -16), 18.0, 14.0, col)
			cv.draw_circle(c + Vector2(34, -20), 3.0, OUTLINE)
			cv.draw_arc(c + Vector2(36, -12), 6.0, 0.2, PI * 0.8, 8, OUTLINE, 2.0, true)
			for lx in [-18.0, 10.0]:
				_round(cv, Rect2(c + Vector2(lx, 20), Vector2(14, 18)), col.darkened(0.1), 5)
			cv.draw_circle(c + Vector2(-6, 8), 5.0, col.lightened(0.3))
		"toy_candles":  # tres velas con su llamita
			for cnd in [[-22.0, 40.0], [0.0, 56.0], [22.0, 32.0]]:
				var ch: float = cnd[1]
				var cx3: float = c.x + cnd[0]
				cv.draw_circle(Vector2(cx3, r.end.y - ch - 14.0), 14.0, Color(1.0, 0.85, 0.5, 0.2 + 0.3 * night_amount))
				_round(cv, Rect2(Vector2(cx3 - 9.0, r.end.y - ch - 2.0), Vector2(18, ch)), [Color("ffc2d9"), col, Color("c8e6ff")][int(cnd[0] + 22.0) / 22], 6)
				_ellipse(cv, Vector2(cx3, r.end.y - ch - 12.0), 5.0, 9.0, Color("ffb938"), false)
				_ellipse(cv, Vector2(cx3, r.end.y - ch - 10.0), 2.5, 5.0, Color("fff3b0"), false)
		"toy_duck":  # patito de goma
			_ellipse(cv, c + Vector2(-2, 12), 30.0, 20.0, col)
			_ellipse(cv, c + Vector2(12, -12), 17.0, 16.0, col)
			_poly(cv, [c + Vector2(26, -12), c + Vector2(38, -8), c + Vector2(26, -4)], Color("ff9b54"))
			cv.draw_circle(c + Vector2(16, -16), 3.0, OUTLINE)
			_ellipse(cv, c + Vector2(-8, 10), 12.0, 7.0, col.darkened(0.12), false, -0.3)
		"toy_snowglobe":  # bola de nieve con casita
			_round(cv, Rect2(Vector2(c.x - 30.0, r.end.y - 22.0), Vector2(60, 20)), Color("b5838d"), 8)
			_ellipse(cv, c + Vector2(0, -8), 34.0, 34.0, Color(0.85, 0.95, 1.0, 0.9))
			_poly(cv, [c + Vector2(-12, 6), c + Vector2(12, 6), c + Vector2(12, 20), c + Vector2(-12, 20)], Color("ffd1e3"), false)
			_poly(cv, [c + Vector2(-16, 8), c + Vector2(0, -6), c + Vector2(16, 8)], Color("e5484d"), false)
			for fl in [Vector2(-18, -24), Vector2(6, -32), Vector2(20, -14), Vector2(-8, -12), Vector2(14, -26)]:
				cv.draw_circle(c + fl, 2.5, Color.WHITE)
			cv.draw_arc(c + Vector2(0, -8), 34.0, 0.0, TAU, 28, OUTLINE, 4.0, true)
			_ellipse(cv, c + Vector2(-14, -22), 6.0, 9.0, Color(1, 1, 1, 0.6), false, 0.5)
		"toy_fruit":  # frutero con manzanas, banana y uvas
			cv.draw_circle(c + Vector2(-20, -6), 13.0, Color("e5484d"))
			cv.draw_circle(c + Vector2(4, -12), 13.0, Color("90be6d"))
			for g in [Vector2(24, -8), Vector2(32, -2), Vector2(20, 0), Vector2(28, 6)]:
				cv.draw_circle(c + g, 6.0, Color("b388f5"))
			cv.draw_arc(c + Vector2(0, -2), 26.0, PI * 1.15, PI * 1.75, 12, Color("ffd93d"), 8.0, true)
			_poly(cv, [c + Vector2(-46, 4), c + Vector2(46, 4), c + Vector2(30, 28), c + Vector2(-30, 28)], col)
			cv.draw_line(c + Vector2(-40, 10), c + Vector2(40, 10), col.lightened(0.3), 3.0)
		_:
			_round(cv, r, col)
