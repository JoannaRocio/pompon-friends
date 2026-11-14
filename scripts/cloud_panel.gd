class_name CloudPanel
extends BigNotice
## Cartel de la nube (se abre desde el menu): guardar la partida y ver su codigo, o recuperar una
## partida con un codigo en otro dispositivo. Poco texto y un paso por vez.

signal restored   # se recupero una partida: el menu entra al juego

var _code_edit: LineEdit
var _go: Button
var _note: Label


func _ready() -> void:
	super()
	_show_main()


func _clear() -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	_code_edit = null
	_go = null
	_note = null


func _has_progress() -> bool:
	return GameState.pompon != null or GameState.has_profile() or GameState.jobs_done > 0


## Pantalla principal: el codigo (o el boton para crearlo) y "Recuperar con un codigo".
func _show_main(message := "") -> void:
	_clear()
	title("Guardar en la nube", Color("3f66b0"))
	if not Cloud.is_configured():
		text_line("Muy pronto vas a poder guardar tu partida en la nube.", 28)
		button("Volver", close, false)
		return
	if Cloud.conflict:
		_show_conflict()
		return
	if message != "":
		text_line(message, 28, Color("2f9e6e"))
	if _has_progress():
		if Cloud.has_code():
			text_line("Tu código", 26, Color("a0527a"))
			add(_code_box(CloudCode.format_code(GameState.cloud_code)))
			text_line("Anótalo: con él recuperas tu partida en otro celular o tablet. Se guarda sola.", 24)
			button("Guardar ahora", _save_now, true, Color("5bb8f5"))
		else:
			text_line("Guarda tu partida para recuperarla en otro celular o tablet.", 28)
			button("Guardar en la nube", _save_now, true, Color("5bb8f5"))
	else:
		text_line("¿Ya jugabas en otro dispositivo? Recupera tu partida con su código.", 28)
	button("Recuperar con un código", _show_enter, not _has_progress(), Color("5fc77f"))
	button("Volver", close, false)


func _code_box(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Hud.card(Color("eef5ff"), 26, Color("a9c8f0"), 4, 0))
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 50)
	l.add_theme_color_override("font_color", Color("2d4f8f"))
	panel.add_child(l)
	return panel


func _busy(text := "Un momento…") -> void:
	_clear()
	title("Guardar en la nube", Color("3f66b0"))
	text_line(text, 30)


func _save_now() -> void:
	_busy("Guardando…")
	var res: Dictionary = await Cloud.upload()
	if not is_inside_tree():
		return
	if res["ok"]:
		_show_main("¡Guardado!")
	elif res["error"] == "conflict":
		_show_main()
	else:
		_show_error(res["error"], _show_main)


## Escribir el codigo de otra partida.
func _show_enter() -> void:
	_clear()
	title("Recuperar partida", Color("2f9e6e"))
	text_line("Escribe el código de tu partida.", 28)
	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = "ABCD-EFGH-JKLM"
	_code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_edit.max_length = 16
	_code_edit.custom_minimum_size = Vector2(0, 86)
	_code_edit.add_theme_font_size_override("font_size", 40)
	var sb := Hud.card(Color("fffdfb"), 30, Color("a9e0c0"), 4, 0)
	_code_edit.add_theme_stylebox_override("normal", sb)
	_code_edit.add_theme_stylebox_override("focus", Hud.card(Color("fffdfb"), 30, Color("5fc77f"), 5, 0))
	_code_edit.text_changed.connect(func(t: String):
		# se ordena solo mientras escribe: mayusculas y guiones cada 4 (ABCD-EFGH-JKLM)
		var shown := CloudCode.format_code(CloudCode.normalize(t).left(CloudCode.CODE_LEN))
		if shown != t:
			_code_edit.text = shown
			_code_edit.caret_column = shown.length()
		_go.disabled = CloudCode.clean_code(shown) == "")
	add(_code_edit)
	if _has_progress():
		text_line("La partida de este dispositivo se reemplaza.", 22, Color("e0295f"))
	_go = button("Recuperar", _restore, true, Color("5fc77f"))
	_go.disabled = true
	button("Volver", _show_main, false)
	_code_edit.grab_focus.call_deferred()


func _restore() -> void:
	var code := _code_edit.text
	_busy("Buscando tu partida…")
	var res: Dictionary = await Cloud.restore(code)
	if not is_inside_tree():
		return
	if res["ok"]:
		_clear()
		title("¡Tu partida volvió!", Color("2f9e6e"))
		if GameState.pompon != null and GameState.pompon.hatched:
			text_line(T.s("%s te estaba esperando.") % GameState.pompon.display_name(), 30)
		button("¡A jugar!", func():
			close()
			restored.emit(), true, Color("5fc77f"))
		Audio.play("success")
	else:
		_show_error(res["error"], _show_enter)


## La misma partida se siguio jugando en otro dispositivo: elegir cual se queda.
func _show_conflict() -> void:
	text_line("Tu partida se siguió jugando en otro dispositivo.", 28)
	text_line("¿Cuál quieres conservar?", 28, Color("a0527a"))
	button("La de la nube", func():
		_busy("Trayendo la partida de la nube…")
		var res: Dictionary = await Cloud.restore(GameState.cloud_code)
		if not is_inside_tree():
			return
		if res["ok"]:
			close()
			restored.emit()
		else:
			_show_error(res["error"], _show_main), true, Color("5bb8f5"))
	button("La de este dispositivo", func():
		_busy("Guardando…")
		var res: Dictionary = await Cloud.upload(true)
		if not is_inside_tree():
			return
		if res["ok"]:
			_show_main("¡Guardado!")
		else:
			_show_error(res["error"], _show_main), false)
	button("Volver", close, false)


func _show_error(error: String, back: Callable) -> void:
	_clear()
	title("¡Ups!", Color("e0295f"))
	var text: String = {
		"network": "No hay conexión a internet. Prueba de nuevo en un ratito.",
		"not_found": "No encontramos ese código. Revisa las letras.",
		"code": "El código tiene 12 letras y números.",
		"off": "La nube todavía no está disponible.",
	}.get(error, "Algo salió mal. Prueba más tarde.")
	_note = text_line(text, 28)
	button("Volver", back, true, Color("ff8fb8"))
