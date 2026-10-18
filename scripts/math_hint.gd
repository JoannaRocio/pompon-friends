class_name MathHint
extends Control
## Dibuja puntitos para entender una cuenta (se muestra cuando el nino se equivoca):
## sumas = dos colores juntos, restas = puntos tachados, multiplicaciones = filas y columnas,
## divisiones = grupos iguales.

const MAX_ADD := 40
const MAX_SUB := 40
const MAX_DIV := 60

var problem := {}


## Hay dibujo para esta cuenta? (si los numeros son muy grandes no se dibuja)
static func can_draw(p: Dictionary) -> bool:
	var a: int = p.get("a", 0)
	var b: int = p.get("b", 0)
	match p.get("op", ""):
		"add":
			return a + b <= MAX_ADD
		"sub":
			return a <= MAX_SUB
		"mul":
			return mini(a, b) <= 10 and maxi(a, b) <= 10
		"div":
			return a <= MAX_DIV and b <= 9
	return false


func show_problem(p: Dictionary) -> void:
	problem = p
	queue_redraw()


func _dot(c: Vector2, r: float, color: Color, crossed := false) -> void:
	draw_circle(c, r, color)
	draw_arc(c, r, 0.0, TAU, 14, Color("5b3a4a"), maxf(1.5, r * 0.18), true)
	if crossed:
		draw_line(c + Vector2(-r, -r) * 0.8, c + Vector2(r, r) * 0.8, Color("c0392b"), maxf(2.0, r * 0.3), true)
		draw_line(c + Vector2(r, -r) * 0.8, c + Vector2(-r, r) * 0.8, Color("c0392b"), maxf(2.0, r * 0.3), true)


func _draw() -> void:
	if problem.is_empty() or not can_draw(problem):
		return
	var a: int = problem["a"]
	var b: int = problem["b"]
	match problem["op"]:
		"add":
			_draw_flow(a + b, func(i: int) -> Array: return [Color("ff9b54") if i < a else Color("5aa9e6"), false])
		"sub":
			_draw_flow(a, func(i: int) -> Array: return [Color("6bbf7a") if i < a - b else Color("d5d0cc"), i >= a - b])
		"mul":
			var rows := mini(a, b)
			var cols := maxi(a, b)
			_draw_grid(rows, cols)
		"div":
			_draw_groups(b, problem["answer"])


## Puntos en filas de hasta 10.
func _draw_flow(total: int, style: Callable) -> void:
	var per_row := 10
	var rows := int(ceil(float(total) / per_row))
	var r := minf(size.x / (per_row * 2.5), size.y / (rows * 2.5))
	var step := r * 2.5
	var width := minf(total, per_row) * step
	var origin := Vector2((size.x - width) * 0.5 + step * 0.5, (size.y - rows * step) * 0.5 + step * 0.5)
	for i in total:
		var s: Array = style.call(i)
		_dot(origin + Vector2((i % per_row) * step, (i / per_row) * step), r, s[0], s[1])


func _draw_grid(rows: int, cols: int) -> void:
	var r := minf(size.x / (cols * 2.5), size.y / (rows * 2.5))
	var step := r * 2.5
	var origin := Vector2((size.x - cols * step) * 0.5 + step * 0.5, (size.y - rows * step) * 0.5 + step * 0.5)
	var colors := [Color("ff8fc8"), Color("b388f5")]
	for y in rows:
		for x in cols:
			_dot(origin + Vector2(x * step, y * step), r, colors[y % 2])


func _draw_groups(groups: int, per_group: int) -> void:
	var gcols := mini(groups, 4)
	var grows := int(ceil(float(groups) / gcols))
	var cell := Vector2(size.x / gcols, size.y / grows)
	var colors := [Color("ff9b54"), Color("5aa9e6"), Color("6bbf7a"), Color("ff8fc8"), Color("b388f5")]
	for g in groups:
		var box := Rect2(Vector2((g % gcols) * cell.x, (g / gcols) * cell.y) + Vector2(4, 4), cell - Vector2(8, 8))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.7)
		sb.border_color = Color("e3c9a6")
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(14)
		draw_style_box(sb, box)
		var per_row := mini(per_group, 5)
		var rows := int(ceil(float(per_group) / per_row))
		var r := minf(box.size.x / (per_row * 2.6), box.size.y / (rows * 2.6))
		var step := r * 2.6
		var origin := box.position + Vector2((box.size.x - per_row * step) * 0.5 + step * 0.5, (box.size.y - rows * step) * 0.5 + step * 0.5)
		for i in per_group:
			_dot(origin + Vector2((i % per_row) * step, (i / per_row) * step), r, colors[g % colors.size()])
