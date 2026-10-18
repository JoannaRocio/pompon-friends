class_name IntroDemo
extends Control
## Mini animacion que explica el trabajo sin palabras: a la izquierda se arrastra un libro a su
## estante; a la derecha un alumno levanta la mano, se toca la señal y se elige la respuesta.

const OUT := Color("5b3a4a")
const LOOP := 4.4

var _t := 0.0


func _process(delta: float) -> void:
	_t = fmod(_t + delta, LOOP)
	queue_redraw()


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _card(r: Rect2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff6fa")
	sb.border_color = Color("ffc2d9")
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(30)
	draw_style_box(sb, r)


func _touch(p: Vector2, press: float) -> void:
	# punto de toque: un circulo que se achica al presionar y una ondita
	draw_circle(p + Vector2(0, 6), 20.0, Color(0, 0, 0, 0.12))
	draw_circle(p, 20.0 - 4.0 * press, Color(1, 1, 1, 0.95))
	draw_arc(p, 20.0 - 4.0 * press, 0.0, TAU, 24, Color("ff4f86"), 4.0, true)
	if press > 0.0:
		draw_arc(p, 20.0 + 26.0 * press, 0.0, TAU, 28, Color("ff4f86", 1.0 - press), 3.0, true)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var left := Rect2(0, 0, w * 0.5 - 8.0, h)
	var right := Rect2(w * 0.5 + 8.0, 0, w * 0.5 - 8.0, h)
	_card(left)
	_card(right)
	_draw_sort(left)
	_draw_exam(right)
	# flecha de "mientras tanto"
	var font := get_theme_default_font()
	draw_string(font, Vector2(w * 0.5 - 20.0, h * 0.5 + 12.0), "+", HORIZONTAL_ALIGNMENT_CENTER, 40, 44, Color("ff4f86"))


func _draw_sort(r: Rect2) -> void:
	var t := _t
	var bin := Rect2(r.position.x + r.size.x * 0.5 - 62.0, r.end.y - 112.0, 124.0, 88.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("e7b98a")
	sb.border_color = OUT
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	draw_style_box(sb, bin)
	draw_rect(Rect2(bin.position.x + 10, bin.position.y + 10, bin.size.x - 20, bin.size.y - 20), Color("c98f5e"))
	for k in 3:
		draw_rect(Rect2(bin.position.x + 16 + k * 20, bin.end.y - 48, 14, 36), [Color("5bb8f5"), Color("ffcf3f"), Color("7bd389")][k])
	var start := Vector2(r.position.x + 56.0, r.position.y + 70.0)
	var target := bin.get_center() + Vector2(0, -10)
	var pos := start
	var scale_f := 1.0
	var press := 0.0
	var finger := start + Vector2(0, 8)
	if t < 0.5:
		scale_f = _ease(t / 0.35)
		finger = start + Vector2(30, 40)
	elif t < 2.0:
		var k := _ease((t - 0.5) / 1.5)
		pos = start.lerp(target, k)
		finger = pos + Vector2(8, 10)
		press = 0.0
	elif t < 2.4:
		var k2 := (t - 2.0) / 0.4
		pos = target
		scale_f = 1.0 - 0.6 * k2
		finger = target + Vector2(8, 10)
		press = k2
	else:
		scale_f = 0.0
		finger = target + Vector2(30, 40)
	if scale_f > 0.02:
		draw_set_transform(pos, -0.1, Vector2(scale_f, scale_f))
		var book := StyleBoxFlat.new()
		book.bg_color = Color("ff7aa8")
		book.border_color = OUT
		book.set_border_width_all(4)
		book.set_corner_radius_all(8)
		draw_style_box(book, Rect2(-24, -32, 48, 64))
		draw_rect(Rect2(-24, -32, 12, 64), Color("e0608d"))
		draw_rect(Rect2(-4, -18, 22, 18), Color(1, 1, 1, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t >= 2.0 and t < 2.9:
		for i in 6:
			var a := TAU * i / 6.0
			var d := 20.0 + 40.0 * (t - 2.0)
			draw_circle(target + Vector2(cos(a), sin(a)) * d, 5.0, Color("ffd33d", clampf(1.0 - (t - 2.0) / 0.9, 0.0, 1.0)))
	if t < 2.2 or t > 2.4:
		_touch(finger, press)


func _draw_exam(r: Rect2) -> void:
	var t := _t
	var font := get_theme_default_font()
	var cx := r.position.x + r.size.x * 0.5
	# alumno
	var head := Vector2(cx, r.position.y + r.size.y * 0.62)
	draw_circle(head + Vector2(0, 4), 52.0, Color(0, 0, 0, 0.1))
	draw_circle(head, 52.0, OUT)
	draw_circle(head, 47.0, Color("ffb3cc"))
	draw_circle(head + Vector2(-17, -4), 6.0, OUT)
	draw_circle(head + Vector2(17, -4), 6.0, OUT)
	draw_arc(head + Vector2(0, 8), 12.0, 0.2, PI - 0.2, 10, OUT, 4.0, true)
	draw_circle(head + Vector2(-32, 12), 8.0, Color(1, 0.55, 0.62, 0.5))
	draw_circle(head + Vector2(32, 12), 8.0, Color(1, 0.55, 0.62, 0.5))
	var bubble := Rect2(cx - 40.0, r.position.y + 18.0, 80.0, 62.0)
	var finger := Vector2(cx + 40.0, r.end.y - 20.0)
	var press := 0.0
	var show_q := false
	var picked := false
	if t < 0.3:
		pass
	elif t < 1.6:
		var k := _ease((t - 0.3) / 0.35)
		_bubble(bubble, k, font)
		if t > 0.9:
			var m := _ease((t - 0.9) / 0.6)
			finger = Vector2(cx + 40.0, r.end.y - 20.0).lerp(bubble.get_center() + Vector2(10, 14), m)
			press = clampf((t - 1.4) / 0.2, 0.0, 1.0)
	elif t < 3.9:
		show_q = true
		picked = t > 3.0
	if show_q:
		var board := Rect2(r.position.x + 18.0, r.position.y + 14.0, r.size.x - 36.0, 66.0)
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color("4f8a76")
		bs.border_color = Color("c99560")
		bs.set_border_width_all(5)
		bs.set_corner_radius_all(16)
		draw_style_box(bs, board)
		draw_string(font, board.position + Vector2(0, 46), "2 + 3 = ?", HORIZONTAL_ALIGNMENT_CENTER, board.size.x, 38, Color("fffbe8"))
		var opts := ["4", "5", "6"]
		var ow := (r.size.x - 36.0 - 20.0) / 3.0
		var right_one := Vector2.ZERO
		for i in 3:
			var orect := Rect2(r.position.x + 18.0 + i * (ow + 10.0), r.end.y - 92.0, ow, 60.0)
			var os := StyleBoxFlat.new()
			var good := picked and i == 1
			os.bg_color = Color("bff0cc") if good else Color("ffffff")
			os.border_color = Color("2f9e6e") if good else Color("ffc2d9")
			os.set_border_width_all(4)
			os.set_corner_radius_all(18)
			draw_style_box(os, orect)
			draw_string(font, orect.position + Vector2(0, 44), opts[i], HORIZONTAL_ALIGNMENT_CENTER, orect.size.x, 38, OUT)
			if i == 1:
				right_one = orect.get_center()
		if t < 3.0:
			var m2 := _ease((t - 1.7) / 1.0)
			finger = Vector2(cx, r.position.y + 100.0).lerp(right_one + Vector2(8, 10), m2)
			press = clampf((t - 2.7) / 0.25, 0.0, 1.0)
		else:
			finger = right_one + Vector2(8, 10)
			press = 0.0
			var ck := _ease((t - 3.0) / 0.3)
			draw_set_transform(right_one + Vector2(ow * 0.32, -22.0), 0.0, Vector2(ck, ck))
			draw_circle(Vector2.ZERO, 16.0, Color("2f9e6e"))
			draw_polyline(PackedVector2Array([Vector2(-7, 0), Vector2(-2, 6), Vector2(8, -6)]), Color.WHITE, 4.0, true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t > 0.3 and t < 3.9:
		_touch(finger, press)


func _bubble(r: Rect2, k: float, font: Font) -> void:
	if k <= 0.01:
		return
	var c := r.get_center()
	draw_set_transform(c, 0.0, Vector2(k, k))
	var rr := Rect2(-r.size * 0.5, r.size)
	var b := StyleBoxFlat.new()
	b.bg_color = Color("fffdf6")
	b.border_color = Color("ff4f86")
	b.set_border_width_all(5)
	b.set_corner_radius_all(24)
	draw_style_box(b, rr)
	draw_colored_polygon(PackedVector2Array([Vector2(-10, rr.end.y - 2), Vector2(10, rr.end.y - 2), Vector2(0, rr.end.y + 16)]), Color("ff4f86"))
	draw_string(font, Vector2(-r.size.x * 0.5, 24), "!", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 70, Color("ff4f86"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
