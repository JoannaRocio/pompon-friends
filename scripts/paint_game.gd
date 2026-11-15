extends MiniGameBase
## Minijuego "Pintar": un lienzo de pixel art de 16 x 16. Se pinta tocando o arrastrando el dedo, con
## lapiz o balde de pintura. Las estrellas de arriba se llenan mientras mas se pinta. Al terminar el
## dibujo se guarda y se puede colgar en el cuarto o regalar a un amigo de verdad (le llega a su juego).
## Entrena la Creatividad del Pompon.

const STAR_STEPS := [12, 30, 55, 85, 120]   # cuadritos pintados para cada estrella
const MIN_PAINTED := 12

var px := PixelArt.blank()
var color := 2                  # color elegido (indice de PixelArt.PALETTE)
var tool := "pen"               # "pen" o "fill"
var saved_id := ""
var canvas: Control
var _swatches: Array = []
var _tool_buttons := {}
var _stars_done := 0
var _painting := false
var _notice: BigNotice


func _ready() -> void:
	game_id = "paint"
	_build_chrome(Color("fff0f6"), STAR_STEPS.size(), 2)
	_pet.visible = false   # aca el lienzo usa todo el lugar
	content.offset_bottom = -24
	content.offset_top = 112
	content.add_theme_constant_override("separation", 16)

	canvas = Control.new()
	canvas.custom_minimum_size = Vector2(624, 624)
	canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	canvas.draw.connect(_draw_canvas)
	canvas.gui_input.connect(_on_canvas_input)
	content.add_child(canvas)

	var palette := GridContainer.new()
	palette.columns = 8
	palette.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	palette.add_theme_constant_override("h_separation", 10)
	palette.add_theme_constant_override("v_separation", 10)
	content.add_child(palette)
	for i in PixelArt.PALETTE.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(66, 54)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_pick_color.bind(i))
		palette.add_child(b)
		_swatches.append(b)

	var tools := HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 12)
	content.add_child(tools)
	for spec in [["pen", T.s("Lápiz")], ["fill", T.s("Balde")]]:
		var t := Button.new()
		t.text = spec[1]
		t.custom_minimum_size = Vector2(150, 72)
		t.focus_mode = Control.FOCUS_NONE
		t.pressed.connect(_pick_tool.bind(spec[0]))
		tools.add_child(t)
		_tool_buttons[spec[0]] = t
	var clear := Button.new()
	clear.text = T.s("Borrar")
	clear.custom_minimum_size = Vector2(140, 72)
	clear.focus_mode = Control.FOCUS_NONE
	Hud.style_soft(clear, 26)
	clear.pressed.connect(func():
		px = PixelArt.blank()
		canvas.queue_redraw())
	tools.add_child(clear)
	var done := Button.new()
	done.text = T.s("¡Listo!")
	done.custom_minimum_size = Vector2(170, 72)
	done.focus_mode = Control.FOCUS_NONE
	Hud.style_primary(done, 30, Color("5fc77f"))
	done.pressed.connect(_finish)
	tools.add_child(done)
	_pick_color(2)
	_pick_tool("pen")


func _pick_color(i: int) -> void:
	color = i
	for k in _swatches.size():
		var sb := StyleBoxFlat.new()
		sb.bg_color = PixelArt.PALETTE[k]
		sb.set_corner_radius_all(16)
		sb.border_color = Color("d6336c") if k == color else Color("5b3a4a")
		sb.set_border_width_all(7 if k == color else 3)
		for st in ["normal", "hover", "pressed", "focus"]:
			_swatches[k].add_theme_stylebox_override(st, sb)


func _pick_tool(t: String) -> void:
	tool = t
	for key in _tool_buttons:
		if key == t:
			Hud.style_primary(_tool_buttons[key], 28, Color("a98bea"))
		else:
			Hud.style_soft(_tool_buttons[key], 28)


func _draw_canvas() -> void:
	var r := Rect2(Vector2.ZERO, canvas.size)
	PixelArt.draw_pixels(canvas, r, px)
	var cell := canvas.size.x / PixelArt.SIZE
	for i in range(1, PixelArt.SIZE):   # cuadricula suave
		var line_col := Color(0.36, 0.23, 0.29, 0.12 if i % 4 != 0 else 0.25)
		canvas.draw_line(Vector2(i * cell, 0), Vector2(i * cell, canvas.size.y), line_col, 1.5)
		canvas.draw_line(Vector2(0, i * cell), Vector2(canvas.size.x, i * cell), line_col, 1.5)
	canvas.draw_rect(r, Color("5b3a4a"), false, 5.0)


func _cell_at(pos: Vector2) -> Vector2i:
	var cell := canvas.size.x / PixelArt.SIZE
	return Vector2i(int(pos.x / cell), int(pos.y / cell))


func _on_canvas_input(event: InputEvent) -> void:
	if _layer != null or _notice != null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_painting = event.pressed
		if event.pressed:
			paint_at(_cell_at(event.position))
	elif event is InputEventMouseMotion and _painting and tool == "pen":
		paint_at(_cell_at(event.position))


## Pinta (o rellena) el cuadrito `c`.
func paint_at(c: Vector2i) -> void:
	if c.x < 0 or c.y < 0 or c.x >= PixelArt.SIZE or c.y >= PixelArt.SIZE:
		return
	var before := px
	px = PixelArt.fill(px, c.x, c.y, color) if tool == "fill" else PixelArt.set_pixel(px, c.x, c.y, color)
	if px == before:
		return
	Audio.play("click", randf_range(1.1, 1.4))
	canvas.queue_redraw()
	_update_stars()


## Las estrellas se llenan mientras mas se pinta.
func _update_stars() -> void:
	var count := PixelArt.painted(px)
	while _stars_done < STAR_STEPS.size() and count >= STAR_STEPS[_stars_done]:
		_stars_done += 1
		_mark(true)


func _finish() -> void:
	if _notice != null or _layer != null:
		return
	if PixelArt.painted(px) < MIN_PAINTED:
		_message(T.s("¡Pinta un poquito más!"), T.s("Llena algunos cuadritos con colores."))
		return
	saved_id = GameState.add_painting(px)
	_notice = BigNotice.new(640.0)
	add_child(_notice)
	_notice.closed.connect(func(): _notice = null)
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(0, 220)
	preview.draw.connect(func():
		PixelArt.draw_framed(preview, saved_id, Rect2(Vector2(preview.size.x * 0.5 - 95.0, 0), Vector2(190, 210))))
	_notice.add(preview)
	_notice.title(T.s("¡Qué lindo dibujo!"))
	_notice.button(T.s("Colgar en mi cuarto"), func():
		_notice.close()
		GameState.hang_painting(saved_id)
		_done(T.s("¡Quedó colgado en tu cuarto!")), true, Color("5fc77f"))
	_notice.button(T.s("Regalar a un amigo"), func():
		_notice.close()
		_pick_friend(), true, Color("ff7aa8"))
	_notice.button(T.s("Guardar"), func():
		_notice.close()
		_done(T.s("Lo puedes colgar cuando quieras en Decorar.")), false)


## Elegir a que amigo de verdad regalarselo.
func _pick_friend() -> void:
	_notice = BigNotice.new(640.0)
	add_child(_notice)
	_notice.closed.connect(func(): _notice = null)
	_notice.title(T.s("¿A quién se lo regalas?"), Color("d6336c"))
	if not Friends.is_active() or GameState.friends.is_empty():
		_notice.text_line(T.s("Todavía no tienes amigos de verdad. Agrégalos con su código en Vecinos."), 26)
		_notice.button(T.s("Colgar en mi cuarto"), func():
			_notice.close()
			GameState.hang_painting(saved_id)
			_done(T.s("¡Quedó colgado en tu cuarto!")), true, Color("5fc77f"))
		_notice.button(T.s("Guardar"), func():
			_notice.close()
			_done(T.s("Lo puedes colgar cuando quieras en Decorar.")), false)
		return
	for f in GameState.friends:
		var code: String = f["code"]
		_notice.button(Friends.display_name(f), func():
			_notice.close()
			_send(code, Friends.display_name(f)), true, Color("ff9ec0"))
	_notice.button(T.s("Mejor no"), func():
		_notice.close()
		_done(T.s("Lo puedes colgar cuando quieras en Decorar.")), false)


func _send(code: String, who: String) -> void:
	var res: Dictionary = await Friends.send_art(code, px)
	if not is_inside_tree():
		return
	var text: String = {
		"ok": T.s("¡Le mandaste tu dibujo a %s! Le va a llegar a su juego.") % who,
		"limit": Friends.limit_text("art", "limit", who),
		"not_friends": T.s("Ya no son amigos."),
		"off": T.s("Para regalar dibujos hay que activar los amigos en Vecinos."),
	}.get(res["result"], T.s("No se pudo enviar. Revisa la conexión a internet."))
	_done(text)


## Muestra un aviso y despues la tarjeta de premios.
func _done(text: String) -> void:
	_message(T.s("¡Listo!"), text, func(): _show_result(T.s("¡Gran artista!"), _stars_done, STAR_STEPS.size()))


func _message(title: String, text: String, after := Callable()) -> void:
	_notice = BigNotice.new(600.0)
	add_child(_notice)
	_notice.closed.connect(func(): _notice = null)
	_notice.title(title, Color("d6336c"))
	_notice.text_line(text, 28)
	_notice.button(T.s("¡Bien!"), func():
		_notice.close()
		if after.is_valid():
			after.call())
