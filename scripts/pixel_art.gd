class_name PixelArt
extends RefCounted
## Dibujos de pixel art (16 x 16) que se pintan en el minijuego "Pintar": se guardan como un texto de
## 256 letras (un color de la paleta por cuadrito, de "0" a "f"), se cuelgan en la pared como un cuadro
## (ids "art_xxxxxx") y se pueden regalar a un amigo de verdad.
## `cache` (id -> {"px", "from"}) lo llena GameState al cargar; asi ItemArt los dibuja sin depender de el.

const SIZE := 16
const PIXELS := SIZE * SIZE
const BLANK := "0"   # el color 0 es el fondo (blanco)
const PALETTE := [
	Color("fffdf8"), Color("2b2b2b"), Color("ef4444"), Color("fb923c"), Color("facc15"), Color("22c55e"),
	Color("3b82f6"), Color("a855f7"), Color("f472b6"), Color("92633a"), Color("9ca3af"), Color("86efac"),
	Color("93c5fd"), Color("fbcfe8"), Color("fde68a"), Color("7c2d12"),
]
const PREFIX := "art_"
const MAX_SAVED := 30   # dibujos guardados como maximo (los mas viejos que no estan colgados se borran)

static var cache := {}


static func blank() -> String:
	return BLANK.repeat(PIXELS)


static func is_art(id: String) -> bool:
	return id.begins_with(PREFIX)


## ¿Es un dibujo valido? (256 letras de 0-9 y a-f)
static func valid(px: String) -> bool:
	if px.length() != PIXELS:
		return false
	for ch in px:
		if not ch in "0123456789abcdef":
			return false
	return true


static func get_pixel(px: String, x: int, y: int) -> int:
	return ("0x" + px[y * SIZE + x]).hex_to_int()


static func set_pixel(px: String, x: int, y: int, color_index: int) -> String:
	var i := y * SIZE + x
	return px.substr(0, i) + "%x" % clampi(color_index, 0, 15) + px.substr(i + 1)


## Balde de pintura: rellena la zona del mismo color que (x, y).
static func fill(px: String, x: int, y: int, color_index: int) -> String:
	var target := get_pixel(px, x, y)
	if target == color_index:
		return px
	var cells := px.split("")
	var hex := "%x" % color_index
	var stack := [Vector2i(x, y)]
	var want := "%x" % target
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= SIZE or p.y >= SIZE:
			continue
		var i := p.y * SIZE + p.x
		if cells[i] != want:
			continue
		cells[i] = hex
		stack.append_array([p + Vector2i(1, 0), p + Vector2i(-1, 0), p + Vector2i(0, 1), p + Vector2i(0, -1)])
	return "".join(cells)


## Cuantos cuadritos estan pintados (no son el fondo).
static func painted(px: String) -> int:
	return PIXELS - px.count(BLANK)


## Cuantos colores distintos uso (sin el fondo).
static func colors_used(px: String) -> int:
	var seen := {}
	for ch in px:
		if ch != BLANK:
			seen[ch] = true
	return seen.size()


## Dibuja los cuadritos en `rect` (cuadrado).
static func draw_pixels(cv: CanvasItem, rect: Rect2, px: String) -> void:
	if not valid(px):
		return
	var cell := rect.size / SIZE
	cv.draw_rect(rect, PALETTE[0])
	for y in SIZE:
		for x in SIZE:
			var c := get_pixel(px, x, y)
			if c != 0:
				cv.draw_rect(Rect2(rect.position + Vector2(x, y) * cell, cell + Vector2(0.6, 0.6)), PALETTE[c])


## El cuadro colgado: marco de madera con el dibujo adentro.
static func draw_framed(cv: CanvasItem, id: String, rect: Rect2) -> void:
	var out := Color("5b3a4a")
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("c9925f")
	frame.border_color = out
	frame.set_border_width_all(4)
	frame.set_corner_radius_all(8)
	frame.anti_aliasing = true
	cv.draw_style_box(frame, rect)
	var pad := rect.size.x * 0.12
	var inner := Rect2(rect.position + Vector2(pad, pad), Vector2(rect.size.x - pad * 2.0, rect.size.x - pad * 2.0))
	draw_pixels(cv, inner, str(cache.get(id, {}).get("px", "")))
	cv.draw_rect(inner, out, false, 2.0)
	if str(cache.get(id, {}).get("from", "")) != "":   # regalado: un moñito
		var c := Vector2(rect.end.x - 10.0, rect.position.y + 10.0)
		cv.draw_circle(c + Vector2(-8, 0), 7.0, Color("ff7aa8"))
		cv.draw_circle(c + Vector2(8, 0), 7.0, Color("ff7aa8"))
		cv.draw_circle(c, 5.0, Color("d6336c"))


## Nombre que se ve en el cuarto y en el diario.
static func name_of(id: String) -> String:
	var from := str(cache.get(id, {}).get("from", ""))
	return "Dibujo de %s" % from if from != "" else "Mi dibujo"
