class_name TownBuilding
extends Button
## Un edificio del pueblo (todo dibujado por codigo) que se toca para entrar: la casa del Pompon,
## la casa de un vecino, la tienda, el supermercado, el cine o el museo. Los que todavia no abren
## llevan una cinta de T.s("Próximamente").

const OUT := Color("5b3a4a")
const GROUND := 0.98   # donde apoya (fraccion del alto)
const ART_SCALE := 1.4  # los dibujos se agrandan asi (se dibujan en medidas chicas)

var kind := "house"       # "home", "house", "shop", "market", "cinema", "museum"
var title := ""           # lo que dice el cartel
var tint := Color("ffb3cc")
var locked := false
var friend := false       # amigo de verdad: lleva una estrellita en el cartel
var art: Control


func setup(building_kind: String, sign_text: String, color: Color, is_locked := false) -> TownBuilding:
	kind = building_kind
	title = sign_text
	tint = color
	locked = is_locked
	flat = true
	focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	custom_minimum_size = Vector2(_width() * ART_SCALE, 0)
	art = Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(_draw_art)
	add_child(art)
	button_down.connect(func(): art.scale = Vector2(0.97, 0.97))
	button_up.connect(func(): art.scale = Vector2.ONE)
	resized.connect(func(): art.pivot_offset = Vector2(size.x * 0.5, size.y * GROUND))
	return self


func _width() -> float:
	match kind:
		"market", "museum":
			return 340.0
		"cinema", "shop":
			return 300.0
		"home":
			return 290.0
	return 250.0


# ---------------------------------------------------------------- ayudas

func _box(r: Rect2, col: Color, radius := 10.0, w := 5) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = OUT
	sb.set_border_width_all(w)
	sb.set_corner_radius_all(int(radius))
	sb.anti_aliasing = true
	art.draw_style_box(sb, r)


func _poly(pts: PackedVector2Array, col: Color) -> void:
	art.draw_colored_polygon(pts, col)
	var closed := pts.duplicate()
	closed.append(pts[0])
	art.draw_polyline(closed, OUT, 5.0, true)


func _window(r: Rect2, lit := true) -> void:
	_box(r, Color("fff3b0") if lit else Color("bfe6ff"), 8.0, 4)
	art.draw_line(Vector2(r.get_center().x, r.position.y + 3), Vector2(r.get_center().x, r.end.y - 3), OUT, 3.0)
	art.draw_line(Vector2(r.position.x + 3, r.get_center().y), Vector2(r.end.x - 3, r.get_center().y), OUT, 3.0)


func _door(r: Rect2, col: Color) -> void:
	_box(r, col, 12.0)
	art.draw_circle(Vector2(r.end.x - 12.0, r.get_center().y + 4.0), 4.5, Color("ffd84d"))


## Cartel con el nombre (arriba del edificio o en su frente).
func _sign(center: Vector2, max_w: float, col: Color) -> void:
	var font := art.get_theme_default_font()
	var fs := 26
	var shown := T.s(title)   # (el titulo es el nombre en español: se traduce al dibujarlo)
	while fs > 16 and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w - 28.0:
		fs -= 2
	var w := minf(font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 30.0, max_w)
	var r := Rect2(center - Vector2(w * 0.5, 22.0), Vector2(w, 44.0))
	_box(r, Color("fffaf0"), 14.0, 4)
	art.draw_string(font, Vector2(r.position.x, r.position.y + 30.0), shown, HORIZONTAL_ALIGNMENT_CENTER, w, fs, col)
	if friend:
		var c := Vector2(r.end.x - 4.0, r.position.y + 4.0)
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI / 2.0 + PI * i / 5.0
			pts.append(c + Vector2(cos(a), sin(a)) * (14.0 if i % 2 == 0 else 6.0))
		_poly(pts, Color("ffcf3f"))


func _draw_art() -> void:
	art.draw_set_transform(Vector2.ZERO, 0.0, Vector2(ART_SCALE, ART_SCALE))
	var w := size.x / ART_SCALE
	var g := size.y * GROUND / ART_SCALE
	match kind:
		"home", "house":
			_house(w, g)
		"shop":
			_shop(w, g)
		"market":
			_market(w, g)
		"cinema":
			_cinema(w, g)
		"museum":
			_museum(w, g)
	if locked:
		_ribbon(w, g)


func _house(w: float, g: float) -> void:
	var bw := w * 0.78
	var bh := 230.0 if kind == "home" else 200.0
	var x0 := (w - bw) * 0.5
	var wall := tint.lightened(0.55)
	_box(Rect2(x0, g - bh, bw, bh), wall, 10.0)
	_poly(PackedVector2Array([Vector2(x0 - 22, g - bh + 6), Vector2(w * 0.5, g - bh - 120), Vector2(x0 + bw + 22, g - bh + 6)]), tint.darkened(0.08))
	_box(Rect2(x0 + bw * 0.68, g - bh - 92, 28, 50), Color("c9925f"), 4.0, 4)   # chimenea
	_door(Rect2(w * 0.5 - 34, g - 108, 68, 108), Color("b07a52"))
	if kind == "home":  # ventana con corazon: es tu casa
		var c := Vector2(w * 0.5, g - bh - 40)
		art.draw_circle(c, 28.0, Color("fff3b0"))
		art.draw_arc(c, 28.0, 0.0, TAU, 24, OUT, 4.0, true)
		Hud.draw_icon(art, "heart", c, 32.0, Color("ff7aa8"), Color(0, 0, 0, 0))
	_window(Rect2(x0 + 16, g - bh + 40, 54, 54))
	_window(Rect2(x0 + bw - 70, g - bh + 40, 54, 54))
	_sign(Vector2(w * 0.5, g - bh - 150), w, Color("d6336c") if kind == "home" else OUT)


func _shop(w: float, g: float) -> void:
	var bw := w * 0.86
	var x0 := (w - bw) * 0.5
	var bh := 250.0
	_box(Rect2(x0, g - bh, bw, bh), Color("fff0f6"), 10.0)
	# toldo a rayas
	var stripes := 7
	var sw := (bw + 20.0) / stripes
	for i in stripes:
		var r := Rect2(x0 - 10 + sw * i, g - bh + 52, sw, 46)
		art.draw_rect(r, Color("ff7aa8") if i % 2 == 0 else Color.WHITE)
		art.draw_circle(Vector2(r.get_center().x, r.end.y), sw * 0.5, Color("ff7aa8") if i % 2 == 0 else Color.WHITE)
	art.draw_rect(Rect2(x0 - 10, g - bh + 52, bw + 20, 46), OUT, false, 4.0)
	_box(Rect2(x0 + 20, g - 120, bw * 0.48, 92), Color("bfe6ff"), 8.0, 4)   # vidriera
	Hud.draw_icon(art, "bag", Vector2(x0 + 20 + bw * 0.24, g - 74), 54.0, Color("ff7aa8"), Color(0, 0, 0, 0))
	_door(Rect2(x0 + bw - 96, g - 124, 72, 124), Color("ff9ec0"))
	_sign(Vector2(w * 0.5, g - bh + 22), bw - 10.0, Color("d6336c"))


func _market(w: float, g: float) -> void:
	var bw := w * 0.9
	var x0 := (w - bw) * 0.5
	var bh := 240.0
	_box(Rect2(x0, g - bh, bw, bh), Color("f4fff0"), 10.0)
	_box(Rect2(x0 - 8, g - bh + 50, bw + 16, 34), Color("5fc77f"), 8.0, 4)
	_box(Rect2(w * 0.5 - 60, g - 130, 120, 130), Color("bfe6ff"), 6.0, 4)   # puertas de vidrio
	art.draw_line(Vector2(w * 0.5, g - 128), Vector2(w * 0.5, g - 2), OUT, 4.0)
	for side: float in [-1.0, 1.0]:   # cajones de fruta
		var cx := w * 0.5 + side * (bw * 0.33)
		_box(Rect2(cx - 44, g - 54, 88, 54), Color("e0a96d"), 6.0, 4)
		for k in 3:
			art.draw_circle(Vector2(cx - 26 + k * 26, g - 60), 13.0, [Color("ef4444"), Color("ffd84d"), Color("fb923c")][k])
	_sign(Vector2(w * 0.5, g - bh + 24), bw - 10.0, Color("2f9e6e"))


func _cinema(w: float, g: float) -> void:
	var bw := w * 0.84
	var x0 := (w - bw) * 0.5
	var bh := 280.0
	_box(Rect2(x0, g - bh, bw, bh), Color("7b5ea7"), 10.0)
	_box(Rect2(x0 + 18, g - bh + 74, bw - 36, 70), Color("fff3b0"), 8.0, 4)   # marquesina
	for i in 9:   # lucecitas
		art.draw_circle(Vector2(x0 + 30 + (bw - 60) * i / 8.0, g - bh + 64), 6.0, Color("ffd84d"))
	for k in 3:   # estrellitas en la marquesina
		var sc := Vector2(w * 0.5 + (k - 1) * 52.0, g - bh + 109)
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI / 2.0 + PI * i / 5.0
			pts.append(sc + Vector2(cos(a), sin(a)) * (18.0 if i % 2 == 0 else 8.0))
		art.draw_colored_polygon(pts, Color("e0609e"))
	_box(Rect2(x0 + 20, g - 128, 60, 88), Color("ff8fab"), 6.0, 4)   # cartel de pelicula
	art.draw_circle(Vector2(x0 + 50, g - 92), 16.0, Color("fff3b0"))
	_door(Rect2(w * 0.5 - 40, g - 120, 80, 120), Color("e0609e"))
	_box(Rect2(x0 + bw - 80, g - 128, 60, 88), Color("7cc8ff"), 6.0, 4)
	_sign(Vector2(w * 0.5, g - bh + 24), bw - 10.0, Color("7b5ea7"))


func _museum(w: float, g: float) -> void:
	var bw := w * 0.86
	var x0 := (w - bw) * 0.5
	var bh := 220.0
	_box(Rect2(x0 - 10, g - 26, bw + 20, 26), Color("e8e0d0"), 4.0, 4)   # escalones
	_box(Rect2(x0, g - bh, bw, bh - 24), Color("f6f0e4"), 4.0)
	_poly(PackedVector2Array([Vector2(x0 - 16, g - bh), Vector2(w * 0.5, g - bh - 90), Vector2(x0 + bw + 16, g - bh)]), Color("efe6d4"))
	for i in 5:   # columnas
		var cx := x0 + 26 + (bw - 52) * i / 4.0
		_box(Rect2(cx - 11, g - bh + 18, 22, bh - 46), Color.WHITE, 3.0, 3)
	_door(Rect2(w * 0.5 - 30, g - 120, 60, 94), Color("b07a52"))
	_sign(Vector2(w * 0.5, g - bh - 40), bw * 0.7, Color("8a6d3b"))


## Cinta T.s("Próximamente") cruzada sobre el frente.
func _ribbon(w: float, g: float) -> void:
	var y := g - 70.0
	var r := Rect2(w * 0.08, y - 24.0, w * 0.84, 48.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ffcf3f")
	sb.border_color = OUT
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(10)
	art.draw_set_transform(r.get_center() * ART_SCALE, -0.12, Vector2(ART_SCALE, ART_SCALE))
	art.draw_style_box(sb, Rect2(-r.size * 0.5, r.size))
	var font := art.get_theme_default_font()
	art.draw_string(font, Vector2(-r.size.x * 0.5, 10.0), T.s("Próximamente"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, OUT)
	art.draw_set_transform(Vector2.ZERO, 0.0)
