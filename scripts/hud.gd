class_name Hud
extends RefCounted
## Piezas visuales de la interfaz de la casa: colores, estilos de tarjetas y botones, e iconos
## dibujados por codigo (se pintan en blanco sobre un circulo de color).

const INK := Color("5b3a4a")
const MUTED := Color("7d6070")   # texto apagado (bloqueado, todavia no, esperando) que igual se lee bien
const PINK := Color("ff8fb8")
const CARD := Color(1, 1, 1, 0.93)
const SHADOW := Color(0.36, 0.23, 0.29, 0.22)

const STAT_COLORS := {
	"alimentacion": Color("ffa94d"), "hidratacion": Color("5bb8f5"), "aseo": Color("3cc9b0"),
	"diversion": Color("ff7aa8"), "comodidad": Color("a98bea"), "felicidad": Color("ffcf3f"), "sueno": Color("7b8ce0"),
	"amor": Color("f2566f"), "amistad": Color("5fc77f"), "inteligencia": Color("6c7ff0"),
}
const STAT_ICONS := {
	"alimentacion": "apple", "hidratacion": "drop", "aseo": "bubbles", "diversion": "game",
	"comodidad": "house", "felicidad": "smile", "sueno": "moon", "amor": "heart", "amistad": "people", "inteligencia": "bulb",
}


static func card(bg := CARD, radius := 32, border := Color.WHITE, border_w := 3, shadow := 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 12.0
	sb.shadow_color = SHADOW
	sb.shadow_size = shadow
	sb.shadow_offset = Vector2(0, 4)
	return sb


## Estilo de boton "pildora" (por defecto rosa con borde blanco).
static func pill(bg := PINK, border := Color.WHITE, radius := 40, shadow := 6) -> StyleBoxFlat:
	var sb := card(bg, radius, border, 5, shadow)
	sb.shadow_color = Color(bg.darkened(0.35), 0.45)
	sb.shadow_offset = Vector2(0, 5)
	return sb


static func style_primary(b: Button, font_size := 34, bg := PINK) -> void:
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	b.add_theme_color_override("font_outline_color", bg.darkened(0.3))
	b.add_theme_constant_override("outline_size", 10)
	b.add_theme_stylebox_override("normal", pill(bg))
	b.add_theme_stylebox_override("hover", pill(bg.lightened(0.06)))
	b.add_theme_stylebox_override("pressed", pill(bg.darkened(0.08), Color.WHITE, 40, 0))
	b.add_theme_stylebox_override("disabled", pill(Color("e6d3dc"), Color("fffafc"), 40, 0))


static func style_soft(b: Button, font_size := 26) -> void:
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", pill(Color("fff1f6"), Color("ffc2d9"), 36, 3))
	b.add_theme_stylebox_override("hover", pill(Color("ffe4ee"), Color("ffb3d1"), 36, 3))
	b.add_theme_stylebox_override("pressed", pill(Color("ffd0e2"), Color("ffb3d1"), 36, 0))
	b.add_theme_stylebox_override("disabled", pill(Color("f3e8ee"), Color("e6d3dc"), 36, 0))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(state, INK)


## Boton redondo con una flechita para volver.
static func back_button(target: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(76, 76)
	b.focus_mode = Control.FOCUS_NONE
	var sb := card(Color(1, 1, 1, 0.95), 38, Color.WHITE, 3, 6)
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, sb)
	b.draw.connect(func():
		var c := b.size * 0.5
		b.draw_polyline(PackedVector2Array([c + Vector2(8, -18), c + Vector2(-10, 0), c + Vector2(8, 18)]), INK, 7.0, true))
	b.pressed.connect(target)
	return b


## Etiquetita de color con texto corto.
static func chip(text: String, bg: Color, fg: Color, font_size := 20) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := card(bg, 22, Color(bg.darkened(0.12), 0.6), 2, 0)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", fg)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	return p


## Moneda dorada chica (para "+40" y similares).
static func coin_icon(px := 32.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func(): draw_icon(c, "coin", c.size * 0.5, px, Color.WHITE))
	return c


## Monedas que salen de `from` (posicion en pantalla) y vuelan hasta `target` (el contador), que salta al recibirlas.
## Es solo el festejo: el numero ya se sumo antes.
static func fly_coins(host: Node, from: Vector2, target: Control, amount: int) -> void:
	if host == null or not is_instance_valid(target) or not host.is_inside_tree():
		return
	var n := clampi(amount / 5, 4, 9)
	var to := target.get_global_rect().get_center()
	for i in n:
		var coin := coin_icon(52.0)
		coin.top_level = true
		coin.size = Vector2(52, 52)
		coin.pivot_offset = Vector2(26, 26)
		coin.scale = Vector2.ZERO
		host.add_child(coin)
		var start := from + Vector2(randf_range(-60.0, 60.0), randf_range(-40.0, 30.0)) - coin.size * 0.5
		coin.global_position = from - coin.size * 0.5
		var last := i == n - 1
		var tw := coin.create_tween()
		tw.tween_interval(i * 0.06)
		tw.tween_property(coin, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(coin, "global_position", start, 0.18)
		tw.tween_interval(0.12)
		tw.tween_property(coin, "global_position", to - coin.size * 0.5, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(coin, "scale", Vector2(0.7, 0.7), 0.5)
		tw.tween_callback(func():
			var audio := coin.get_node_or_null("/root/Audio")   # (Hud es estatico: el autoload se busca por ruta)
			if audio != null and (i % 2 == 0 or last):
				audio.play("coin", 1.0 + 0.04 * i)
			if is_instance_valid(target):
				target.pivot_offset = target.size * 0.5
				var bump := target.create_tween()
				bump.tween_property(target, "scale", Vector2(1.12, 1.12), 0.07)
				bump.tween_property(target, "scale", Vector2.ONE, 0.12)
			coin.queue_free())


# --------------------------------------------------------------- iconos

static func _circle_pts(c: Vector2, rx: float, ry: float, rot := 0.0, n := 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2(cos(a) * rx, sin(a) * ry).rotated(rot) + c)
	return pts


## Forma de luna: el circulo de afuera (o, big_r) menos el de adentro (i, r).
static func _crescent(o: Vector2, big_r: float, i: Vector2, r: float) -> PackedVector2Array:
	var d := o.distance_to(i)
	var u := (i - o) / d
	var a := (big_r * big_r - r * r + d * d) / (2.0 * d)
	var h := sqrt(maxf(big_r * big_r - a * a, 0.0))
	var m := o + u * a
	var perp := Vector2(-u.y, u.x)
	var p1 := m + perp * h
	var p2 := m - perp * h
	var pts := PackedVector2Array()
	# borde de afuera: de p1 a p2 por el lado contrario al circulo de adentro
	var a1 := (p1 - o).angle()
	var span := wrapf((p2 - o).angle() - a1, 0.0, TAU)
	if absf(angle_difference(a1 + span * 0.5, u.angle())) < PI * 0.5:
		span -= TAU
	for k in 17:
		pts.append(o + Vector2.from_angle(a1 + span * k / 16.0) * big_r)
	# borde de adentro: de p2 a p1 por dentro del circulo grande
	var b1 := (p2 - i).angle()
	var span2 := wrapf((p1 - i).angle() - b1, 0.0, TAU)
	if absf(angle_difference(b1 + span2 * 0.5, (o - i).angle())) > PI * 0.5:
		span2 -= TAU
	# (sin repetir p2 y p1, que ya estan en el borde de afuera: puntos repetidos rompen la triangulacion)
	for k in range(1, 16):
		pts.append(i + Vector2.from_angle(b1 + span2 * k / 16.0) * r)
	return pts


static func _rrect(cv: CanvasItem, r: Rect2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var corners := [[r.position + Vector2(rad, rad), PI], [r.position + Vector2(r.size.x - rad, rad), PI * 1.5],
		[r.end - Vector2(rad, rad), 0.0], [r.position + Vector2(rad, r.size.y - rad), PI * 0.5]]
	for cn in corners:
		for i in 7:
			var a: float = float(cn[1]) + (PI * 0.5) * float(i) / 6.0
			pts.append(Vector2(cn[0]) + Vector2(cos(a), sin(a)) * rad)
	cv.draw_colored_polygon(pts, col)


## Dibuja un icono centrado en `c` dentro de una caja de lado `s`. `col` = trazo/relleno; `bg` = "huecos".
## Carita redonda de como se sintio (diario): "happy", "sad", "sleep" o "wow". `r` = radio.
static func draw_face(cv: CanvasItem, mood: String, c: Vector2, r: float) -> void:
	var fill: Color = {"happy": Color("ffd34d"), "sad": Color("9ccbf2"), "sleep": Color("c9b8f2"), "wow": Color("ffa8c8")}.get(mood, Color("ffd34d"))
	var ink := Color("5b3a4a")
	var w := maxf(2.0, r * 0.14)
	cv.draw_circle(c, r + w, Color.WHITE)
	cv.draw_circle(c, r, fill)
	var eye_y := -0.18 * r
	match mood:
		"sleep":   # ojitos cerrados y una z
			for sx in [-1.0, 1.0]:
				cv.draw_arc(c + Vector2(sx * 0.36 * r, eye_y), 0.16 * r, 0.2, PI - 0.2, 8, ink, w, true)
			cv.draw_circle(c + Vector2(0, 0.38 * r), 0.1 * r, ink)
		"wow":     # ojos grandes y boca en O
			for sx in [-1.0, 1.0]:
				cv.draw_circle(c + Vector2(sx * 0.34 * r, eye_y), 0.13 * r, ink)
			cv.draw_arc(c + Vector2(0, 0.36 * r), 0.17 * r, 0.0, TAU, 14, ink, w, true)
		"sad":     # cejas caidas, boca hacia abajo y una lagrimita
			for sx in [-1.0, 1.0]:
				cv.draw_circle(c + Vector2(sx * 0.34 * r, eye_y), 0.1 * r, ink)
			cv.draw_arc(c + Vector2(0, 0.58 * r), 0.3 * r, PI + 0.5, TAU - 0.5, 10, ink, w, true)
			cv.draw_circle(c + Vector2(0.36 * r, 0.12 * r), 0.11 * r, Color("3d8fcc"))
		_:         # contento
			for sx in [-1.0, 1.0]:
				cv.draw_circle(c + Vector2(sx * 0.34 * r, eye_y), 0.1 * r, ink)
			cv.draw_arc(c + Vector2(0, 0.08 * r), 0.36 * r, 0.35, PI - 0.35, 12, ink, w, true)
			for sx in [-1.0, 1.0]:
				cv.draw_circle(c + Vector2(sx * 0.6 * r, 0.22 * r), 0.13 * r, Color(1, 0.45, 0.55, 0.45))


static func draw_icon(cv: CanvasItem, kind: String, c: Vector2, s: float, col: Color, bg := Color(0, 0, 0, 0.35)) -> void:
	var w := maxf(2.0, s * 0.075)
	match kind:
		"apple":
			cv.draw_circle(c + Vector2(-0.13, 0.08) * s, 0.30 * s, col)
			cv.draw_circle(c + Vector2(0.13, 0.08) * s, 0.30 * s, col)
			cv.draw_line(c + Vector2(0, -0.2) * s, c + Vector2(0.05, -0.42) * s, col, w, true)
			cv.draw_colored_polygon(_circle_pts(c + Vector2(0.17, -0.3) * s, 0.15 * s, 0.07 * s, -0.5), col)
		"drop":
			var cc := c + Vector2(0, 0.1) * s
			var pts := PackedVector2Array([c + Vector2(0, -0.44) * s])
			for i in 25:
				var a := lerpf(-PI / 2.0 + 1.02, 1.5 * PI - 1.02, float(i) / 24.0)
				pts.append(cc + Vector2(cos(a), sin(a)) * 0.29 * s)
			cv.draw_colored_polygon(pts, col)
			cv.draw_circle(c + Vector2(-0.1, 0.14) * s, 0.06 * s, bg)
		"bubbles":
			cv.draw_arc(c + Vector2(-0.12, 0.1) * s, 0.22 * s, 0.0, TAU, 24, col, w, true)
			cv.draw_arc(c + Vector2(0.18, -0.12) * s, 0.15 * s, 0.0, TAU, 20, col, w, true)
			cv.draw_arc(c + Vector2(0.2, 0.24) * s, 0.1 * s, 0.0, TAU, 16, col, w, true)
		"heart":
			var hp := PackedVector2Array()
			for i in 32:
				var a2 := TAU * i / 32.0
				hp.append(c + Vector2(16.0 * pow(sin(a2), 3.0), -(13.0 * cos(a2) - 5.0 * cos(2.0 * a2) - 2.0 * cos(3.0 * a2) - cos(4.0 * a2))) * (s / 40.0) + Vector2(0, 0.02 * s))
			cv.draw_colored_polygon(hp, col)
		"game":
			_rrect(cv, Rect2(c + Vector2(-0.44, -0.2) * s, Vector2(0.88, 0.5) * s), 0.2 * s, col)
			cv.draw_line(c + Vector2(-0.26, 0.05) * s, c + Vector2(-0.06, 0.05) * s, bg, w * 1.2, true)
			cv.draw_line(c + Vector2(-0.16, -0.05) * s, c + Vector2(-0.16, 0.15) * s, bg, w * 1.2, true)
			cv.draw_circle(c + Vector2(0.16, 0.12) * s, 0.06 * s, bg)
			cv.draw_circle(c + Vector2(0.28, -0.02) * s, 0.06 * s, bg)
		"bag":
			cv.draw_arc(c + Vector2(0, -0.1) * s, 0.17 * s, PI, TAU, 14, col, w, true)
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.34, -0.12) * s, c + Vector2(0.34, -0.12) * s, c + Vector2(0.4, 0.4) * s, c + Vector2(-0.4, 0.4) * s]), col)
			cv.draw_circle(c + Vector2(-0.12, -0.02) * s, 0.04 * s, bg)
			cv.draw_circle(c + Vector2(0.12, -0.02) * s, 0.04 * s, bg)
		"case":
			cv.draw_polyline(PackedVector2Array([c + Vector2(-0.14, -0.1) * s, c + Vector2(-0.14, -0.28) * s, c + Vector2(0.14, -0.28) * s, c + Vector2(0.14, -0.1) * s]), col, w, true)
			_rrect(cv, Rect2(c + Vector2(-0.42, -0.14) * s, Vector2(0.84, 0.56) * s), 0.1 * s, col)
			cv.draw_line(c + Vector2(-0.42, 0.08) * s, c + Vector2(0.42, 0.08) * s, bg, w * 0.8, true)
			cv.draw_circle(c + Vector2(0, 0.08) * s, 0.06 * s, col)
		"shirt":
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.16, -0.36) * s, c + Vector2(-0.44, -0.2) * s, c + Vector2(-0.34, 0.02) * s, c + Vector2(-0.22, -0.06) * s,
				c + Vector2(-0.22, 0.4) * s, c + Vector2(0.22, 0.4) * s, c + Vector2(0.22, -0.06) * s, c + Vector2(0.34, 0.02) * s, c + Vector2(0.44, -0.2) * s, c + Vector2(0.16, -0.36) * s]), col)
			cv.draw_colored_polygon(_circle_pts(c + Vector2(0, -0.36) * s, 0.1 * s, 0.08 * s), bg)
		"house":
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.46, -0.02) * s, c + Vector2(0, -0.42) * s, c + Vector2(0.46, -0.02) * s]), col)
			cv.draw_rect(Rect2(c + Vector2(-0.32, -0.04) * s, Vector2(0.64, 0.44) * s), col)
			cv.draw_rect(Rect2(c + Vector2(-0.08, 0.14) * s, Vector2(0.16, 0.26) * s), bg)
		"menu":
			for dy in [-0.22, 0.0, 0.22]:
				cv.draw_line(c + Vector2(-0.3, dy) * s, c + Vector2(0.3, dy) * s, col, w * 1.5, true)
		"star":
			var sp := PackedVector2Array()
			for i in 10:
				var a3 := -PI / 2.0 + PI * i / 5.0
				sp.append(c + Vector2(cos(a3), sin(a3)) * (0.44 if i % 2 == 0 else 0.2) * s)
			cv.draw_colored_polygon(sp, col)
		"people":
			cv.draw_circle(c + Vector2(-0.16, -0.16) * s, 0.15 * s, col)
			cv.draw_colored_polygon(_circle_pts(c + Vector2(-0.16, 0.26) * s, 0.26 * s, 0.22 * s), col)
			cv.draw_circle(c + Vector2(0.2, -0.1) * s, 0.12 * s, col)
			cv.draw_colored_polygon(_circle_pts(c + Vector2(0.2, 0.3) * s, 0.2 * s, 0.18 * s), col)
		"smile":
			cv.draw_arc(c, 0.4 * s, 0.0, TAU, 28, col, w, true)
			cv.draw_circle(c + Vector2(-0.14, -0.1) * s, 0.05 * s, col)
			cv.draw_circle(c + Vector2(0.14, -0.1) * s, 0.05 * s, col)
			cv.draw_arc(c + Vector2(0, 0.02) * s, 0.2 * s, 0.2, PI - 0.2, 12, col, w, true)
		"bulb":
			cv.draw_circle(c + Vector2(0, -0.1) * s, 0.28 * s, col)
			_rrect(cv, Rect2(c + Vector2(-0.14, 0.1) * s, Vector2(0.28, 0.2) * s), 0.06 * s, col)
			cv.draw_line(c + Vector2(-0.1, 0.38) * s, c + Vector2(0.1, 0.38) * s, col, w, true)
		"coin":
			cv.draw_circle(c, 0.44 * s, Color("e0a000"))
			cv.draw_circle(c, 0.37 * s, Color("ffd34d"))
			cv.draw_arc(c, 0.25 * s, 0.0, TAU, 20, Color("e0a000"), w * 0.7, true)
		"crib":
			_rrect(cv, Rect2(c + Vector2(-0.42, -0.26) * s, Vector2(0.84, 0.52) * s), 0.08 * s, col)
			for x in [-0.28, -0.14, 0.0, 0.14, 0.28]:
				cv.draw_line(c + Vector2(x, -0.22) * s, c + Vector2(x, 0.22) * s, bg, w * 0.6, true)
			cv.draw_line(c + Vector2(-0.4, 0.26) * s, c + Vector2(-0.4, 0.42) * s, col, w, true)
			cv.draw_line(c + Vector2(0.4, 0.26) * s, c + Vector2(0.4, 0.42) * s, col, w, true)
		"lock":
			cv.draw_arc(c + Vector2(0, -0.08) * s, 0.2 * s, PI, TAU, 14, col, w * 1.3, true)
			cv.draw_line(c + Vector2(-0.2, -0.08) * s, c + Vector2(-0.2, 0.06) * s, col, w * 1.3, true)
			cv.draw_line(c + Vector2(0.2, -0.08) * s, c + Vector2(0.2, 0.06) * s, col, w * 1.3, true)
			_rrect(cv, Rect2(c + Vector2(-0.3, 0.0) * s, Vector2(0.6, 0.44) * s), 0.08 * s, col)
			cv.draw_circle(c + Vector2(0, 0.2) * s, 0.06 * s, bg)
		"book":  # libro abierto con dos hojas
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.46, -0.28) * s, c + Vector2(-0.02, -0.18) * s, c + Vector2(-0.02, 0.36) * s, c + Vector2(-0.46, 0.26) * s]), col)
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(0.46, -0.28) * s, c + Vector2(0.02, -0.18) * s, c + Vector2(0.02, 0.36) * s, c + Vector2(0.46, 0.26) * s]), col)
			for ly in [-0.06, 0.08, 0.2]:
				cv.draw_line(c + Vector2(-0.38, ly - 0.04) * s, c + Vector2(-0.12, ly + 0.02) * s, bg, w * 0.6, true)
				cv.draw_line(c + Vector2(0.38, ly - 0.04) * s, c + Vector2(0.12, ly + 0.02) * s, bg, w * 0.6, true)
		"bolt":  # rayo (fisico)
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(0.1, -0.45) * s, c + Vector2(-0.26, 0.06) * s, c + Vector2(-0.03, 0.06) * s,
				c + Vector2(-0.12, 0.46) * s, c + Vector2(0.28, -0.12) * s, c + Vector2(0.05, -0.12) * s]), col)
		"note":  # nota musical
			cv.draw_circle(c + Vector2(-0.14, 0.26) * s, 0.17 * s, col)
			cv.draw_line(c + Vector2(0.02, 0.22) * s, c + Vector2(0.02, -0.4) * s, col, w * 1.4, true)
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(0.02, -0.42) * s, c + Vector2(0.32, -0.28) * s, c + Vector2(0.32, -0.08) * s, c + Vector2(0.02, -0.22) * s]), col)
		"palette":  # paleta de pintura (creatividad)
			cv.draw_circle(c, 0.44 * s, col)
			for hp in [Vector2(-0.18, -0.12), Vector2(0.02, -0.24), Vector2(0.22, -0.06), Vector2(-0.2, 0.14)]:
				cv.draw_circle(c + hp * s, 0.07 * s, bg)
			cv.draw_circle(c + Vector2(0.18, 0.24) * s, 0.1 * s, bg)
		"calc":  # + - x = (matematicas)
			var arm := 0.12 * s
			var p1 := c + Vector2(-0.2, -0.2) * s
			cv.draw_line(p1 - Vector2(arm, 0), p1 + Vector2(arm, 0), col, w * 1.4, true)
			cv.draw_line(p1 - Vector2(0, arm), p1 + Vector2(0, arm), col, w * 1.4, true)
			var p2 := c + Vector2(0.22, -0.2) * s
			cv.draw_line(p2 - Vector2(arm, 0), p2 + Vector2(arm, 0), col, w * 1.4, true)
			var p3 := c + Vector2(-0.2, 0.22) * s
			cv.draw_line(p3 + Vector2(-arm, -arm), p3 + Vector2(arm, arm), col, w * 1.4, true)
			cv.draw_line(p3 + Vector2(-arm, arm), p3 + Vector2(arm, -arm), col, w * 1.4, true)
			var p4 := c + Vector2(0.22, 0.22) * s
			cv.draw_line(p4 + Vector2(-arm, -arm * 0.5), p4 + Vector2(arm, -arm * 0.5), col, w * 1.4, true)
			cv.draw_line(p4 + Vector2(-arm, arm * 0.5), p4 + Vector2(arm, arm * 0.5), col, w * 1.4, true)
		"puzzle":  # pieza de rompecabezas (logica)
			_rrect(cv, Rect2(c + Vector2(-0.3, -0.2) * s, Vector2(0.6, 0.56) * s), 0.06 * s, col)
			cv.draw_circle(c + Vector2(0.0, -0.26) * s, 0.1 * s, col)
			cv.draw_circle(c + Vector2(0.33, 0.08) * s, 0.1 * s, col)
			cv.draw_circle(c + Vector2(-0.3, 0.08) * s, 0.1 * s, bg)
		"sprout":  # brote (crecimiento)
			cv.draw_line(c + Vector2(0, 0.42) * s, c + Vector2(0, -0.02) * s, col, w * 1.4, true)
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.02, 0.1) * s, c + Vector2(-0.44, -0.02) * s, c + Vector2(-0.36, -0.32) * s, c + Vector2(-0.04, -0.14) * s]), col)
			cv.draw_colored_polygon(PackedVector2Array([c + Vector2(0.02, 0.0) * s, c + Vector2(0.44, -0.12) * s, c + Vector2(0.36, -0.42) * s, c + Vector2(0.04, -0.24) * s]), col)
		"moon":  # luna en cuarto creciente con una estrellita (sueño, noche)
			cv.draw_colored_polygon(_crescent(c + Vector2(-0.06, 0.02) * s, 0.36 * s, c + Vector2(0.12, -0.1) * s, 0.3 * s), col)
			var st := c + Vector2(0.28, 0.2) * s
			cv.draw_line(st + Vector2(-0.08, 0) * s, st + Vector2(0.08, 0) * s, col, w, true)
			cv.draw_line(st + Vector2(0, -0.08) * s, st + Vector2(0, 0.08) * s, col, w, true)
		"gift":  # caja con mono
			_rrect(cv, Rect2(c + Vector2(-0.36, -0.06) * s, Vector2(0.72, 0.48) * s), 0.06 * s, col)
			_rrect(cv, Rect2(c + Vector2(-0.42, -0.2) * s, Vector2(0.84, 0.16) * s), 0.04 * s, col)
			cv.draw_line(c + Vector2(0, -0.2) * s, c + Vector2(0, 0.42) * s, bg, w * 1.2, true)
			cv.draw_colored_polygon(_circle_pts(c + Vector2(-0.13, -0.3) * s, 0.14 * s, 0.08 * s, 0.5), col)
			cv.draw_colored_polygon(_circle_pts(c + Vector2(0.13, -0.3) * s, 0.14 * s, 0.08 * s, -0.5), col)
		"check":
			cv.draw_polyline(PackedVector2Array([c + Vector2(-0.3, 0.02) * s, c + Vector2(-0.08, 0.24) * s, c + Vector2(0.32, -0.22) * s]), col, w * 1.8, true)
		"clock":   # reloj (cuanto falta para que cambie algo)
			cv.draw_arc(c, 0.38 * s, 0.0, TAU, 28, col, w * 1.3, true)
			cv.draw_line(c, c + Vector2(0, -0.24) * s, col, w * 1.3, true)
			cv.draw_line(c, c + Vector2(0.17, 0.08) * s, col, w * 1.3, true)
		"chevron_down":
			cv.draw_polyline(PackedVector2Array([c + Vector2(-0.3, -0.12) * s, c + Vector2(0, 0.16) * s, c + Vector2(0.3, -0.12) * s]), col, w * 1.5, true)
		"chevron_up":
			cv.draw_polyline(PackedVector2Array([c + Vector2(-0.3, 0.12) * s, c + Vector2(0, -0.16) * s, c + Vector2(0.3, 0.12) * s]), col, w * 1.5, true)
		"female":
			cv.draw_arc(c + Vector2(0, -0.12) * s, 0.24 * s, 0.0, TAU, 24, col, w * 1.2, true)
			cv.draw_line(c + Vector2(0, 0.12) * s, c + Vector2(0, 0.44) * s, col, w * 1.2, true)
			cv.draw_line(c + Vector2(-0.14, 0.3) * s, c + Vector2(0.14, 0.3) * s, col, w * 1.2, true)
		"male":
			cv.draw_arc(c + Vector2(-0.06, 0.1) * s, 0.24 * s, 0.0, TAU, 24, col, w * 1.2, true)
			var tip := c + Vector2(0.3, -0.3) * s
			cv.draw_line(c + Vector2(0.12, -0.1) * s, tip, col, w * 1.2, true)
			cv.draw_line(tip, tip + Vector2(-0.2, 0.0) * s, col, w * 1.2, true)
			cv.draw_line(tip, tip + Vector2(0.0, 0.2) * s, col, w * 1.2, true)
