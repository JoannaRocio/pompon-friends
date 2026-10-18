class_name ClassroomView
extends Control
## El salon de clase: pizarra, ventana, dos alumnos Pompon estudiando en sus pupitres y la profe
## (el Pompon del jugador). Cuando un alumno termina su examen levanta la mano y aparece una señal "!"
## sobre su cabeza: hay que tocarla para corregirlo.

signal exam_tapped

const OUT := Color("5b3a4a")
const STUDENT_SPECIES := ["Felino", "Canino", "Conejo", "Ave", "Dragon", "Raton", "Reptil"]
const STUDENT_COLORS := [
	["ffb3cc", "fff0f5"], ["a8d8f0", "f4f9ff"], ["ffe27a", "fff6cf"], ["9ad9a8", "e8f8d8"],
	["e8c08c", "fff0d8"], ["d2b8f0", "f6efff"], ["ffc09a", "fff1e6"],
]

var student_names: Array = ["", ""]
var hand_student := -1
var board_text := "+ −"
var _students: Array = []
var _teacher: PomponView
var _front: Control
var _t := 0.0
var _cheer := 0.0
var _rng := RandomNumberGenerator.new()
var anchor: Control   # punto invisible sobre la señal (para la flecha guia)


class Front extends Control:
	var room: ClassroomView

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		room._draw_front(self)


func _ready() -> void:
	_rng.randomize()
	clip_contents = true
	var picked: Array = []
	for i in 2:
		var sp: String = STUDENT_SPECIES[_rng.randi() % STUDENT_SPECIES.size()]
		var col: Array = STUDENT_COLORS[_rng.randi() % STUDENT_COLORS.size()]
		var v := PomponView.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var eq := {}
		if i == 1:
			eq = {"glasses": "glasses_round"}
		v.set_pompon(PomponView.make_sample(sp, Color(col[0]), Color(col[1])), eq)
		add_child(v)
		_students.append(v)
		var nm: String = ProfileDialog.NAME_IDEAS[_rng.randi() % ProfileDialog.NAME_IDEAS.size()]
		while nm in picked:
			nm = ProfileDialog.NAME_IDEAS[_rng.randi() % ProfileDialog.NAME_IDEAS.size()]
		picked.append(nm)
		student_names[i] = nm
	_teacher = PomponView.new()
	_teacher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if GameState.pompon != null:
		_teacher.set_pompon(GameState.pompon, GameState.equipped)
	add_child(_teacher)
	_front = Front.new()
	(_front as Front).room = self
	_front.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_front)
	anchor = Control.new()
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.size = Vector2(4, 4)
	add_child(anchor)
	resized.connect(_layout)
	_layout.call_deferred()


# ------------------------------------------------------------------ medidas

func student_center(i: int) -> float:
	return size.x * (0.40 if i == 0 else 0.79)


func student_box() -> Vector2:
	var h := size.y * 0.66
	return Vector2(h * 0.70, h)


func base_y() -> float:
	return size.y * 0.90


func _layout() -> void:
	var sb := student_box()
	for i in _students.size():
		var v: PomponView = _students[i]
		v.size = sb
		v.position = Vector2(student_center(i) - sb.x * 0.5, base_y() - sb.y)
	var tb := Vector2(sb.x * 0.62, sb.y * 0.74)
	_teacher.size = tb
	_teacher.position = Vector2(size.x * 0.11 - tb.x * 0.5, base_y() - tb.y + 6.0)
	queue_redraw()
	_front.queue_redraw()


func bubble_rect() -> Rect2:
	if hand_student < 0:
		return Rect2()
	var sb := student_box()
	var cx := student_center(hand_student)
	return Rect2(cx - 78.0, maxf(base_y() - sb.y - 120.0, 10.0) + sin(_t * 5.0) * 6.0, 156.0, 112.0)


# ------------------------------------------------------------------- acciones

func raise_hand(i: int) -> void:
	hand_student = i
	Audio.play("ding")


func lower_hand() -> void:
	hand_student = -1


## Los alumnos festejan (cuando se corrige bien o se ordena mucho).
func cheer(hearts := 4) -> void:
	_cheer = 1.0
	for v in _students:
		(v as PomponView).celebrate(hearts)
	_teacher.celebrate(2)


func _process(delta: float) -> void:
	_t += delta
	_cheer = maxf(0.0, _cheer - delta * 1.5)
	for i in _students.size():
		var v: PomponView = _students[i]
		var base := base_y() - student_box().y
		var bob := sin(_t * 1.8 + i * 1.7) * 3.0
		if hand_student == i:
			bob = -absf(sin(_t * 5.0)) * 12.0
		v.position.y = base + bob
	if hand_student >= 0:
		var r := bubble_rect()
		anchor.position = r.position + Vector2(r.size.x * 0.5 - 2.0, 0.0)
	queue_redraw()
	_front.queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if hand_student < 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var sb := student_box()
		var cx := student_center(hand_student)
		var zone := Rect2(cx - sb.x * 0.5, base_y() - sb.y, sb.x, sb.y).merge(bubble_rect()).grow(14.0)
		if zone.has_point(event.position):
			exam_tapped.emit()


# --------------------------------------------------------------------- dibujo

func _draw() -> void:
	var w := size.x
	var h := size.y
	var fy := h * 0.66
	# pared con zocalo
	draw_rect(Rect2(0, 0, w, fy), Color("ffe9c9"))
	for i in 9:
		draw_rect(Rect2(i * w / 8.0, 0, 3, fy), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(0, fy - 70, w, 70), Color("f6cf9c"))
	draw_rect(Rect2(0, fy - 74, w, 8), Color("fff3dc"))
	# piso de madera
	draw_rect(Rect2(0, fy, w, h - fy), Color("e2b780"))
	var y := fy + 34.0
	while y < h:
		draw_line(Vector2(0, y), Vector2(w, y), Color("c99a64"), 3.0)
		y += 46.0
	var gx := 0.0
	var row := 0
	y = fy
	while y < h:
		gx = 40.0 + (row % 2) * 90.0
		while gx < w:
			draw_line(Vector2(gx, y), Vector2(gx, minf(y + 34.0, h)), Color("c99a64"), 3.0)
			gx += 180.0
		y += 34.0 if row == 0 else 46.0
		row += 1
	draw_line(Vector2(0, fy), Vector2(w, fy), OUT, 4.0)
	_draw_board(Rect2(w * 0.24, h * 0.05, w * 0.52, h * 0.30))
	_draw_window(Rect2(w * 0.04, h * 0.07, w * 0.14, h * 0.25))
	_draw_clock(Vector2(w * 0.88, h * 0.16), h * 0.07)
	_draw_garland(w, h)


func _draw_board(r: Rect2) -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("4f8a76")
	frame.border_color = Color("b07a4a")
	frame.set_border_width_all(10)
	frame.set_corner_radius_all(14)
	frame.shadow_color = Color(0, 0, 0, 0.18)
	frame.shadow_size = 8
	draw_style_box(frame, r)
	var font := get_theme_default_font()
	draw_string(font, r.position + Vector2(0, r.size.y * 0.62), board_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(r.size.y * 0.55), Color("fffbe8"))
	draw_line(r.position + Vector2(r.size.x * 0.12, r.size.y * 0.86), r.position + Vector2(r.size.x * 0.4, r.size.y * 0.86), Color(1, 1, 1, 0.55), 4.0)
	draw_rect(Rect2(r.position.x + r.size.x * 0.1, r.end.y + 2, r.size.x * 0.8, 10), Color("b07a4a"))
	draw_rect(Rect2(r.position.x + r.size.x * 0.7, r.end.y - 6, 26, 8), Color("fffbe8"))  # tiza


func _draw_window(r: Rect2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("bfe3f5")
	sb.border_color = Color("b07a4a")
	sb.set_border_width_all(8)
	sb.set_corner_radius_all(10)
	draw_style_box(sb, r)
	draw_line(r.position + Vector2(r.size.x * 0.5, 4), r.position + Vector2(r.size.x * 0.5, r.size.y - 4), Color("b07a4a"), 6.0)
	draw_line(r.position + Vector2(4, r.size.y * 0.5), r.position + Vector2(r.size.x - 4, r.size.y * 0.5), Color("b07a4a"), 6.0)
	draw_circle(r.position + Vector2(r.size.x * 0.3, r.size.y * 0.3), r.size.x * 0.12, Color(1, 1, 1, 0.85))
	draw_rect(Rect2(r.position.x - 10, r.position.y - 6, 18, r.size.y + 12), Color("ffb3cc"))
	draw_rect(Rect2(r.end.x - 8, r.position.y - 6, 18, r.size.y + 12), Color("ffb3cc"))


func _draw_clock(c: Vector2, rad: float) -> void:
	draw_circle(c, rad + 6.0, OUT)
	draw_circle(c, rad, Color("fffaf0"))
	var now := Time.get_time_dict_from_system()
	var m := float(now["minute"]) / 60.0 * TAU - PI / 2.0
	var hr := (float(now["hour"] % 12) + float(now["minute"]) / 60.0) / 12.0 * TAU - PI / 2.0
	draw_line(c, c + Vector2(cos(m), sin(m)) * rad * 0.8, OUT, 4.0, true)
	draw_line(c, c + Vector2(cos(hr), sin(hr)) * rad * 0.5, OUT, 6.0, true)
	draw_circle(c, 5.0, Color("ff7aa8"))


func _draw_garland(w: float, h: float) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var x := w * i / 24.0
		pts.append(Vector2(x, 8.0 + sin(float(i) / 24.0 * PI) * 26.0))
	draw_polyline(pts, OUT, 3.0, true)
	var cols := [Color("ff7aa8"), Color("ffcf3f"), Color("5bb8f5"), Color("7bd389"), Color("a98bea")]
	for i in range(1, 24, 2):
		var p := pts[i]
		draw_colored_polygon(PackedVector2Array([p + Vector2(-12, 0), p + Vector2(12, 0), p + Vector2(0, 28)]), cols[(i / 2) % cols.size()])


## Pupitres, cuadernos y la señal del examen (por delante de los alumnos).
func _draw_front(cv: Control) -> void:
	var sb := student_box()
	for i in 2:
		var cx := student_center(i)
		var top := base_y() - sb.y * 0.30
		var dw := minf(sb.x * 1.2, size.x * 0.37)
		var desk := Rect2(cx - dw * 0.5, top, dw, sb.y * 0.14)
		var s := StyleBoxFlat.new()
		s.bg_color = Color("e9a76c")
		s.border_color = OUT
		s.set_border_width_all(5)
		s.set_corner_radius_all(16)
		s.shadow_color = Color(0, 0, 0, 0.18)
		s.shadow_size = 6
		cv.draw_style_box(s, desk)
		cv.draw_rect(Rect2(desk.position.x + 16, desk.end.y, 14, sb.y * 0.2), Color("b8793f"))
		cv.draw_rect(Rect2(desk.end.x - 30, desk.end.y, 14, sb.y * 0.2), Color("b8793f"))
		cv.draw_line(Vector2(desk.position.x + 23, desk.end.y), Vector2(desk.position.x + 23, desk.end.y + sb.y * 0.2), OUT, 3.0)
		cv.draw_line(Vector2(desk.end.x - 23, desk.end.y), Vector2(desk.end.x - 23, desk.end.y + sb.y * 0.2), OUT, 3.0)
		# cuaderno abierto y lapiz
		var nb := Rect2(cx - 38, top - 18, 76, 30)
		cv.draw_colored_polygon(PackedVector2Array([nb.position + Vector2(0, 6), nb.position + Vector2(38, 0), nb.position + Vector2(76, 6), nb.end + Vector2(0, 4), nb.position + Vector2(38, 36), nb.position + Vector2(0, nb.size.y + 4)]), Color("fffdf6"))
		cv.draw_line(nb.position + Vector2(38, 0), nb.position + Vector2(38, 34), OUT, 2.0)
		cv.draw_line(cv.size * 0.0 + Vector2(cx + 50, top - 6), Vector2(cx + 82, top + 10), Color("ff9b54"), 8.0, true)
	# la señal sobre el alumno que levanto la mano
	if hand_student >= 0:
		var r := bubble_rect()
		var pulse := 1.0 + 0.05 * sin(_t * 8.0)
		var c := r.get_center()
		var rr := Rect2(c - r.size * 0.5 * pulse, r.size * pulse)
		var bubble := StyleBoxFlat.new()
		bubble.bg_color = Color("fffdf6")
		bubble.border_color = Color("ff4f86")
		bubble.set_border_width_all(6)
		bubble.set_corner_radius_all(30)
		bubble.shadow_color = Color(0.5, 0.1, 0.25, 0.3)
		bubble.shadow_size = 10
		cv.draw_style_box(bubble, rr)
		cv.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 14, rr.end.y - 3), Vector2(c.x + 14, rr.end.y - 3), Vector2(c.x, rr.end.y + 22)]), Color("ff4f86"))
		cv.draw_colored_polygon(PackedVector2Array([Vector2(c.x - 8, rr.end.y - 4), Vector2(c.x + 8, rr.end.y - 4), Vector2(c.x, rr.end.y + 12)]), Color("fffdf6"))
		# hoja de examen con un signo de admiracion
		var pr := Rect2(c.x - 50, c.y - 38, 50, 66)
		cv.draw_rect(pr, Color("ffffff"))
		cv.draw_rect(pr, OUT, false, 3.0)
		for k in 4:
			cv.draw_line(pr.position + Vector2(8, 14 + k * 12), pr.position + Vector2(pr.size.x - 8, 14 + k * 12), Color("c9c2b8"), 3.0)
		var font := get_theme_default_font()
		cv.draw_string(font, c + Vector2(4, 24), "!", HORIZONTAL_ALIGNMENT_CENTER, 50, 88, Color("ff4f86"))
	# nombre de cada alumno en su pupitre
	var font2 := get_theme_default_font()
	for i in 2:
		var cx2 := student_center(i)
		var plate := Rect2(cx2 - 52, base_y() - sb.y * 0.30 + sb.y * 0.16 - 2, 104, 32)
		var ps := StyleBoxFlat.new()
		ps.bg_color = Color("fffdf6")
		ps.border_color = OUT
		ps.set_border_width_all(3)
		ps.set_corner_radius_all(12)
		cv.draw_style_box(ps, plate)
		cv.draw_string(font2, plate.position + Vector2(0, 24), student_names[i], HORIZONTAL_ALIGNMENT_CENTER, plate.size.x, 20, OUT)
