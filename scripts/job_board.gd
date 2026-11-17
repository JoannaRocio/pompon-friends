extends Control
## Ofertas de empleo del periodico: se elige el trabajo. Hay dos disponibles (profesor/a de
## matematicas y de ingles, con una sola carrera) y uno bloqueado que llegara pronto (geografia).

const INK := Color("5b3a4a")
const TIP_INTRO := "job_intro"    # cartel "para cuidar a tu Pompon necesitas monedas" (ya visto)
const TIP_HIRED := "job_hired"    # cartel "¡conseguiste tu primer trabajo!" (ya visto)
const TIP_ENGLISH := "job_english"  # cartel "¡ahora tambien enseñas ingles!" (ya visto)
const TIP_GEOGRAPHY := "job_geography"  # lo mismo para geografia

var _list: VBoxContainer
var _slot: VBoxContainer       # nombre o ficha de profesor/a
var _message: Label
var _layer: Control
var _arrow: GuideArrow
var _apply_buttons: Array = []   # botones T.s("Aplicar") (la flecha los señala la primera vez)


## Icono de cada oferta (dibujado por codigo); si esta bloqueado lleva un candado.
class JobIcon extends Control:
	var job_id := ""
	var tint := Color.WHITE
	var locked := false

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = tint.lerp(Color("bdb6c4"), 0.65) if locked else tint
		sb.border_color = Color("5b3a4a")
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(24)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var font := get_theme_default_font()
		var white := Color(1, 1, 1, 0.92)
		match job_id:
			"math":
				var symbols := ["+", "−", "×", "÷"]
				for i in 4:
					var c := Vector2(size.x * (0.3 + 0.4 * (i % 2)), size.y * (0.38 + 0.38 * (i / 2)))
					draw_string(font, c + Vector2(-18, 16), symbols[i], HORIZONTAL_ALIGNMENT_CENTER, 36, 46, white)
			"english":
				draw_string(font, Vector2(12, size.y * 0.55), "Aa", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, white)
				draw_string(font, Vector2(12, size.y * 0.8), "ABC", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, white)
			"geography":
				var c2 := size * 0.5
				var r := size.x * 0.32
				draw_circle(c2, r, Color(1, 1, 1, 0.25))
				draw_arc(c2, r, 0.0, TAU, 36, white, 4.0, true)
				draw_line(c2 + Vector2(-r, 0), c2 + Vector2(r, 0), white, 3.0)
				draw_line(c2 + Vector2(0, -r), c2 + Vector2(0, r), white, 3.0)
				for rx in [r * 0.5, r * 0.85]:
					var pts := PackedVector2Array()
					for k in 33:
						var a := TAU * k / 32.0
						pts.append(c2 + Vector2(cos(a) * rx, sin(a) * r))
					draw_polyline(pts, white, 3.0, true)
		if locked:
			var lock := Rect2(size.x - 44, size.y - 38, 34, 26)
			draw_arc(Vector2(lock.get_center().x, lock.position.y), 10.0, PI, TAU, 14, Color("5b3a4a"), 6.0, true)
			var lb := StyleBoxFlat.new()
			lb.bg_color = Color("5b3a4a")
			lb.set_corner_radius_all(6)
			draw_style_box(lb, lock)
			draw_circle(lock.get_center(), 4.0, Color("f3ead8"))


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("fff4e8")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	# cabecera: volver + nombre del periodico
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	root.add_child(top)
	top.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/home.tscn")))
	var paper := PanelContainer.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper.add_theme_stylebox_override("panel", Hud.card(Color("fffdf6"), 26, Color("e3d2b6"), 4, 6))
	top.add_child(paper)
	var paper_box := VBoxContainer.new()
	paper_box.add_theme_constant_override("separation", 2)
	paper.add_child(paper_box)
	var masthead := Label.new()
	masthead.text = T.s("EL PERIÓDICO POMPON")
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	masthead.add_theme_font_size_override("font_size", 34)
	masthead.add_theme_color_override("font_color", INK)
	paper_box.add_child(masthead)
	var section := Label.new()
	section.text = T.s("OFERTAS DE EMPLEO")
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_theme_font_size_override("font_size", 24)
	section.add_theme_color_override("font_color", Color("d6336c"))
	paper_box.add_child(section)

	# tu puesto: el nombre (todavia sin trabajo) o la ficha de profesor/a (ya contratado/a)
	_slot = VBoxContainer.new()
	root.add_child(_slot)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 16)
	scroll.add_child(_list)

	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 24)
	_message.add_theme_color_override("font_color", Color("a0527a"))
	root.add_child(_message)

	_arrow = GuideArrow.new()
	_arrow.prefer_below = true  # arriba de T.s("Aplicar") esta T.s("Cambiar"): la flecha va debajo
	add_child(_arrow)
	_rebuild()
	if not GameState.has_profile():  # por si se llega sin haber pasado por el menu
		_ask_profile.call_deferred(false)


static func hired() -> bool:
	return GameState.tips_seen.has(TIP_HIRED) or GameState.jobs_done > 0


func _rebuild() -> void:
	for c in _slot.get_children():
		c.queue_free()
	if hired():
		var card := TeacherCard.new().setup(-1, true)
		card.change_pressed.connect(func(): _ask_profile(true))
		_slot.add_child(card)
	else:
		_slot.add_child(_name_row())
	for c in _list.get_children():
		c.queue_free()
	_apply_buttons = []
	for job in Jobs.JOBS:
		_list.add_child(_make_ad(job))


## Todavia sin trabajo: el nombre del jugador y T.s("Cambiar").
func _name_row() -> Control:
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 12)
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", Hud.card(Color("ffe6ef"), 30, Color("ffc2d9"), 3, 0))
	who.add_child(chip)
	var title := Label.new()
	title.text = Jobs.full_title(GameState.player_title, GameState.player_name)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("a0527a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(title)
	var change := Button.new()
	change.text = T.s("Cambiar")
	change.custom_minimum_size = Vector2(150, 64)
	Hud.style_soft(change, 24)
	change.pressed.connect(func(): _ask_profile(true))
	who.add_child(change)
	return who


## Cartel al aplicar la primera vez: ¡primer trabajo!, la ficha de profesor/a y para que sirven las monedas.
## (Antes habia otro cartel al entrar, "Para cuidar a tu Pompon necesitas monedas": se junto con este
## para que haya menos carteles antes de que nazca el Pompon.)
func _show_hired(job: Dictionary) -> void:
	var notice := BigNotice.new(660.0)
	_layer = notice
	add_child(notice)
	notice.title(T.s("¡Conseguiste tu primer trabajo!"))
	notice.add(TeacherCard.new().setup(1))
	notice.text_line(T.s("Con las monedas cuidas a tu Pompon."), 26, Color("a0527a"))
	notice.button(T.s("¡A trabajar!"), func():
		if not GameState.tips_seen.has(TIP_INTRO):
			GameState.tips_seen.append(TIP_INTRO)
		GameState.tips_seen.append(TIP_HIRED)
		GameState.save_game()
		get_tree().change_scene_to_file(job["scene"]))
	Audio.play("success")


## La flecha señala T.s("Aplicar") mientras haya que aprender a trabajar (no tapa el dialogo del nombre).
func _process(_delta: float) -> void:
	_arrow.set_targets(_apply_buttons if GameState.job_guide_on() and _layer == null else [])


func _make_ad(job: Dictionary) -> Control:
	var available: bool = job["available"]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95) if available else Color(1, 1, 1, 0.7), 34, Color.WHITE, 3, 8 if available else 2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var icon := JobIcon.new()
	icon.job_id = job["id"]
	icon.tint = Color(job["color"])
	icon.locked = not available
	icon.custom_minimum_size = Vector2(116, 116)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = Jobs.title(job["id"], GameState.player_title)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 30)
	if not available:
		name_label.add_theme_color_override("font_color", Color(INK, 0.55))
	info.add_child(name_label)
	var blurb := Label.new()
	blurb.text = Jobs.blurb(job)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.add_theme_font_size_override("font_size", 24)
	blurb.add_theme_color_override("font_color", Color("a0527a") if available else Color(INK, 0.45))
	info.add_child(blurb)
	if not available:   # (si hay lugar no hace falta decirlo: el boton "Aplicar" ya lo dice)
		var status_row := HBoxContainer.new()
		info.add_child(status_row)
		status_row.add_child(Hud.chip(T.s("Próximamente"), Color("ece6f0"), Color("7d7390"), 20))

	if available:
		var apply := Button.new()
		apply.text = T.s("Aplicar")
		apply.custom_minimum_size = Vector2(150, 86)
		apply.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		Hud.style_primary(apply, 30)
		var job_id: String = job["id"]
		apply.pressed.connect(func(): _open(job_id))
		row.add_child(apply)
		_apply_buttons.append(apply)
	return card


func _open(job_id: String) -> void:
	var job := Jobs.get_job(job_id)
	if job.is_empty() or not job["available"]:
		_message.text = T.s("Este trabajo todavía no está disponible. ¡Pronto habrá más oficios!")
		Audio.play("fail")
		return
	Jobs.current = job_id
	var tip := _subject_tip(job_id)
	if not hired():
		if tip != "":  # (el primer trabajo ya se festeja con su cartel)
			GameState.tips_seen.append(tip)
		_show_hired(job)
		return
	if tip != "" and not GameState.tips_seen.has(tip):
		_show_new_subject(job)
		return
	get_tree().change_scene_to_file(job["scene"])


## Cartel de "nueva materia" de ese trabajo ("" para matematicas, que es la primera).
static func _subject_tip(job_id: String) -> String:
	return {"english": TIP_ENGLISH, "geography": TIP_GEOGRAPHY}.get(job_id, "")


## Ya trabaja de profesor/a y suma otra materia: su nivel y su paga siguen iguales (es una sola carrera).
func _show_new_subject(job: Dictionary) -> void:
	var notice := BigNotice.new(660.0)
	_layer = notice
	add_child(notice)
	var tint := Color(job["color"])
	notice.add(BigNotice.icon_strip([["book" if job["id"] == "english" else "house", tint], ["star", Color("ffcf3f")], ["coin", Color("ffcf3f")]]))
	notice.title(T.s("¡Ahora también enseñas %s!") % Jobs.subject_name(job["id"]))
	notice.text_line(T.s("Tu nivel y tu paga son los mismos en todas las materias."), 28, Color("a0527a"))
	var tip := _subject_tip(job["id"])
	notice.button(T.s("¡A enseñar!"), func():
		GameState.tips_seen.append(tip)
		GameState.save_game()
		get_tree().change_scene_to_file(job["scene"]))
	Audio.play("success")


## Pide nombre y sexo (la primera vez es obligatorio; al cambiarlo se puede cancelar).
func _ask_profile(can_cancel: bool) -> void:
	if _layer != null:
		return
	if GameState.age_group == "":   # (por si se llega sin haber pasado por el menu) primero la edad
		_layer = FriendSafety.ask_age(self, func(_g):
			_layer = null
			_ask_profile(can_cancel))
		return
	var dialog := ProfileDialog.new()
	_layer = dialog
	add_child(dialog)
	dialog.setup(can_cancel)
	var close := func():
		dialog.queue_free()
		_layer = null
	dialog.accepted.connect(func():
		close.call()
		_rebuild())
	dialog.cancelled.connect(close)
