class_name ProfilePanel
extends PanelContainer
## Perfil del Pompon: quien es, su personalidad, y los gustos que fue aprendiendo (color, comida, juego,
## habitacion), su aspecto y lo que sabe hacer. Se abre al tocar su foto.

signal closed

const INK := Color("5b3a4a")
const PINK := Color("d6336c")
const SOFT := Color("a0527a")
const TRAIT_COLORS := {"Energico": Color("ffa94d"), "Timido": Color("ff8fb8"), "Curioso": Color("5bb8f5"),
	"Gloton": Color("f2c14e"), "Artistico": Color("b388f5")}
const TRAIT_TEXT := {
	"Energico": "Siempre quiere moverse y jugar", "Timido": "Tranquilo y sensible, le encantan los mimos",
	"Curioso": "Le encanta explorar y aprender", "Gloton": "Siempre piensa en la próxima comida",
	"Artistico": "Le gustan los colores y las cosas lindas",
}


## Barrita de un rasgo de personalidad.
class TraitBar extends Control:
	var value := 0.0
	var max_value := 60.0
	var color := Color.WHITE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("f0e6ec")
		sb.set_corner_radius_all(int(size.y * 0.5))
		draw_style_box(sb, r)
		if value > 0.0:
			var fill := StyleBoxFlat.new()
			fill.bg_color = color
			fill.set_corner_radius_all(int(size.y * 0.5))
			draw_style_box(fill, Rect2(Vector2.ZERO, Vector2(maxf(size.y, size.x * clampf(value / max_value, 0.0, 1.0)), size.y)))


var _sex := ""   # (para {he}/{his} en inglés)


func setup(p: Pompon) -> ProfilePanel:
	_sex = p.sex
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 20
	offset_right = -20
	offset_top = 96
	offset_bottom = -20
	add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 38, Color("ffb3d1"), 6, 16))
	var now := int(Time.get_unix_time_from_system())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	scroll.add_child(col)

	_header(col, p, now)
	_section(col, T.s("Crecimiento"))
	_growth(col, p, now)
	_section(col, T.s("Personalidad"))
	_personality(col, p, now)
	_section(col, T.s("Gustos"))
	_tastes(col, p)
	_section(col, T.s("Aspecto"))
	_looks(col, p)
	_section(col, T.s("Habilidades"))
	_skills(col, p)

	var close := Button.new()
	close.text = T.s("Cerrar")
	close.custom_minimum_size = Vector2(0, 80)
	Hud.style_primary(close, 34)
	close.pressed.connect(func(): closed.emit())
	box.add_child(close)
	return self


# ------------------------------------------------------------------ piezas

func _label(text: String, size: int, color := INK, center := false) -> Label:
	var l := Label.new()
	l.text = T.with_pron(text, _sex)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _section(col: VBoxContainer, title: String) -> void:
	var l := _label(title, 30, PINK)
	col.add_child(l)
	var d := ColorRect.new()
	d.color = Color("f3dbe6")
	d.custom_minimum_size = Vector2(0, 3)
	col.add_child(d)


func _badge(kind: String, color: Color, px := 52.0) -> Control:
	var b := Control.new()
	b.custom_minimum_size = Vector2(px, px)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.draw.connect(func():
		var c := b.size * 0.5
		b.draw_circle(c, px * 0.5, color)
		Hud.draw_icon(b, kind, c, px * 0.64, Color.WHITE, color.darkened(0.3)))
	return b


func _swatch(color: Color, px := 40.0) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(px, px)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.draw.connect(func():
		var c := s.size * 0.5
		s.draw_circle(c, px * 0.5, Color.WHITE)
		s.draw_circle(c, px * 0.5 - 4.0, color)
		s.draw_arc(c, px * 0.5 - 2.0, 0.0, TAU, 24, Color(0, 0, 0, 0.15), 2.0, true))
	return s


## Una fila: icono (o muestra de color), titulo chico, valor grande y, si hace falta, corazones.
func _row(col: VBoxContainer, lead: Control, title: String, value: String, hearts := -1) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.97), 24, Color("f6dce8"), 3, 0))
	col.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	row.add_child(lead)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	row.add_child(texts)
	texts.add_child(_label(title, 20, SOFT))
	texts.add_child(_label(value, 28))
	if hearts >= 0:
		row.add_child(HeartsRow.new().setup(hearts, 26.0))


func _header(col: VBoxContainer, p: Pompon, now: int) -> void:
	var photo := Panel.new()
	photo.custom_minimum_size = Vector2(250, 250)
	photo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tint := Color("ffd9e8") if p.sex == "Hembra" else Color("d4e9fb")
	photo.add_theme_stylebox_override("panel", Hud.card(tint, 125, Color("ff9ec0") if p.sex == "Hembra" else Color("8cc8f5"), 6, 6))
	col.add_child(photo)
	var view := PomponView.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.head_zoom = PomponView.portrait_zoom(p, now)
	view.set_pompon(p, GameState.equipped)
	photo.add_child(view)
	var name_label := _label(p.display_name(), 46, PINK, true)
	col.add_child(name_label)
	var level := p.level(now)
	var line := "%s · %s" % [Pompon.species_label(p.species), T.label(p.stage_name(now))]
	col.add_child(_label(line, 28, SOFT, true))
	var next_level := p.next_stage_level(now)
	var life := T.s("Nivel %d · día %d de vida") % [level, p.days_alive(now) + 1]
	if next_level > 0:
		life += T.s("\nSerá %s en %d días") % [T.label(Pompon.stage_name_for_level(next_level)), next_level - level]
	col.add_child(_label(life, 24, INK, true))
	col.add_child(_label(p.id, 20, SOFT, true))


func _growth(col: VBoxContainer, p: Pompon, now: int) -> void:
	if PomponGrowth.active(p, now):
		var q := PomponGrowth.quality(p, now)
		var bar := StatBar.new().setup("", "sprout", PomponGrowth.tier_color(PomponGrowth.pace(p, now)))
		bar.value = q
		bar.text = T.s("Crecimiento  %d%%") % int(q)
		bar.font_size = 24
		bar.custom_minimum_size = Vector2(0, 58)
		col.add_child(bar)
		# a este ritmo, como terminaria la etapa
		var pace := PomponGrowth.pace(p, now)
		var outlook := T.s("Si sigues así, crecerá con un rasgo muy positivo y 5 palabras nuevas.")
		if pace < PomponGrowth.NORMAL:
			outlook = T.s("Si no lo cuidas mejor, podría crecer tímido, miedoso o solitario.")
		elif pace < PomponGrowth.EXCELLENT:
			outlook = T.s("Crecerá con rasgos normales. ¡Con más cuidado puede llegar más lejos!")
		# (cuantos dias faltan ya lo dice el encabezado: aca solo como viene y que se puede sumar hoy)
		col.add_child(_label(outlook, 22, PomponGrowth.tier_color(pace).darkened(0.25)))
		col.add_child(_label(T.s("Hoy puedes sumar:"), 24, SOFT))
		for item in PomponGrowth.checklist(p, now):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			col.add_child(row)
			var done: float = item["done"]
			var mark := Control.new()
			mark.custom_minimum_size = Vector2(32, 32)
			mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.draw.connect(func():
				var c := mark.size * 0.5
				mark.draw_circle(c, 15.0, Color("5fc77f") if done >= 0.999 else (Color("ffd98a") if done > 0.0 else Color("eadfe6")))
				if done >= 0.999:
					Hud.draw_icon(mark, "check", c, 22.0, Color.WHITE))
			row.add_child(mark)
			var l := _label(T.s(item["label"]), 22, INK if done >= 0.999 else SOFT)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
	else:
		col.add_child(_label(T.s("Ya terminó de crecer.") if p.stage_index(now) >= 4 else T.s("Todavía no empezó a crecer."), 22, SOFT))
	var words := PomponGrowth.known_words(p, now)
	col.add_child(_label(T.s("Palabras que sabe"), 24, SOFT))
	if words.is_empty():
		col.add_child(_label(T.s("Todavía no dice palabras: solo sonidos."), 22, INK))
	else:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 8)
		flow.add_theme_constant_override("v_separation", 8)
		col.add_child(flow)
		for w in words:
			var chip := PanelContainer.new()
			chip.add_theme_stylebox_override("panel", Hud.card(Color("e8f8ee"), 20, Color("a8e6bf"), 2, 0))
			var wl := _label(T.s("«%s»") % T.s(w), 24, Color("2f7a4f"))
			wl.autowrap_mode = TextServer.AUTOWRAP_OFF
			chip.add_child(wl)
			flow.add_child(chip)
	var traits: Array = p.growth.get("traits", [])
	if not traits.is_empty():
		col.add_child(_label(T.s("Rasgos que ganó al crecer"), 24, SOFT))
		for t in traits:
			var tcolor: Color = Color("5fc77f") if t["tier"] == "excelente" else (Color("ffb938") if t["tier"] == "normal" else Color("ff7a6b"))
			var after := int(t["stage"])
			_row(col, _badge("sprout", tcolor), T.s("De %s") % T.label(Pompon.STAGES[after]).to_lower(), "%s · %s" % [T.s(t["name"]), T.s(PomponGrowth.TRAIT_INFO.get(t["name"], ""))])


func _personality(col: VBoxContainer, p: Pompon, now: int) -> void:
	var tr: String = p.personality
	_row(col, _badge(Hud.STAT_ICONS.get(PomponTastes.TRAIT_STAT.get(tr, "felicidad"), "smile"), TRAIT_COLORS.get(tr, PINK)),
		T.s("Es"), Pompon.personality_label(tr), -1)
	col.add_child(_label(T.s(TRAIT_TEXT.get(tr, "")), 24, INK))
	var forming := p.stage_index(now) <= 2
	col.add_child(_label(T.s("Su personalidad se está formando: lo que viven juntos la moldea.") if forming else T.s("Su personalidad ya está formada."), 22, SOFT))
	for t in PomponTastes.TRAITS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		col.add_child(row)
		var l := _label(Pompon.personality_label(t), 22)
		l.custom_minimum_size = Vector2(150, 0)
		row.add_child(l)
		var bar := TraitBar.new()
		bar.value = PomponTastes.trait_value(p, t)
		bar.color = TRAIT_COLORS[t]
		bar.custom_minimum_size = Vector2(0, 22)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)


func _tastes(col: VBoxContainer, p: Pompon) -> void:
	# color favorito
	var fam := PomponTastes.favorite_color(p)
	if fam != "":
		_row(col, _swatch(PomponTastes.color_swatch(fam)), T.s("Color favorito"), PomponTastes.color_name(fam).capitalize(), PomponTastes.color_hearts(p, fam))
	else:
		_row(col, _swatch(Color("e8dfe5")), T.s("Color favorito"), T.s("Lo está descubriendo…"))
	var ranked := PomponTastes.colors_ranked(p)
	for i in mini(3, ranked.size()):
		var f: String = ranked[i]
		if f == fam:
			continue
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 10)
		col.add_child(r)
		r.add_child(_swatch(PomponTastes.color_swatch(f), 28.0))
		var l := _label(T.s("Le gusta el %s") % PomponTastes.color_name(f), 22)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(l)
		r.add_child(HeartsRow.new().setup(PomponTastes.color_hearts(p, f), 20.0))
	# comida favorita
	var food := PomponTastes.favorite_food(p)
	if food != "":
		_row(col, _badge("apple", Color("ffa94d")), T.s("Comida favorita"), PomponTastes.food_name(food), PomponTastes.food_hearts(p, food))
	else:
		_row(col, _badge("apple", Color("e0c9b5")), T.s("Comida favorita"), T.s("Todavía no tiene una favorita"))
	var tried: Array = PomponTastes.FOODS.filter(func(f): return PomponTastes.times_eaten(p, f["id"]) > 0)
	tried.sort_custom(func(a, b): return PomponTastes.food_score(p, a["id"]) > PomponTastes.food_score(p, b["id"]))
	for i in mini(6, tried.size()):
		var tf: Dictionary = tried[i]
		var hearts := PomponTastes.food_hearts(p, tf["id"])
		var r2 := HBoxContainer.new()
		r2.add_theme_constant_override("separation", 10)
		col.add_child(r2)
		var nl := _label(PomponTastes.food_name(tf["id"]), 22)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r2.add_child(nl)
		if hearts == 0:
			var doubt := _label(T.s("todavía duda"), 20, SOFT)
			doubt.autowrap_mode = TextServer.AUTOWRAP_OFF   # sin esto el texto se parte letra por letra
			r2.add_child(doubt)
		else:
			r2.add_child(HeartsRow.new().setup(hearts, 20.0))
	if tried.is_empty():
		col.add_child(_label(T.s("Todavía no probó ninguna comida."), 22, SOFT))
	else:
		var new_n: int = PomponTastes.FOODS.size() - tried.size()
		if new_n > 0:
			col.add_child(_label(T.s("Le faltan probar %d comidas. Al principio duda, pero de a poco se anima.") % new_n, 22, SOFT))
	# juego y habitacion
	var game := PomponTastes.favorite_game(p)
	_row(col, _badge("game", Color("a98bea")), T.s("Juego favorito"), PomponTastes.game_name(game) if game != "" else T.s("Todavía no eligió"))
	var room := PomponTastes.favorite_room(p)
	_row(col, _badge("house", Color("ff7aa8")), T.s("Habitación favorita"), Rooms.room_name(room) if room >= 0 else T.s("Todavía no eligió"))


func _looks(col: VBoxContainer, p: Pompon) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	row.add_child(_swatch(p.color_primary, 46.0))
	row.add_child(_swatch(p.color_secondary, 46.0))
	var l := _label(T.s("Ojos %s · boca de %s · cara %s") % [T.s(p.eyes), T.s(p.mouth), T.s(p.face)], 24)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)


func _skills(col: VBoxContainer, p: Pompon) -> void:
	col.add_child(_label(T.s("Las va desarrollando con los minijuegos y con los objetos de su cuarto."), 22, SOFT))
	for skill in PomponSkills.ORDER:
		var info: Dictionary = PomponSkills.SKILLS[skill]
		var color: Color = info["color"]
		var level := PomponSkills.level(p, skill)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.97), 24, color.lightened(0.45), 3, 0))
		col.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		row.add_child(_badge(info["icon"], color, 56.0))
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 3)
		row.add_child(texts)
		var top := HBoxContainer.new()
		texts.add_child(top)
		var name_label := _label(T.s(info["name"]), 28)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_label)
		var level_label := _label(T.s("¡Máximo!") if level >= PomponSkills.MAX_LEVEL else T.s("Nivel %d") % level, 26, color.darkened(0.25))
		level_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		top.add_child(level_label)
		var bar := TraitBar.new()
		bar.max_value = 1.0
		bar.value = PomponSkills.progress(p, skill)
		bar.color = color
		bar.custom_minimum_size = Vector2(0, 16)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		texts.add_child(bar)
		var hint := _label(T.s("Se entrena con: ") + T.s(String(info["hint"])).to_lower(), 18, SOFT)
		hint.custom_minimum_size = Vector2(300, 0)
		texts.add_child(hint)
