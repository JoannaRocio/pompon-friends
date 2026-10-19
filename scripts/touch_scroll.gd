extends Node
## Deslizar las listas con el dedo (autoload TouchScroll). El arrastre propio de Godot solo empieza si
## el dedo cae en una parte "libre" de la lista: si cae sobre un boton (por ejemplo "Comprar" en la
## tienda), el boton se queda con el toque y la lista no se mueve. Esto lo maneja para TODAS las listas
## del juego (cualquier ScrollContainer, aunque aparezca despues):
## - el dedo puede empezar sobre cualquier cosa de la lista;
## - pasada una zona muerta chiquita, la lista sigue al dedo y el boton que se toco se suelta (asi no se
##   compra nada sin querer);
## - al soltar sigue con inercia y frena de a poco;
## - si hay una ventana encima (un cartel), no mueve la lista de abajo.
## Solo en pantallas tactiles (en la PC queda la rueda del mouse). `force` lo prende para las pruebas.

const DEADZONE := 14.0       # px que hay que mover el dedo para que cuente como deslizar
const FRICTION := 0.02       # cuanto queda de la velocidad despues de un segundo de inercia
const MIN_SPEED := 30.0
const MAX_SPEED := 2600.0     # px por segundo como mucho al soltar
const FAR := Vector2(-9999, -9999)   # donde se "suelta" el boton que se estaba apretando

var force := false
var _scrolls: Array = []
var _active: ScrollContainer
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _dragging := false
var _axis := Vector2.ZERO    # (0, 1) vertical o (1, 0) horizontal
var _vel := Vector2.ZERO
var _fling: ScrollContainer
var _rest := Vector2.ZERO     # fraccion de pixel que falta aplicar (el scroll es entero)
var _last_t := 0


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func enabled() -> bool:
	return force or DisplayServer.is_touchscreen_available()


func _on_node_added(n: Node) -> void:
	if n is ScrollContainer:
		_scrolls.append(n)
		if enabled():   # (el arrastre propio se peleaba con este)
			(n as ScrollContainer).mouse_filter = Control.MOUSE_FILTER_IGNORE


## ¿Se puede deslizar en ese eje?
static func _can_scroll(s: ScrollContainer, axis: Vector2) -> bool:
	if axis.y != 0.0:
		var vb := s.get_v_scroll_bar()
		return s.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and vb.max_value - vb.page > 1.0
	var hb := s.get_h_scroll_bar()
	return s.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED and hb.max_value - hb.page > 1.0


## La lista mas de adentro que esta bajo el dedo.
func _find(pos: Vector2) -> ScrollContainer:
	var best: ScrollContainer = null
	_scrolls = _scrolls.filter(func(s): return is_instance_valid(s))
	for s: ScrollContainer in _scrolls:
		if s.is_visible_in_tree() and s.get_global_rect().has_point(pos):
			if best == null or best.is_ancestor_of(s):
				best = s
	return best


func _input(event: InputEvent) -> void:
	if not enabled():
		return
	# mientras se desliza, los botones no reciben el toque (el mouse que Godot arma con el dedo)
	if _dragging and event is InputEventMouse and (event as InputEventMouse).position.x > FAR.x + 1.0:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_fling = null
			_vel = Vector2.ZERO
			_active = _find(event.position)
			_start = event.position
			_last = event.position
			_dragging = false
			_last_t = Time.get_ticks_msec()
		else:
			if _dragging and _active != null and _vel.length() > MIN_SPEED:
				_vel = _vel.limit_length(MAX_SPEED)
				_fling = _active   # sigue sola un poquito
			_dragging = false
			_active = null
	elif event is InputEventScreenDrag and event.index == 0 and _active != null:
		var pos: Vector2 = event.position
		var delta := pos - _last
		_last = pos
		var now := Time.get_ticks_msec()
		var dt := maxf((now - _last_t) / 1000.0, 0.001)
		_last_t = now
		if not _dragging:
			var moved := pos - _start
			if moved.length() < DEADZONE:
				return
			_axis = Vector2(0, 1) if absf(moved.y) >= absf(moved.x) else Vector2(1, 0)
			if not _can_scroll(_active, _axis) or not _over_list(_active):
				_active = null
				return
			_dragging = true
			_release_buttons()
			delta = moved   # lo que ya se movio dentro de la zona muerta tambien cuenta
		_move(_active, delta)
		_vel = _vel.lerp(delta / dt, 0.5)
		get_viewport().set_input_as_handled()


## ¿El dedo esta sobre la lista (y no sobre una ventana que la tapa)?
func _over_list(s: ScrollContainer) -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered == null or hovered == s or s.is_ancestor_of(hovered)


## Suelta el boton que se estaba apretando: el "mouse" se va lejos y se suelta alli (asi el boton
## entiende que el dedo salio de el y no se activa).
func _release_buttons() -> void:
	var away := InputEventMouseMotion.new()
	away.position = FAR
	away.global_position = FAR
	away.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(away)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = FAR
	up.global_position = FAR
	Input.parse_input_event(up)


func _move(s: ScrollContainer, delta: Vector2) -> void:
	_rest += -delta * _axis
	var step := Vector2(roundf(_rest.x), roundf(_rest.y))
	_rest -= step
	if _axis.y != 0.0:
		s.scroll_vertical += int(step.y)
	else:
		s.scroll_horizontal += int(step.x)


func _process(delta: float) -> void:
	if _fling == null:
		return
	if not is_instance_valid(_fling) or not _fling.is_visible_in_tree():
		_fling = null
		return
	_move(_fling, _vel * delta)
	_vel *= pow(FRICTION, delta)
	if _vel.length() < MIN_SPEED:
		_fling = null
