class_name FriendSafety
extends RefCounted
## Ventanas para cuidar a los jugadores con los amigos de verdad (se usan en Vecinos, el pueblo y la
## casa):
## - ask_age: pregunta de edad NEUTRAL (todas las edades iguales, ninguna marcada de antemano). Solo se
##   guarda el grupo: menor de 13, 13 a 17 o adulto.
## - parental_gate: un menor de 13 necesita a un adulto para activar los amigos (una cuenta dificil).
## - friend_options: dejar de ser amigos, bloquear o denunciar.
## - report: denunciar (con el motivo; si es un dibujo, va el dibujo) y ofrecer bloquear.
## - show_received_art: un dibujo que llego: se ve en chiquito y se elige guardarlo o no.

const GREEN := Color("5fc77f")
const PINK := Color("d6336c")


static func _notice(parent: Node, width := 620.0) -> BigNotice:
	var n := BigNotice.new(width)
	parent.add_child(n)
	return n


## Pregunta de edad neutral. `done` recibe el grupo elegido.
static func ask_age(parent: Node, done: Callable) -> BigNotice:
	var n := _notice(parent, 660.0)
	n.title("¿Cuántos años tienes?", Color("7a56c4"))
	n.text_line("Para cuidar tu privacidad con tus amigos.", 24, Color("a0527a"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var options: Array = [["6 o menos", 6]]
	for age in range(7, 18):
		options.append([str(age), age])
	options.append(["18 o más", 18])
	for o in options:
		var b := Button.new()
		b.text = o[0]
		b.custom_minimum_size = Vector2(132, 72)
		b.focus_mode = Control.FOCUS_NONE
		Hud.style_soft(b, 26)
		var age: int = o[1]
		b.pressed.connect(func():
			GameState.age_group = GameState.age_group_for(age)
			GameState.save_game()
			if Friends.is_active():
				Friends.publish()   # (si es menor de 13, su nombre deja de verse)
			n.close()
			done.call(GameState.age_group))
		grid.add_child(b)
	n.add(grid)
	return n


## Control parental: hay que resolver una cuenta de adulto. `done` recibe true si la resolvio.
static func parental_gate(parent: Node, done: Callable) -> BigNotice:
	var n := _notice(parent, 640.0)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var q := [rng.randi_range(13, 19), rng.randi_range(6, 9)]
	n.add(BigNotice.icon_strip([["people", Color("5bb8f5")], ["lock", Color("a98bea")]]))
	n.title("Pídele ayuda a un adulto", PINK)
	n.text_line("Para jugar con amigos de verdad, un adulto tiene que dar permiso.", 26)
	var ask := n.text_line("¿Cuánto es %d × %d?" % q, 40, Color("3f66b0"))
	var edit := LineEdit.new()
	edit.placeholder_text = "Respuesta"
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.custom_minimum_size = Vector2(0, 80)
	edit.add_theme_font_size_override("font_size", 38)
	edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	edit.max_length = 4
	n.add(edit)
	var check := func():
		if edit.text.strip_edges() == str(q[0] * q[1]):
			n.close()
			done.call(true)
		else:   # otra cuenta (asi no se puede probar al azar)
			q[0] = rng.randi_range(13, 19)
			q[1] = rng.randi_range(6, 9)
			ask.text = "Esa no es. ¿Cuánto es %d × %d?" % q
			edit.text = ""
	n.button("Listo", check, true, GREEN)
	n.button("Cancelar", func():
		n.close()
		done.call(false), false)
	return n


## Opciones sobre un amigo de verdad (`entry` con "code" y "name"). `changed` se llama si algo cambio.
static func friend_options(parent: Node, entry: Dictionary, changed := Callable()) -> BigNotice:
	var n := _notice(parent)
	var code: String = entry.get("code", "")
	var who: String = entry.get("name", "tu amigo")
	n.title(who, PINK)
	n.button("Dejar de ser amigos", func():
		n.close()
		_confirm(parent, "¿Dejar de ser amigos?", "%s ya no va a aparecer en tu lista." % who, "Dejar de ser amigos", func():
			await Friends.remove(code)
			_call(changed)), false)
	n.button("Bloquear", func():
		n.close()
		_confirm(parent, "¿Bloquear a %s?" % who, "Deja de ser tu amigo y no te puede mandar solicitudes, visitas ni dibujos.", "Bloquear", func():
			await Friends.block(code)
			_call(changed)), false)
	n.button("Denunciar", func():
		n.close()
		report(parent, code, who, "", changed), false)
	n.button("Cerrar", n.close, false)
	return n


static func _call(c: Callable) -> void:
	if c.is_valid():
		c.call()


static func _confirm(parent: Node, title: String, text: String, yes: String, action: Callable) -> void:
	var n := _notice(parent)
	n.title(title, PINK)
	n.text_line(text, 26)
	n.button("No", n.close, true, GREEN)
	n.button(yes, func():
		n.close()
		action.call(), false)


## Denunciar: se elige el motivo, se manda y despues se ofrece bloquear.
static func report(parent: Node, code: String, who: String, art := "", changed := Callable()) -> BigNotice:
	var n := _notice(parent)
	n.title("¿Qué pasó?", PINK)
	n.text_line("Lo vamos a revisar. Gracias por avisarnos.", 24, Color("a0527a"))
	var reasons: Array = ["art", "name", "other"] if art != "" else ["name", "art", "other"]
	for reason in reasons:
		var send := func():
			n.close()
			var res: Dictionary = await Friends.report(code, reason, art)
			var done := _notice(parent)
			done.title("¡Gracias!" if res["ok"] else "No se pudo enviar", GREEN if res["ok"] else PINK)
			done.text_line("Lo vamos a revisar. Si quieres, también puedes bloquear a %s." % who if res["ok"] else "Revisa la conexión a internet y prueba otra vez.", 26)
			if res["ok"] and not GameState.is_blocked(code):
				done.button("Bloquear", func():
					done.close()
					await Friends.block(code)
					_call(changed), true, PINK)
			done.button("Cerrar", done.close, not res["ok"])
		n.button(Friends.REPORT_REASONS[reason], send, false)
	n.button("Cancelar", n.close, false)
	return n


## Un dibujo que llego (el primero de la fila): se ve en chiquito y se elige guardarlo, no o denunciar.
static func show_received_art(parent: Node, closed := Callable()) -> BigNotice:
	if GameState.pending_art.is_empty():
		return null
	var art: Dictionary = GameState.pending_art[0]
	var n := _notice(parent, 640.0)
	n.title("¡%s te mandó un dibujo!" % art["who"], Color("7a56c4"))
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(0, 220)
	var px: String = art["px"]
	preview.draw.connect(func():
		var side := 200.0
		PixelArt.draw_pixels(preview, Rect2(Vector2(preview.size.x * 0.5 - side * 0.5, 10), Vector2(side, side)), px))
	n.add(preview)
	n.button("Guardarlo", func():
		GameState.answer_art(true)
		n.close()
		_call(closed), true, GREEN)
	n.button("No, gracias", func():
		GameState.answer_art(false)
		n.close()
		_call(closed), false)
	n.button("Denunciar", func():
		var code: String = art["code"]
		var who: String = art["who"]
		GameState.answer_art(false)
		n.close()
		report(parent, code, who, px, closed), false)
	return n
