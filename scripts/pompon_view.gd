class_name PomponView
extends Control
## Dibuja un Pompon (o su huevo) en estilo "kawaii": formas redondeadas, contorno suave y
## mejillas rosadas. Usa la genetica del Pompon (especie, colores, ojos, boca, cara) y la
## ropa equipada. Toca al Pompon para acariciarlo.

signal petted

const OUTLINE := Color("5b3a4a")
const EYE_DARK := Color("2d1b2e")
const PINK := Color("ffb3c1")
const BLUSH := Color(1.0, 0.55, 0.62, 0.55)
const CREAM := Color("fff1d6")
const STAGE_SCALE := [1.0, 0.6, 0.78, 0.9, 1.0]
const FLOOR_Y := 175.0  # el piso en coordenadas de diseno (la cabeza esta en y=0)

var pompon: Pompon = null
var equipped := {}
var facing := 1.0           # 1 = mira a la derecha, -1 = a la izquierda (se espeja al caminar)
var walking := false
var animated := true        # false para miniaturas (se dibuja una sola vez)
var head_zoom := 0.0        # > 0: primer plano de la cabeza (miniaturas de gorros y lentes)
var item_only_id := ""      # si se indica, dibuja SOLO esa prenda (sin el Pompon): miniaturas de la tienda
var face_mood := ""         # "shy" (ojitos bajos y mas rubor) o "happy" (ojitos ^ ^); "" = normal
var lean := 0.0             # inclinacion del cuerpo desde los pies (radianes; olerse, acariciarse)
var show_egg := false       # dibujarlo como huevo aunque ya nacio (el momento antes de salir)
var sleeping := false       # duerme: ojitos cerrados y "zzz"
var sleep_props := ""       # de noche en su camita: "bed" (almohada y mantita) o "mat" (ademas una colchoneta en el piso)
var egg_cracks := 0         # rajaduras en la cascara (0 a 3)

var _t := randf() * 10.0
var _walk := 0.0
var _bounce := 0.0
var _hearts: Array = []
var _act := ""
var _act_t := 0.0
var _base_xf := Transform2D.IDENTITY   # transformacion normal del personaje (para dibujar el tazon sin inclinarse)
var _c1 := Color.WHITE
var _c2 := Color.WHITE

const ACT_SECONDS := 2.8

# Miniaturas de gorros: [centro del gorro, ancho/alto que ocupa] para que todos se vean del mismo tamano.
const HAT_FIT := {
	"hat_beanie": [Vector2(0, -108), 215.0], "hat_cap": [Vector2(10, -88), 205.0],
	"hat_bow": [Vector2(-58, -74), 100.0], "hat_crown": [Vector2(0, -106), 150.0],
	"hat_party": [Vector2(2, -120), 135.0], "hat_flower": [Vector2(0, -90), 205.0],
	"hat_straw": [Vector2(0, -80), 260.0], "hat_chef": [Vector2(0, -110), 150.0],
	"hat_beret": [Vector2(-10, -96), 200.0], "hat_ears": [Vector2(0, -116), 190.0],
	"hat_witch": [Vector2(0, -122), 240.0], "hat_halo": [Vector2(0, -130), 140.0],
}


## Pompon de muestra (adulto, sano) para menus y vistas previas.
static func make_sample(species: String, c1: Color, c2: Color, eyes := "redondos", mouth := "sonrisa", face := "redonda") -> Pompon:
	var p := Pompon.new()
	p.species = species
	p.color_primary = c1
	p.color_secondary = c2
	p.eyes = eyes
	p.mouth = mouth
	p.face = face
	p.born_at = int(Time.get_unix_time_from_system()) - 90 * 86400
	for s in Pompon.STAT_NAMES:
		p.stats[s] = 100.0
	return p


## De noche: colchoneta (si duerme en el piso) y almohada, detras del Pompon.
func _draw_pillow() -> void:
	if sleep_props == "mat":
		_ell(Vector2(0, FLOOR_Y - 4.0), 150.0, 30.0, Color("d7c6f2"))
		_ell(Vector2(0, FLOOR_Y - 8.0), 134.0, 22.0, Color("e9defa"), false)
	_ell(Vector2(-6, 60), 120.0, 46.0, Color("fff8fb"))
	_ell(Vector2(-6, 52), 96.0, 24.0, Color("fde8f1"), false)


## Mantita de dormir sobre las patitas (con lunares y el borde doblado).
func _draw_blanket() -> void:
	var col := Color("b9a5ee")
	var pts: Array = [Vector2(-128, 182)]
	for i in 9:
		var x := -128.0 + i * 32.0
		pts.append(Vector2(x, 86.0 + sin(i * 1.3 + _t * 0.8) * 3.0))
	pts.append(Vector2(128, 182))
	_poly(pts, col, true, 5.0)
	draw_line(Vector2(-124, 98), Vector2(124, 98), Color("ddd2fb"), 14.0, true)
	for d in [Vector2(-80, 132), Vector2(-20, 150), Vector2(40, 128), Vector2(92, 156), Vector2(-104, 162)]:
		draw_circle(d, 7.0, Color(1, 1, 1, 0.7))


## "zzz" que sube de la cabeza mientras duerme.
func _draw_zzz() -> void:
	var font := get_theme_default_font()
	var head := head_point()
	var bs := body_scale()
	for i in 3:
		var k := fmod(_t * 0.45 + i / 3.0, 1.0)
		var pos := head + Vector2(70.0 + k * 50.0, -80.0 - k * 110.0) * bs
		var fs := int((18.0 + k * 18.0) * maxf(bs, 0.6))
		var a := sin(k * PI)
		draw_string_outline(font, pos, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(1, 1, 1, a))
		draw_string(font, pos, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.48, 0.55, 0.88, a))


## Etapa que se dibuja (0 = huevo).
func _stage() -> int:
	if pompon == null or show_egg:
		return 0
	return pompon.stage_index(int(Time.get_unix_time_from_system()))


## Centro de la cabeza (coordenadas locales), para poner efectos encima o cerca de la nariz.
func head_point() -> Vector2:
	var stage := _stage()
	var s: float = minf(size.x / 330.0, size.y / 400.0) * STAGE_SCALE[stage]
	return Vector2(size.x * 0.5, size.y - 6.0 - s * FLOOR_Y)


## Tamano del personaje en pantalla (1 = adulto en una caja de 330 x 400).
func body_scale() -> float:
	var stage := _stage()
	return minf(size.x / 330.0, size.y / 400.0) * STAGE_SCALE[stage]


## Zoom para que el Pompon entre enterito en una foto redonda (cada etapa tiene otro tamano).
static func portrait_zoom(p: Pompon, now: int) -> float:
	return [0.0, 1.1, 0.92, 0.9, 0.88][clampi(p.stage_index(now), 0, 4)] if p != null else 0.0


func set_pompon(p: Pompon, eq := {}) -> void:
	pompon = p
	equipped = eq
	queue_redraw()


func _ready() -> void:
	set_process(animated)


## Animacion de una actividad: "eat" (comer), "drink" (beber) o "bath" (banarse).
func act(kind: String) -> void:
	_act = kind
	_act_t = ACT_SECONDS


func _process(delta: float) -> void:
	_t += delta
	if walking:
		_walk += delta * 11.0
	var act_before := _act_t
	_act_t = maxf(0.0, _act_t - delta)
	if act_before > 0.0 and _act_t <= 0.0 and (_act == "eat" or _act == "drink"):
		celebrate(3)  # termino de comer o beber: ¡contento!
	_bounce = maxf(0.0, _bounce - delta * 2.2)
	for h in _hearts:
		h["age"] += delta
		h["p"] = h["p"] + Vector2(0.0, -55.0 * delta)
	_hearts = _hearts.filter(func(h): return h["age"] < 1.2)
	queue_redraw()


## Solo cuenta el toque encima del personaje (no el espacio vacio de alrededor): tocar la pared
## no es acariciarlo, y asi el cuarto se puede deslizar desde cualquier lado.
func _has_point(point: Vector2) -> bool:
	if pompon == null:
		return false
	var stage := _stage()
	var s: float = minf(size.x / 330.0, size.y / 400.0) * STAGE_SCALE[stage]
	var floor_pos := Vector2(size.x * 0.5, size.y - 6.0)
	if stage == 0:  # el huevo se apoya en el piso y mide ~200 de alto
		var d := (point - floor_pos) / s
		return absf(d.x) <= 85.0 and d.y >= -215.0 and d.y <= 12.0
	var origin := floor_pos - Vector2(0.0, s * FLOOR_Y)
	var d2 := (point - origin) / s
	return absf(d2.x) <= 100.0 and d2.y >= -150.0 and d2.y <= 180.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		celebrate(3)
		petted.emit()


## Salto con corazones (al acariciarlo, al nacer, al crecer).
func celebrate(hearts := 6) -> void:
	_bounce = 1.0
	for i in hearts:
		_hearts.append({"p": Vector2(randf_range(-90.0, 90.0), randf_range(-120.0, -60.0)), "age": randf_range(-0.3, 0.0)})


# ------------------------------------------------------------------ helpers

func _ell(c: Vector2, rx: float, ry: float, fill: Color, outline := true, rot := 0.0, w := 5.0) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry).rotated(rot) + c)
	draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		draw_polyline(pts, OUTLINE, w, true)


func _poly(points: Array, fill: Color, outline := true, w := 5.0) -> void:
	var pts := PackedVector2Array(points)
	draw_colored_polygon(pts, fill)
	if outline:
		pts.append(pts[0])
		draw_polyline(pts, OUTLINE, w, true)


func _mirror(points: Array) -> Array:
	var out := []
	for p in points:
		out.append(Vector2(-p.x, p.y))
	out.reverse()
	return out


## Linea gruesa con contorno y puntas redondeadas (colas).
func _tube(pts: Array, width: float, fill: Color) -> void:
	var packed := PackedVector2Array(pts)
	draw_polyline(packed, OUTLINE, width + 10.0, true)
	draw_circle(packed[0], (width + 10.0) * 0.5, OUTLINE)
	draw_circle(packed[packed.size() - 1], (width + 10.0) * 0.5, OUTLINE)
	draw_polyline(packed, fill, width, true)
	draw_circle(packed[0], width * 0.5, fill)
	draw_circle(packed[packed.size() - 1], width * 0.5, fill)


func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, steps := 14) -> Array:
	var out := []
	for i in steps + 1:
		var t := float(i) / steps
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return out


func _star(c: Vector2, r: float, points := 5) -> Array:
	var out := []
	for i in points * 2:
		var rr := r if i % 2 == 0 else r * 0.45
		var a := -PI / 2.0 + PI * i / points
		out.append(c + Vector2(cos(a), sin(a)) * rr)
	return out


func _heart(c: Vector2, s: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(c + Vector2(x, y) * s)
	draw_colored_polygon(pts, color)


# --------------------------------------------------------------------- draw

func _draw() -> void:
	if pompon == null:
		return
	_c1 = pompon.color_primary
	_c2 = pompon.color_secondary
	if item_only_id != "":
		_draw_item_only()
		return
	var now := int(Time.get_unix_time_from_system())
	var stage := _stage()
	var u := minf(size.x / 330.0, size.y / 400.0)  # el personaje mide ~330 x 400 unidades de diseno
	var s: float = u * STAGE_SCALE[stage]
	var floor_pos := Vector2(size.x * 0.5, size.y - 6.0)

	# sombra suave
	draw_set_transform(floor_pos, 0.0, Vector2(u, u))
	_ell(Vector2(0, -2), 92.0 * STAGE_SCALE[stage], 14.0, Color(0.35, 0.2, 0.25, 0.18), false)

	if stage == 0:
		var pulse := pow(maxf(0.0, sin(_t * 1.1)), 12.0)
		var wobble := sin(_t * 15.0) * 0.12 * maxf(pulse, _bounce)
		draw_set_transform_matrix(Transform2D(wobble, Vector2(s, s), 0.0, floor_pos))
		_draw_egg()
	elif head_zoom > 0.0:  # primer plano para miniaturas
		var z := u * head_zoom
		draw_set_transform_matrix(Transform2D(0.0, Vector2(z, z), 0.0, Vector2(size.x * 0.5, size.y * 0.62)))
		_draw_character()
	else:
		var breathe := sin(_t * 2.4) * 0.03
		if _act_t > 0.0:
			breathe += sin(_t * 9.0) * 0.045  # cabeceo al comer, beber o banarse
		var sx: float = s * (1.0 + breathe) * facing
		var sy: float = s * (1.0 - breathe)
		var hop := absf(sin(_walk)) * 7.0 * u if walking else 0.0
		var lift := sin(_bounce * PI) * 34.0 * u + hop
		var origin := floor_pos - Vector2(0.0, sy * FLOOR_Y + lift)
		var base_xf := Transform2D(0.0, Vector2(sx, sy), 0.0, origin)
		if lean != 0.0:
			base_xf = Transform2D(lean * facing, floor_pos) * Transform2D(0.0, -floor_pos) * base_xf
		if _is_munching():
			# baja la cabecita hacia el tazon y mastica / lame con un balanceo suave
			var dip := minf(clampf((ACT_SECONDS - _act_t) / 0.35, 0.0, 1.0), clampf(_act_t / 0.35, 0.0, 1.0))
			var chew := sin(_t * 11.0) * 0.05 * dip
			var squash := 1.0 - 0.12 * dip * (0.65 + 0.35 * absf(sin(_t * 5.5)))
			var pivot := Transform2D(0.0, floor_pos) * Transform2D(chew, Vector2.ZERO) * Transform2D(0.0, -floor_pos)
			var sq := Transform2D(0.0, Vector2(1.0, squash), 0.0, Vector2(0.0, floor_pos.y * (1.0 - squash)))
			draw_set_transform_matrix(pivot * sq * base_xf)
			_draw_character()
			draw_set_transform_matrix(base_xf)
		else:
			draw_set_transform_matrix(base_xf)
			if sleep_props != "":
				_draw_pillow()
			_draw_character()
		if sleep_props != "":
			draw_set_transform_matrix(base_xf)
			_draw_blanket()
		_base_xf = base_xf
		_draw_activity()
		for h in _hearts:
			_heart(h["p"], 0.9, Color(1.0, 0.4, 0.55, clampf(1.2 - h["age"], 0.0, 1.0)))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if sleeping and stage > 0:
		_draw_zzz()


## Solo la prenda (gorro, lentes o ropa), centrada y ajustada al tamano de la miniatura.
func _draw_item_only() -> void:
	var cat: String = Catalog.get_item(item_only_id).get("category", "")
	var center := Vector2.ZERO   # donde esta la prenda en coordenadas de diseno
	var span := 200.0            # ancho aproximado que ocupa
	match cat:
		"hat":
			var fit: Array = HAT_FIT.get(item_only_id, [Vector2(0, -104), 220.0])
			center = fit[0]
			span = fit[1]
		"glasses":
			center = Vector2(0, -6)
			span = 178.0
		"shirt":
			center = Vector2(0, 116)
			span = 205.0
	var z := minf(size.x, size.y) * 0.86 / span
	draw_set_transform_matrix(Transform2D(0.0, Vector2(z, z), 0.0, size * 0.5 - center * z))
	match cat:
		"hat":
			_draw_hat(item_only_id, 96.0)
		"glasses":
			_draw_glasses(item_only_id)
		"shirt":
			_draw_shirt_sleeves(item_only_id)
			_draw_shirt(item_only_id)
			if item_only_id in ["shirt_red", "shirt_sweater", "shirt_green", "shirt_pajama"]:
				_ell(Vector2(0, 66), 28.0, 11.0, Color("fff8ea"))  # cuello
	draw_set_transform_matrix(Transform2D.IDENTITY)


## Mangas para que la prenda suelta se lea como ropa (en el Pompon las cubren sus brazos).
func _draw_shirt_sleeves(id: String) -> void:
	var col := Catalog.color_of(id)
	match id:
		"shirt_tutu":
			return
		"shirt_overalls", "shirt_scarf":
			col = Color("fff3e0")
		"shirt_dress":
			col = col.lightened(0.1)
	_ell(Vector2(-82, 98), 17.0, 30.0, col, true, 0.5)
	_ell(Vector2(82, 98), 17.0, 30.0, col, true, -0.5)


func _draw_egg() -> void:
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		var x := cos(a) * 62.0
		var y := sin(a) * 82.0
		if y < 0.0:
			x *= 1.0 - 0.18 * (-y / 82.0)
		pts.append(Vector2(x, y - 84.0))
	var base := _c2.lerp(_c1, 0.3)
	draw_colored_polygon(pts, base)
	for pos in [Vector2(-25, -120), Vector2(22, -100), Vector2(-8, -150), Vector2(30, -140)]:
		draw_circle(pos, 9.0, _c1)
	var zig := []
	for i in 9:
		zig.append(Vector2(-52.0 + i * 13.0, -62.0 + (8.0 if i % 2 == 0 else -8.0)))
	draw_polyline(PackedVector2Array(zig), _c1, 7.0, true)
	draw_circle(Vector2(-26, -140), 9.0, Color(1, 1, 1, 0.55))
	pts.append(pts[0])
	draw_polyline(pts, OUTLINE, 5.0, true)
	# rajaduras: cada toque (o golpecito de adentro) abre una mas
	var cracks := [
		[Vector2(-8, -166), Vector2(-2, -150), Vector2(-12, -138), Vector2(-4, -124)],
		[Vector2(56, -110), Vector2(42, -104), Vector2(46, -92), Vector2(30, -86), Vector2(34, -74)],
		[Vector2(-58, -96), Vector2(-44, -92), Vector2(-48, -80), Vector2(-32, -74)],
	]
	for i in mini(egg_cracks, cracks.size()):
		draw_polyline(PackedVector2Array(cracks[i]), OUTLINE, 4.0, true)


func _draw_character() -> void:
	var sp := pompon.species
	var c1 := _c1
	var c2 := _c2
	var dark := c1.darkened(0.2)
	var hrx := 100.0
	var hry := 96.0
	match pompon.face:
		"ovalada":
			hrx = 90.0
			hry = 104.0
		"ancha":
			hrx = 110.0
			hry = 90.0

	# --- detras del cuerpo: colas y alas
	match sp:
		"Felino":
			_tube(_bezier(Vector2(55, 140), Vector2(155, 150), Vector2(132, 55)), 22.0, c1)
		"Canino":
			_ell(Vector2(88, 128), 17.0, 30.0, dark, true, -0.7)
		"Conejo":
			_ell(Vector2(-78, 140), 24.0, 24.0, CREAM)
		"Raton":
			_tube(_bezier(Vector2(60, 150), Vector2(150, 160), Vector2(140, 100)), 8.0, PINK)
		"Dragon":
			var wing := [Vector2(52, 62), Vector2(160, -8), Vector2(142, 66), Vector2(166, 98), Vector2(112, 112), Vector2(62, 120)]
			_poly(wing, c2.darkened(0.05))
			_poly(_mirror(wing), c2.darkened(0.05))
			_tube(_bezier(Vector2(55, 148), Vector2(150, 160), Vector2(150, 105)), 24.0, c1)
			for p in [Vector2(120, 140), Vector2(143, 124), Vector2(150, 100)]:
				_poly([p + Vector2(-8, -6), p + Vector2(4, -26), p + Vector2(12, -2)], CREAM, true, 3.0)
		"Reptil":
			_tube(_bezier(Vector2(50, 150), Vector2(160, 168), Vector2(165, 118)), 28.0, c1)
		"Ave":
			_poly([Vector2(-50, 150), Vector2(-92, 168), Vector2(-60, 130)], dark, true, 4.0)

	# --- pies, cuerpo y brazos
	var foot := Color("f4a261") if sp == "Ave" else dark
	var step := sin(_walk) if walking else 0.0
	_ell(Vector2(-36, 166 - maxf(0.0, step) * 14.0), 30.0, 13.0, foot)
	_ell(Vector2(36, 166 - maxf(0.0, -step) * 14.0), 30.0, 13.0, foot)
	_ell(Vector2(0, 100), 72.0, 68.0, c1)
	_ell(Vector2(0, 113), 46.0, 44.0, c2, false)
	if sp == "Ave":
		_ell(Vector2(-78, 108), 20.0, 38.0, dark, true, 0.3)
		_ell(Vector2(78, 108), 20.0, 38.0, dark, true, -0.3)
	else:
		_ell(Vector2(-77, 106), 17.0, 28.0, c1, true, 0.35)
		_ell(Vector2(77, 106), 17.0, 28.0, c1, true, -0.35)
	if sp == "Reptil" or sp == "Dragon":
		for p in [Vector2(-40, 90), Vector2(44, 84), Vector2(-52, 128)]:
			draw_circle(p, 7.0, c2.darkened(0.08))

	if equipped.has("shirt"):
		_draw_shirt(equipped["shirt"])

	# --- orejas, cuernos y crestas (detras de la cabeza)
	match sp:
		"Canino":
			_ell(Vector2(-93, -22), 30.0, 54.0, c1.darkened(0.3), true, 0.45)
			_ell(Vector2(93, -22), 30.0, 54.0, c1.darkened(0.3), true, -0.45)
		"Felino":
			var ear := [Vector2(-88, -50), Vector2(-76, -128), Vector2(-24, -86)]
			_poly(ear, c1)
			_poly(_mirror(ear), c1)
			_poly([Vector2(-78, -62), Vector2(-72, -108), Vector2(-44, -84)], PINK, false)
			_poly(_mirror([Vector2(-78, -62), Vector2(-72, -108), Vector2(-44, -84)]), PINK, false)
		"Conejo":
			_ell(Vector2(-46, -140), 27.0, 72.0, c1, true, -0.12)
			_ell(Vector2(46, -140), 27.0, 72.0, c1, true, 0.12)
			_ell(Vector2(-46, -136), 13.0, 52.0, PINK, false, -0.12)
			_ell(Vector2(46, -136), 13.0, 52.0, PINK, false, 0.12)
		"Raton":
			_ell(Vector2(-80, -72), 42.0, 42.0, c1)
			_ell(Vector2(80, -72), 42.0, 42.0, c1)
			_ell(Vector2(-80, -72), 25.0, 25.0, PINK, false)
			_ell(Vector2(80, -72), 25.0, 25.0, PINK, false)
		"Ave":
			_ell(Vector2(0, -hry - 6.0), 10.0, 24.0, dark, true, 0.0, 4.0)
			_ell(Vector2(-15, -hry - 3.0), 10.0, 22.0, dark, true, -0.55, 4.0)
			_ell(Vector2(15, -hry - 3.0), 10.0, 22.0, dark, true, 0.55, 4.0)
		"Dragon":
			var horn := [Vector2(-52, -78), Vector2(-70, -146), Vector2(-20, -94)]
			_poly(horn, CREAM)
			_poly(_mirror(horn), CREAM)
			var fin := [Vector2(-88, -22), Vector2(-146, -44), Vector2(-124, 8)]
			_poly(fin, c2.darkened(0.05))
			_poly(_mirror(fin), c2.darkened(0.05))
		"Reptil":
			for x in [-42.0, 0.0, 42.0]:
				_ell(Vector2(x, -hry - 2.0 + absf(x) * 0.25), 15.0, 17.0, c2.darkened(0.1))

	# --- cabeza
	_ell(Vector2(0, 0), hrx, hry, c1, true, 0.0, 5.5)
	if sp != "Ave":
		_ell(Vector2(0, 38), 50.0, 33.0, c2, false)
	else:
		_ell(Vector2(0, 40), 58.0, 34.0, c2, false)

	_draw_face(hry)

	# --- sombrero y lentes
	if equipped.has("glasses"):
		_draw_glasses(equipped["glasses"])
	if equipped.has("hat"):
		_draw_hat(equipped["hat"], hry)


## Media elipse superior (cupulas de sombreros).
func _dome(cx: float, base_y: float, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		pts.append(Vector2(cx + cos(a) * rx, base_y + sin(a) * ry))
	return pts


## Efectos de comer, beber y banarse (plato, migas, gotas, burbujas).
func _draw_activity() -> void:
	if _act_t <= 0.0:
		return
	var k := 1.0 - _act_t / ACT_SECONDS
	var fade := clampf(_act_t / 0.5, 0.0, 1.0)
	match _act:
		"eat", "drink":
			_draw_bowl(_act == "eat", k)
		"bath":
			for i in 9:
				var p2 := Vector2(-96.0 + float((i * 47) % 190), 150.0 - fmod(k * 220.0 + i * 33.0, 270.0))
				var r := 8.0 + float(i % 3) * 5.0
				draw_circle(p2, r, Color(1, 1, 1, 0.55 * fade))
				draw_arc(p2, r, 0.0, TAU, 16, Color("8ecae6", fade), 2.5, true)
			for p3 in [Vector2(-36, -92), Vector2(0, -108), Vector2(36, -92), Vector2(-14, -82), Vector2(18, -84)]:
				draw_circle(p3, 22.0, Color(1, 1, 1, fade))
				draw_arc(p3, 22.0, 0.0, TAU, 18, Color("bfe0f5", fade), 2.5, true)


func _is_munching() -> bool:
	return _act_t > 0.0 and (_act == "eat" or _act == "drink")


## Tazon de comida o de agua (el de siempre es feo: ¡hay que comprar unos lindos en la tienda!).
## `k` = avance (0..1): la comida se va acabando y el agua va bajando.
func _draw_bowl(food: bool, k: float) -> void:
	var appear := clampf((ACT_SECONDS - _act_t) / 0.3, 0.0, 1.0)
	var leave := clampf(_act_t / 0.3, 0.0, 1.0)
	var pop := (1.0 + 0.2 * sin(appear * PI)) * minf(appear, leave)
	if pop <= 0.02:
		return
	draw_set_transform_matrix(_base_xf * Transform2D(0.0, Vector2(pop, pop), 0.0, Vector2(0, 172)))
	BowlArt.draw_bowl(self, str(equipped.get("bowl_food" if food else "bowl_water", "")), food, k, _t)
	draw_set_transform_matrix(_base_xf)


func _is_sad() -> bool:
	var worst := 100.0
	for s in ["alimentacion", "hidratacion", "aseo", "diversion"]:
		worst = minf(worst, pompon.stats.get(s, 100.0))
	return worst < 25.0


## Boca al comer (se abre y se cierra) o al beber (la lengüita lame).
func _draw_munch(my: float) -> void:
	if _act == "drink":
		var ext := absf(sin(_t * 8.0))
		draw_arc(Vector2(0, my - 4), 15.0, 0.12 * PI, 0.88 * PI, 14, OUTLINE, 4.0, true)
		_ell(Vector2(0, my + 8.0 + ext * 9.0), 7.5, 5.0 + ext * 7.0, Color("ff8fa3"), true, 0.0, 3.0)
	else:
		var open := 0.25 + 0.75 * absf(sin(_t * 10.0))
		_ell(Vector2(0, my + 4.0), 13.0, 4.0 + 12.0 * open, EYE_DARK, false)
		if open > 0.5:
			_ell(Vector2(0, my + 4.0 + 7.0 * open), 8.0, 4.0 * open, Color("ff8fa3"), false)


## Cuanto tiene abiertos los ojos (1 abiertos, 0 cerrados). Siempre estan abiertos y cada ~4 s
## parpadea: se van cerrando y se vuelven a abrir; cada tanto hace un doble parpadeo.
func _eye_open() -> float:
	if not animated:
		return 1.0   # miniaturas: siempre con los ojos abiertos
	var cycle := fmod(_t + 1.3, 4.3)
	var k := -1.0
	if cycle >= 4.0:
		k = (cycle - 4.0) / 0.3
	elif int((_t + 1.3) / 4.3) % 3 == 0 and cycle >= 3.55 and cycle < 3.85:
		k = (cycle - 3.55) / 0.3
	return 1.0 if k < 0.0 else absf(1.0 - 2.0 * k)


## Un ojo segun su forma, aplastado hacia arriba y abajo cuando se cierra (`open`).
func _draw_eye(c: Vector2, sx: float, open: float) -> void:
	var shine := open > 0.55
	match pompon.eyes:
		"ovalados":
			_ell(c, 11.0, 17.0 * open, EYE_DARK, false)
			if shine:
				draw_circle(c + Vector2(3, -6 * open), 4.5, Color.WHITE)
		"brillantes":
			_ell(c, 17.0, 19.0 * open, EYE_DARK, false)
			if shine:
				draw_circle(c + Vector2(5, -7 * open), 7.0, Color.WHITE)
				draw_circle(c + Vector2(-5, 6 * open), 3.5, Color.WHITE)
		"tiernos":  # grandes, con mucho brillo y dos pestañitas hacia afuera
			_ell(c, 15.0, 16.0 * open, EYE_DARK, false)
			if shine:
				draw_circle(c + Vector2(4, -6 * open), 6.0, Color.WHITE)
				draw_circle(c + Vector2(-5, 5 * open), 3.0, Color.WHITE)
				draw_line(c + Vector2(12.0 * sx, -10.0 * open), c + Vector2(20.0 * sx, -17.0 * open), EYE_DARK, 4.0, true)
				draw_line(c + Vector2(6.0 * sx, -14.0 * open), c + Vector2(10.0 * sx, -22.0 * open), EYE_DARK, 4.0, true)
		_:
			_ell(c, 13.0, 13.0 * open, EYE_DARK, false)
			if shine:
				draw_circle(c + Vector2(4, -5 * open), 4.5, Color.WHITE)
				draw_circle(c + Vector2(-4, 4 * open), 2.0, Color.WHITE)


func _draw_face(hry: float) -> void:
	var sp := pompon.species
	var open := _eye_open()
	var munch := _is_munching()
	var eye_y := -6.0
	var sad := _is_sad()

	# mejillas
	_ell(Vector2(-68, 30), 16.0, 10.0, BLUSH, false)
	_ell(Vector2(68, 30), 16.0, 10.0, BLUSH, false)
	if face_mood == "shy":  # se pone colorado: rubor mas fuerte con rayitas
		for bx in [-68.0, 68.0]:
			_ell(Vector2(bx, 30), 22.0, 13.0, Color(1.0, 0.45, 0.55, 0.45), false)
			for k in 3:
				draw_line(Vector2(bx - 12.0 + k * 9.0, 36), Vector2(bx - 6.0 + k * 9.0, 24), Color(0.85, 0.3, 0.4, 0.7), 3.0, true)

	# ojos
	for sx in [-1.0, 1.0]:
		var c := Vector2(38.0 * sx, eye_y)
		if sleeping:  # dormido: ojitos cerrados y tranquilos
			draw_arc(c + Vector2(0, -2), 13.0, 0.18 * PI, 0.82 * PI, 12, EYE_DARK, 4.5, true)
			continue
		if munch or face_mood == "happy":  # ojitos cerrados de gusto
			draw_arc(c + Vector2(0, 4), 14.0, 1.15 * PI, 1.85 * PI, 12, EYE_DARK, 5.0, true)
			continue
		if face_mood == "shy":  # mira para abajo, de costado
			_ell(c + Vector2(5.0, 8.0), 7.0, 8.0, EYE_DARK, false)
			draw_arc(c + Vector2(0, -4), 15.0, 1.2 * PI, 1.8 * PI, 10, EYE_DARK, 3.0, true)
			continue
		if open < 0.2:  # en medio del parpadeo: ojito cerrado
			draw_arc(c + Vector2(0, -2), 14.0, 0.15 * PI, 0.85 * PI, 12, EYE_DARK, 5.0, true)
			continue
		_draw_eye(c, sx, open)
		if sad:
			draw_line(c + Vector2(-14 * sx, -26), c + Vector2(10 * sx, -20), EYE_DARK, 4.0, true)

	# nariz / pico
	match sp:
		"Ave":
			_poly([Vector2(-15, 12), Vector2(15, 12), Vector2(0, 36)], Color("ffa94d"), true, 4.0)
		"Canino":
			_ell(Vector2(0, 14), 11.0, 8.0, EYE_DARK, false)
		"Felino", "Conejo", "Raton":
			_ell(Vector2(0, 14), 8.0, 6.0, Color("e07a8f"), false)
		"Dragon", "Reptil":
			draw_circle(Vector2(-10, 14), 3.0, OUTLINE)
			draw_circle(Vector2(10, 14), 3.0, OUTLINE)

	# boca (el ave ya tiene pico)
	if sp != "Ave":
		var my := 30.0
		if munch:
			_draw_munch(my)
		elif sad:
			draw_arc(Vector2(0, my + 14), 13.0, 1.15 * PI, 1.85 * PI, 14, OUTLINE, 4.0, true)
		else:
			match pompon.mouth:
				"pico":  # boquita en "w"
					draw_arc(Vector2(-8, my), 8.0, 0.1 * PI, 0.9 * PI, 10, OUTLINE, 4.0, true)
					draw_arc(Vector2(8, my), 8.0, 0.1 * PI, 0.9 * PI, 10, OUTLINE, 4.0, true)
				"colmillitos":
					draw_arc(Vector2(0, my - 4), 15.0, 0.12 * PI, 0.88 * PI, 14, OUTLINE, 4.0, true)
					_poly([Vector2(-11, my + 8), Vector2(-5, my + 8), Vector2(-8, my + 18)], Color.WHITE, true, 2.5)
					_poly([Vector2(5, my + 8), Vector2(11, my + 8), Vector2(8, my + 18)], Color.WHITE, true, 2.5)
				_:
					draw_arc(Vector2(0, my - 4), 15.0, 0.12 * PI, 0.88 * PI, 14, OUTLINE, 4.0, true)
					if pompon.mouth == "bigotes":
						for dy in [-8.0, 2.0, 12.0]:
							draw_line(Vector2(60, my + dy), Vector2(104, my + dy * 1.7 - 6.0), OUTLINE, 3.0, true)
							draw_line(Vector2(-60, my + dy), Vector2(-104, my + dy * 1.7 - 6.0), OUTLINE, 3.0, true)
	if sp == "Felino" and pompon.mouth != "bigotes":
		for dy in [-6.0, 6.0]:
			draw_line(Vector2(64, 30 + dy), Vector2(106, 22 + dy * 1.6), OUTLINE, 3.0, true)
			draw_line(Vector2(-64, 30 + dy), Vector2(-106, 22 + dy * 1.6), OUTLINE, 3.0, true)


# -------------------------------------------------------------------- ropa

func _item_color(id: String) -> Color:
	return Catalog.color_of(id)


func _draw_shirt(id: String) -> void:
	var col := _item_color(id)
	match id:
		"shirt_star":
			_ell(Vector2(0, 112), 68.0, 56.0, col)
			_ell(Vector2(0, 76), 46.0, 15.0, col.lightened(0.25))
			_poly(_star(Vector2(0, 120), 32.0), Color("ffe27a"), true, 3.5)
		"shirt_cape":
			_poly([Vector2(-60, 74), Vector2(-26, 84), Vector2(-40, 172), Vector2(-104, 168)], col)
			_poly([Vector2(60, 74), Vector2(26, 84), Vector2(40, 172), Vector2(104, 168)], col)
			_ell(Vector2(0, 76), 50.0, 15.0, col.darkened(0.12))
			_ell(Vector2(0, 86), 9.0, 9.0, Color("ffd33d"))
		"shirt_sailor":
			_ell(Vector2(0, 112), 68.0, 56.0, Color("fff8ea"))
			for y in [104.0, 128.0, 152.0]:
				draw_line(Vector2(-58, y), Vector2(58, y), col, 7.0, true)
			_poly([Vector2(-36, 74), Vector2(36, 74), Vector2(0, 126)], col)
			_poly([Vector2(-14, 112), Vector2(14, 112), Vector2(0, 128)], Color("e5484d"), false)
		"shirt_tux":
			_ell(Vector2(0, 112), 68.0, 56.0, col)
			_poly([Vector2(-26, 76), Vector2(26, 76), Vector2(0, 152)], Color.WHITE)
			_poly([Vector2(-16, 92), Vector2(16, 92), Vector2(10, 106), Vector2(-10, 106)], Color("e5484d"), true, 3.0)
			for i in 3:
				draw_circle(Vector2(0, 116.0 + i * 14.0), 3.2, col)
		"shirt_dress":
			_poly([Vector2(-44, 82), Vector2(44, 82), Vector2(84, 164), Vector2(-84, 164)], col)
			for i in 7:
				draw_circle(Vector2(-72.0 + i * 24.0, 164), 13.0, Color.WHITE)
			_ell(Vector2(0, 86), 46.0, 14.0, col.lightened(0.15))
		"shirt_hoodie":
			_ell(Vector2(0, 112), 68.0, 56.0, col)
			_ell(Vector2(0, 74), 54.0, 17.0, col.darkened(0.15))
			draw_line(Vector2(-14, 78), Vector2(-16, 108), Color.WHITE, 4.0, true)
			draw_line(Vector2(14, 78), Vector2(16, 108), Color.WHITE, 4.0, true)
			_poly([Vector2(-34, 132), Vector2(34, 132), Vector2(40, 156), Vector2(-40, 156)], col.darkened(0.15), true, 3.0)
		"shirt_sweater":
			_ell(Vector2(0, 112), 68.0, 56.0, col)
			for y in [102.0, 124.0, 146.0]:
				draw_line(Vector2(-54, y), Vector2(54, y), Color(1, 1, 1, 0.65), 6.0, true)
			_ell(Vector2(0, 76), 48.0, 15.0, col.lightened(0.25))
		"shirt_green":
			_ell(Vector2(0, 112), 68.0, 56.0, col)
			draw_line(Vector2(0, 80), Vector2(0, 166), col.darkened(0.35), 4.0, true)
			for i in 5:
				draw_circle(Vector2(0, 92.0 + i * 16.0), 3.0, Color.WHITE)
		"shirt_overalls":
			_ell(Vector2(0, 108), 68.0, 58.0, Color("fff3e0"))
			_ell(Vector2(0, 128), 64.0, 40.0, col)
			_poly([Vector2(-34, 96), Vector2(34, 96), Vector2(38, 134), Vector2(-38, 134)], col.darkened(0.05), true, 4.0)
			draw_line(Vector2(-28, 74), Vector2(-26, 98), col.darkened(0.15), 10.0, true)
			draw_line(Vector2(28, 74), Vector2(26, 98), col.darkened(0.15), 10.0, true)
			draw_circle(Vector2(-26, 102), 5.0, Color("ffd33d"))
			draw_circle(Vector2(26, 102), 5.0, Color("ffd33d"))
		"shirt_pajama":
			_ell(Vector2(0, 112), 68.0, 56.0, col)
			for p in [Vector2(-28, 104), Vector2(24, 124), Vector2(-6, 144), Vector2(30, 98)]:
				_poly(_star(p, 9.0), Color("fff3b0"), false)
			_ell(Vector2(0, 76), 40.0, 12.0, col.lightened(0.3))
		"shirt_raincoat":
			_ell(Vector2(0, 112), 68.0, 56.0, col)
			_ell(Vector2(0, 74), 56.0, 17.0, col.darkened(0.12))
			draw_line(Vector2(0, 84), Vector2(0, 166), col.darkened(0.3), 3.0, true)
			for i in 3:
				draw_circle(Vector2(10, 100.0 + i * 22.0), 5.0, Color("5b3a4a"))
			draw_line(Vector2(-14, 78), Vector2(-16, 100), Color("5b3a4a"), 3.0, true)
		"shirt_tutu":
			_ell(Vector2(0, 100), 46.0, 28.0, Color("fff3f8"))
			for i in 3:
				_ell(Vector2(0, 134.0 + i * 11.0), 82.0 - i * 6.0, 20.0, col.lightened(0.12 * i))
			_ell(Vector2(0, 124), 48.0, 8.0, col.darkened(0.15), false)
		"shirt_scarf":
			_ell(Vector2(0, 112), 68.0, 56.0, Color("fff3e0"))
			var bands := [Color("f28c6b"), Color("ffd166"), Color("6bbf7a"), Color("8ecae6")]
			_ell(Vector2(0, 78), 54.0, 17.0, bands[0])
			for i in 4:
				draw_line(Vector2(-40.0 + i * 26.0, 72), Vector2(-36.0 + i * 26.0, 90), bands[(i + 1) % 4], 8.0, true)
			_poly([Vector2(20, 84), Vector2(46, 84), Vector2(52, 140), Vector2(26, 144)], bands[0])
			for i in 3:
				draw_line(Vector2(28.0 + i * 3.0, 104.0 + i * 12.0), Vector2(50.0 + i * 2.0, 100.0 + i * 12.0), bands[(i + 1) % 4], 6.0, true)
		_:  # remera roja y cualquier otra
			_ell(Vector2(0, 112), 68.0, 56.0, col)
			_poly(_star(Vector2(0, 118), 18.0), Color("ffd33d"), true, 3.0)


func _draw_hat(id: String, hry: float) -> void:
	var col := _item_color(id)
	var top := -hry
	match id:
		"hat_beret":
			_ell(Vector2(-12, top + 14.0), 86.0, 34.0, col)
			_ell(Vector2(-12, top + 30.0), 76.0, 12.0, col.darkened(0.15), false)
			draw_line(Vector2(-12, top - 18.0), Vector2(-5, top - 34.0), col.darkened(0.3), 6.0, true)
		"hat_ears":
			draw_arc(Vector2(0, top + 64.0), 88.0, PI + 0.3, TAU - 0.3, 24, OUTLINE, 15.0, true)
			draw_arc(Vector2(0, top + 64.0), 88.0, PI + 0.3, TAU - 0.3, 24, col, 9.0, true)
			for sx in [-1.0, 1.0]:
				_poly([Vector2(sx * 76.0, top + 24.0), Vector2(sx * 80.0, top - 34.0), Vector2(sx * 30.0, top + 10.0)], col)
				_poly([Vector2(sx * 68.0, top + 14.0), Vector2(sx * 70.0, top - 16.0), Vector2(sx * 44.0, top + 6.0)], Color("ffb3c1"), false)
		"hat_witch":
			_ell(Vector2(0, top + 30.0), 120.0, 20.0, col.darkened(0.1))
			_poly([Vector2(-54, top + 28), Vector2(54, top + 28), Vector2(16, top - 86), Vector2(-4, top - 104)], col)
			_poly([Vector2(-52, top + 20), Vector2(52, top + 20), Vector2(48, top + 2), Vector2(-48, top + 2)], Color("ff8fb1"), true, 3.5)
			_poly([Vector2(-10, top + 18), Vector2(10, top + 18), Vector2(10, top + 4), Vector2(-10, top + 4)], Color("ffd33d"), true, 3.0)
			_poly(_star(Vector2(24, top - 40.0), 9.0), Color("ffd33d"), false)
		"hat_halo":
			var ring := PackedVector2Array()
			for i in 33:
				var a := TAU * i / 32.0
				ring.append(Vector2(cos(a) * 58.0, top - 34.0 + sin(a) * 14.0))
			draw_polyline(ring, Color(1.0, 0.9, 0.5, 0.35), 24.0, true)
			draw_polyline(ring, OUTLINE, 15.0, true)
			draw_polyline(ring, Color("ffe27a"), 9.0, true)
		"hat_beanie":
			var dome := PackedVector2Array()
			for i in 21:
				var a := PI + PI * i / 20.0
				dome.append(Vector2(cos(a) * 92.0, top + 24.0 + sin(a) * 66.0))
			_poly(Array(dome), col)
			_ell(Vector2(0, top + 26.0), 96.0, 16.0, col.lightened(0.25))
			for x in [-40.0, 0.0, 40.0]:
				draw_line(Vector2(x, top - 30.0 + absf(x) * 0.35), Vector2(x * 1.05, top + 12.0), col.darkened(0.15), 4.0, true)
			_ell(Vector2(0, top - 44.0), 20.0, 20.0, col.lightened(0.4))
		"hat_cap":
			var dome2 := PackedVector2Array()
			for i in 21:
				var a2 := PI + PI * i / 20.0
				dome2.append(Vector2(cos(a2) * 86.0, top + 28.0 + sin(a2) * 54.0))
			_poly(Array(dome2), col)
			_ell(Vector2(34, top + 30.0), 78.0, 13.0, col.darkened(0.2))
			draw_circle(Vector2(0, top - 24.0), 7.0, col.lightened(0.3))
		"hat_bow":
			var p := Vector2(-58.0, top + 22.0)
			_poly([p, p + Vector2(-38, -26), p + Vector2(-38, 26)], col)
			_poly([p, p + Vector2(38, -26), p + Vector2(38, 26)], col)
			_ell(p, 12.0, 12.0, col.darkened(0.15))
		"hat_party":
			_poly([Vector2(-40, top + 30), Vector2(40, top + 30), Vector2(4, top - 78)], col)
			for i in 3:
				var yy := top + 18.0 - i * 26.0
				draw_line(Vector2(-30.0 + i * 11.0, yy), Vector2(30.0 - i * 11.0, yy - 8.0), Color(1, 1, 1, 0.8), 5.0, true)
			_ell(Vector2(4, top - 80), 12.0, 12.0, Color("ffd33d"))
		"hat_flower":
			var petals := [Color("ff9ecb"), Color("fff3b0"), Color("ffffff")]
			for i in 7:
				var a := PI + PI * (i + 0.5) / 7.0
				var fc := Vector2(cos(a) * 86.0, top + 36.0 + sin(a) * 62.0)
				_ell(fc + Vector2(8, 4), 10.0, 5.0, Color("6bbf7a"), false, 0.5)
				for k in 5:
					var pa := TAU * k / 5.0
					draw_circle(fc + Vector2(cos(pa), sin(pa)) * 9.0, 8.0, petals[i % 3])
				draw_circle(fc, 6.0, Color("ffd33d"))
		"hat_straw":
			_poly(Array(_dome(0.0, top + 30.0, 58.0, 42.0)), col)
			_ell(Vector2(0, top + 32.0), 122.0, 20.0, col.darkened(0.06))
			_ell(Vector2(0, top + 26.0), 60.0, 11.0, Color("ff7aa0"), false)
		"hat_chef":
			for p in [Vector2(-34, top - 6), Vector2(0, top - 26), Vector2(34, top - 6)]:
				_ell(p, 34.0, 34.0, col)
			_poly([Vector2(-54, top + 34), Vector2(54, top + 34), Vector2(54, top + 6), Vector2(-54, top + 6)], col)
		"hat_crown":
			var gold := Color("ffd33d")
			_poly([Vector2(-58, top + 26), Vector2(-62, top - 30), Vector2(-30, top - 4), Vector2(0, top - 44),
				Vector2(30, top - 4), Vector2(62, top - 30), Vector2(58, top + 26)], gold)
			for x in [-34.0, 0.0, 34.0]:
				draw_circle(Vector2(x, top + 8.0), 7.0, Color("ff6b8b"))


func _draw_glasses(id: String) -> void:
	var col := _item_color(id)
	match id:
		"glasses_pixel":
			for sx in [-1.0, 1.0]:
				var lens := Rect2(Vector2(38.0 * sx - 30.0, -22.0), Vector2(60, 34))
				draw_rect(lens, Color("1d1d2b"))
				draw_rect(lens, OUTLINE, false, 4.0)
				draw_rect(Rect2(lens.position + Vector2(6, 5), Vector2(14, 8)), Color(1, 1, 1, 0.75))
			draw_line(Vector2(-8, -12), Vector2(8, -12), OUTLINE, 6.0, true)
		"glasses_rainbow":
			var bands := [Color("ff5d5d"), Color("ffa94d"), Color("ffe066"), Color("7bd389"), Color("5bb8f5")]
			for sx in [-1.0, 1.0]:
				draw_circle(Vector2(38.0 * sx, -6.0), 27.0, Color(1, 1, 1, 0.3))
				for i in bands.size():
					draw_arc(Vector2(38.0 * sx, -6.0), 24.0 - i * 4.4, 0.0, TAU, 28, bands[i], 4.0, true)
				draw_arc(Vector2(38.0 * sx, -6.0), 27.0, 0.0, TAU, 32, OUTLINE, 4.0, true)
			draw_line(Vector2(-11, -8), Vector2(11, -8), OUTLINE, 5.0, true)
		"glasses_sun":
			for sx in [-1.0, 1.0]:
				_ell(Vector2(38.0 * sx, -4.0), 29.0, 22.0, Color("2b2b3a"), true, 0.0, 4.0)
				draw_line(Vector2(38.0 * sx - 14.0, -12.0), Vector2(38.0 * sx - 4.0, -16.0), Color(1, 1, 1, 0.5), 4.0, true)
			draw_line(Vector2(-10, -6), Vector2(10, -6), OUTLINE, 5.0, true)
		"glasses_heart":
			for sx in [-1.0, 1.0]:
				_heart(Vector2(38.0 * sx, -2.0), 1.75, OUTLINE)
				_heart(Vector2(38.0 * sx, -2.0), 1.4, Color(col.r, col.g, col.b, 0.75))
			draw_line(Vector2(-10, -8), Vector2(10, -8), OUTLINE, 5.0, true)
		"glasses_cat":
			var lens := [Vector2(-74, -26), Vector2(-14, -10), Vector2(-16, 12), Vector2(-44, 20), Vector2(-68, 6)]
			_poly(lens, Color(col.r, col.g, col.b, 0.5), true, 4.0)
			_poly(_mirror(lens), Color(col.r, col.g, col.b, 0.5), true, 4.0)
			draw_line(Vector2(-14, -8), Vector2(14, -8), OUTLINE, 5.0, true)
		"glasses_star":
			for sx in [-1.0, 1.0]:
				_poly(_star(Vector2(38.0 * sx, -4.0), 27.0), Color(col.r, col.g, col.b, 0.6), true, 4.0)
			draw_line(Vector2(-8, -6), Vector2(8, -6), OUTLINE, 5.0, true)
		_:
			for sx in [-1.0, 1.0]:
				draw_circle(Vector2(38.0 * sx, -6.0), 25.0, Color(1, 1, 1, 0.25))
				draw_arc(Vector2(38.0 * sx, -6.0), 25.0, 0.0, TAU, 32, col, 5.0, true)
			draw_line(Vector2(-13, -8), Vector2(13, -8), col, 5.0, true)
