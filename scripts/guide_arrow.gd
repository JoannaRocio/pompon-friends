class_name GuideArrow
extends Control
## Flecha rosa que rebota y señala el boton que hay que tocar ahora (guia para ninos).
## Se pone encima del boton y apunta hacia abajo; sin objetivo se esconde. Con varios objetivos
## (`set_targets`) va pasando de uno a otro: "cualquiera de estos". Si el boton esta pegado arriba
## (no hay lugar encima), la flecha se pone debajo y apunta hacia arriba.

const COLOR := Color("ff4f86")

var target: Control = null
var targets: Array = []     # varios botones: la flecha los recorre
var period := 1.4           # segundos en cada uno
var _t := 0.0
var _placed := false
var _up := false             # debajo del boton, apuntando hacia arriba
var prefer_below := false    # ponerla debajo aunque haya lugar arriba (si arriba tapa otro boton)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(84, 104)
	size = Vector2(84, 104)
	visible = false
	z_index = 20


func set_target(node: Control) -> void:
	if node == target and targets.is_empty():
		return
	targets = []
	target = node
	_placed = false
	visible = node != null and node.is_visible_in_tree()


func set_targets(nodes: Array) -> void:
	if nodes == targets:
		return
	targets = nodes
	target = nodes[0] if not nodes.is_empty() else null
	_placed = false
	visible = target != null and target.is_visible_in_tree()


func _process(delta: float) -> void:
	_t += delta
	if targets.size() > 1:
		target = targets[int(_t / period) % targets.size()]
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		visible = false
		return
	visible = true
	var r := target.get_global_rect()
	var parent_origin := (get_parent() as Control).global_position if get_parent() is Control else Vector2.ZERO
	var bob := absf(sin(_t * 4.2)) * 18.0
	var up := prefer_below or r.position.y - parent_origin.y < size.y
	if up != _up:
		_up = up
		_placed = false
	var goal := r.position - parent_origin + Vector2(r.size.x * 0.5 - size.x * 0.5, -size.y + 4.0 - bob + 6.0)
	if _up:
		goal = Vector2(goal.x, r.end.y - parent_origin.y - 10.0 + bob)
	# al cambiar de objetivo se desliza (no salta)
	position = goal if not _placed else position.lerp(goal, minf(1.0, delta * 10.0))
	_placed = true
	queue_redraw()


func _draw() -> void:
	if _up:  # espejada: la punta mira hacia arriba
		draw_set_transform(Vector2(0, size.y), 0.0, Vector2(1, -1))
	var c := size.x * 0.5
	# sombra
	var pts := _arrow_points(Vector2(c, 0), 4.0)
	draw_colored_polygon(pts, Color(0.36, 0.1, 0.2, 0.25))
	var outline := _arrow_points(Vector2(c, 0), 0.0)
	draw_colored_polygon(outline, Color.WHITE)
	var inner := _arrow_inner(Vector2(c, 0))
	draw_colored_polygon(inner, COLOR)
	draw_circle(Vector2(c - 8, 22), 7.0, Color(1, 1, 1, 0.35))


## Flecha hacia abajo: tallo y punta. `grow` la engorda (borde blanco / sombra).
func _arrow_points(top: Vector2, shift: float) -> PackedVector2Array:
	var g := 7.0
	return PackedVector2Array([
		top + Vector2(-17 - g, 8 + shift - g), top + Vector2(17 + g, 8 + shift - g), top + Vector2(17 + g, 52 + shift),
		top + Vector2(36 + g, 52 + shift), top + Vector2(0, 98 + shift + g), top + Vector2(-36 - g, 52 + shift), top + Vector2(-17 - g, 52 + shift)])


func _arrow_inner(top: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		top + Vector2(-17, 8), top + Vector2(17, 8), top + Vector2(17, 52), top + Vector2(34, 52),
		top + Vector2(0, 90), top + Vector2(-34, 52), top + Vector2(-17, 52)])
