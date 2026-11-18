class_name GuideArrow
extends Control
## Flecha rosa que rebota y señala el boton que hay que tocar ahora (guia para ninos).
## Se pone encima del boton y apunta hacia abajo; sin objetivo se esconde. Con varios objetivos
## (`set_targets`) va pasando de uno a otro: "cualquiera de estos". Si el boton esta pegado arriba
## (no hay lugar encima), en vez de una flecha que taparia lo de abajo, un anillo que late alrededor
## del boton (`ring` lo fuerza, por ejemplo cuando arriba del boton hay un texto). Con `prefer_below`
## la flecha va debajo y apunta hacia arriba.

const COLOR := Color("ff4f86")

var target: Control = null
var targets: Array = []     # varios botones: la flecha los recorre
var period := 1.4           # segundos en cada uno
var _t := 0.0
var _placed := false
var _up := false             # debajo del boton, apuntando hacia arriba
var prefer_below := false    # ponerla debajo aunque haya lugar arriba (si arriba tapa otro boton)
var ring := false            # anillo que late alrededor del boton en vez de flecha (no tapa nada)
var _ring := false           # (en uso ahora: forzado o porque arriba no hay lugar)
const RING_PAD := 12.0
const ARROW_SIZE := Vector2(84, 104)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = ARROW_SIZE
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
	_ring = ring or (not prefer_below and r.position.y - parent_origin.y < ARROW_SIZE.y)
	if _ring:   # alrededor del boton
		size = r.size + Vector2.ONE * RING_PAD * 2.0
		position = r.position - parent_origin - Vector2.ONE * RING_PAD
		if position.y < 2.0:   # pegado al borde de la pantalla: el anillo no se corta arriba
			size.y -= 2.0 - position.y
			position.y = 2.0
		_placed = false
		queue_redraw()
		return
	size = ARROW_SIZE
	var up := prefer_below
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
	if _ring:
		_draw_ring()
		return
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


## Anillo rosa con borde blanco que late (se agranda y achica) alrededor del boton.
func _draw_ring() -> void:
	var beat := absf(sin(_t * 4.2))
	var grow := beat * 6.0
	var r := Rect2(Vector2.ONE * (4.0 - grow), size - Vector2.ONE * (8.0 - grow * 2.0))
	var radius := int(minf(r.size.x, r.size.y) * 0.5)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	sb.set_border_width_all(12)
	sb.border_color = Color.WHITE
	draw_style_box(sb, r)
	var inner := StyleBoxFlat.new()
	inner.draw_center = false
	inner.set_corner_radius_all(maxi(radius - 3, 0))
	inner.anti_aliasing = true
	inner.set_border_width_all(7)
	inner.border_color = Color(COLOR, 0.75 + 0.25 * beat)
	draw_style_box(inner, r.grow(-3.0))
