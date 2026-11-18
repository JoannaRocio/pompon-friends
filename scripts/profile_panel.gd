class_name ProfilePanel
extends PanelContainer
## Perfil del Pompon: arriba quien es (foto, nombre, etapa) y abajo 4 pestañas cortas: Crece (como viene y
## que hacer hoy), Es (personalidad y aspecto), Le gusta (favoritos) y Sabe (habilidades). Se abre al tocar
## su foto. Poco texto por pantalla: los chicos leen poco, mejor iconos, barras y corazones.

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
var _pages: Array[Control] = []
var _scroll: ScrollContainer
static var _last_tab := 0   # vuelve a abrir en la ultima pestaña que miraste

const TABS := [{"label": "Crece", "icon": "sprout"}, {"label": "Cómo es", "icon": "smile"},
	{"label": "Le gusta", "icon": "heart"}, {"label": "Sabe", "icon": "star"}]


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
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	_header(box, p, now)
	box.add_child(_make_tabs())
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	var pages := VBoxContainer.new()
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(pages)
	for builder in [_growth, _personality, _tastes, _skills]:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 12)
		pages.add_child(col)
		builder.call(col, p, now)
		_pages.append(col)
	_show_tab(_last_tab)

	var close := Button.new()
	close.text = T.s("Cerrar")
	close.custom_minimum_size = Vector2(0, 80)
	Hud.style_primary(close, 34)
	close.pressed.connect(func(): closed.emit())
	box.add_child(close)
	return self


func _show_tab(i: int) -> void:
	_last_tab = i
	for k in _pages.size():
		_pages[k].visible = k == i
	if _scroll != null:
		_scroll.scroll_vertical = 0


## Pestañas con icono arriba y una palabra abajo (como el vestidor, pero mas chicas).
func _make_tabs() -> Control:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for i in TABS.size():
		var t: Dictionary = TABS[i]
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 92)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", Hud.pill(Color("fff1f6"), Color("ffc2d9"), 30, 3))
		b.add_theme_stylebox_override("hover", Hud.pill(Color("ffe4ee"), Color("ffb3d1"), 30, 3))
		b.add_theme_stylebox_override("pressed", Hud.pill(PINK, Color.WHITE, 30, 0))
		b.add_theme_stylebox_override("hover_pressed", Hud.pill(PINK, Color.WHITE, 30, 0))
		var col := VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(col)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(0, 38)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var kind: String = t["icon"]
		icon.draw.connect(func():
			Hud.draw_icon(icon, kind, icon.size * 0.5, 36.0, Color.WHITE if b.button_pressed else PINK, PINK if b.button_pressed else Color("fff1f6")))
		col.add_child(icon)
		var label := Label.new()
		label.text = T.s(t["label"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(label)
		var paint := func(on: bool):
			label.add_theme_color_override("font_color", Color.WHITE if on else INK)
			icon.queue_redraw()
		b.toggled.connect(paint)
		b.pressed.connect(func(): _show_tab(i))
		b.button_pressed = i == _last_tab
		paint.call(b.button_pressed)
		tabs.add_child(b)
	return tabs


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
	col.add_child(_label(title, 26, PINK))


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


## Cuadrito de un favorito (van de a dos por fila): icono, que es y cual es.
func _tile(grid: GridContainer, lead: Control, title: String, value: String, hearts := -1) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.97), 24, Color("f6dce8"), 3, 0))
	grid.add_child(card)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	lead.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(lead)
	col.add_child(_label(title, 20, SOFT, true))
	col.add_child(_label(value, 26, INK, true))
	if hearts >= 0:
		var h := HeartsRow.new().setup(hearts, 22.0)
		h.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(h)


func _header(col: VBoxContainer, p: Pompon, now: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	var photo := Panel.new()
	photo.custom_minimum_size = Vector2(170, 170)
	var tint := Color("ffd9e8") if p.sex == "Hembra" else Color("d4e9fb")
	photo.add_theme_stylebox_override("panel", Hud.card(tint, 85, Color("ff9ec0") if p.sex == "Hembra" else Color("8cc8f5"), 5, 4))
	row.add_child(photo)
	var view := PomponView.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.head_zoom = PomponView.portrait_zoom(p, now)
	view.set_pompon(p, GameState.equipped)
	photo.add_child(view)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)
	texts.add_child(_label(p.display_name(), 42, PINK))
	texts.add_child(_label("%s · %s" % [Pompon.species_label(p.species), T.label(p.stage_name(now))], 26, SOFT))
	var level := p.level(now)
	var next_level := p.next_stage_level(now)
	var life := T.s("Nivel %d") % level
	if next_level > 0:
		life += T.s("\nSerá %s en %d días") % [T.label(Pompon.stage_name_for_level(next_level)), next_level - level]
	texts.add_child(_label(life, 24, INK))


func _growth(col: VBoxContainer, p: Pompon, now: int) -> void:
	if PomponGrowth.active(p, now):
		var q := PomponGrowth.quality(p, now)
		var pace := PomponGrowth.pace(p, now)
		var bar := StatBar.new().setup("", "sprout", PomponGrowth.tier_color(pace))
		bar.value = q
		bar.text = T.s("Crecimiento  %d%%") % int(q)
		bar.font_size = 24
		bar.custom_minimum_size = Vector2(0, 58)
		col.add_child(bar)
		# una frase corta y en positivo: como viene (nunca lo malo que le podria pasar)
		var outlook := T.s("¡Va genial!")
		var outlook_color := PomponGrowth.tier_color(pace).darkened(0.25)
		if pace < PomponGrowth.NORMAL:
			outlook = T.s("¡Necesita tu cariño!")
			outlook_color = PINK
		elif pace < PomponGrowth.EXCELLENT:
			outlook = T.s("¡Va bien!")
		col.add_child(_label(outlook, 26, outlook_color, true))
		_section(col, T.s("Hoy para crecer feliz"))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 8)
		col.add_child(grid)
		for item in PomponGrowth.checklist(p, now):
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 8)
			grid.add_child(row)
			var done: float = item["done"]
			var mark := Control.new()
			mark.custom_minimum_size = Vector2(30, 30)
			mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.draw.connect(func():
				var c := mark.size * 0.5
				mark.draw_circle(c, 14.0, Color("5fc77f") if done >= 0.999 else (Color("ffd98a") if done > 0.0 else Color("eadfe6")))
				if done >= 0.999:
					Hud.draw_icon(mark, "check", c, 20.0, Color.WHITE))
			row.add_child(mark)
			var l := _label(T.s(item["label"]), 21, INK if done >= 0.999 else SOFT)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(l)
	else:
		col.add_child(_label(T.s("Ya terminó de crecer.") if p.stage_index(now) >= 4 else T.s("Todavía no empezó a crecer."), 24, SOFT, true))
	_section(col, T.s("Palabras que sabe"))
	var words := PomponGrowth.known_words(p, now)
	if words.is_empty():
		col.add_child(_label(T.s("Por ahora, solo soniditos."), 22, SOFT))
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


func _personality(col: VBoxContainer, p: Pompon, now: int) -> void:
	var tr: String = p.personality
	_row(col, _badge(Hud.STAT_ICONS.get(PomponTastes.TRAIT_STAT.get(tr, "felicidad"), "smile"), TRAIT_COLORS.get(tr, PINK)),
		Pompon.personality_label(tr), T.s(TRAIT_TEXT.get(tr, "")), -1)
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
	var traits: Array = p.growth.get("traits", [])
	if not traits.is_empty():
		_section(col, T.s("Rasgos que ganó al crecer"))
		for t in traits:
			var tcolor: Color = Color("5fc77f") if t["tier"] == "excelente" else (Color("ffb938") if t["tier"] == "normal" else Color("ff7a6b"))
			var after := int(t["stage"])
			_row(col, _badge("sprout", tcolor), T.s("De %s") % T.label(Pompon.STAGES[after]).to_lower(), "%s · %s" % [T.s(t["name"]), T.s(PomponGrowth.TRAIT_INFO.get(t["name"], ""))])
	_section(col, T.s("Aspecto"))
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	col.add_child(row2)
	row2.add_child(_swatch(p.color_primary, 46.0))
	row2.add_child(_swatch(p.color_secondary, 46.0))
	var l2 := _label(T.s("Ojos %s · boca de %s · cara %s") % [T.s(p.eyes), T.s(p.mouth), T.s(p.face)], 22)
	l2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(l2)
	col.add_child(_label(p.id, 20, SOFT, true))


func _tastes(col: VBoxContainer, p: Pompon, _now: int) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	col.add_child(grid)
	var finding := T.s("Lo está descubriendo…")
	var fam := PomponTastes.favorite_color(p)
	if fam != "":
		_tile(grid, _swatch(PomponTastes.color_swatch(fam), 52.0), T.s("Color favorito"), PomponTastes.color_name(fam).capitalize(), PomponTastes.color_hearts(p, fam))
	else:
		_tile(grid, _swatch(Color("e8dfe5"), 52.0), T.s("Color favorito"), finding)
	var food := PomponTastes.favorite_food(p)
	if food != "":
		_tile(grid, _badge("apple", Color("ffa94d")), T.s("Comida favorita"), PomponTastes.food_name(food), PomponTastes.food_hearts(p, food))
	else:
		_tile(grid, _badge("apple", Color("e0c9b5")), T.s("Comida favorita"), finding)
	var game := PomponTastes.favorite_game(p)
	_tile(grid, _badge("game", Color("a98bea") if game != "" else Color("d9d0e8")), T.s("Juego favorito"), PomponTastes.game_name(game) if game != "" else finding)
	var room := PomponTastes.favorite_room(p)
	_tile(grid, _badge("house", Color("ff7aa8") if room >= 0 else Color("efcfdc")), T.s("Habitación favorita"), Rooms.room_name(room) if room >= 0 else finding)
	# comidas que ya probo, con corazones (sin listas largas: las 4 que mas le gustan)
	var tried: Array = PomponTastes.FOODS.filter(func(f): return PomponTastes.times_eaten(p, f["id"]) > 0)
	if tried.is_empty():
		col.add_child(_label(T.s("¡Dale de comer para descubrir qué le gusta!"), 22, SOFT, true))
		return
	tried.sort_custom(func(a, b): return PomponTastes.food_score(p, a["id"]) > PomponTastes.food_score(p, b["id"]))
	_section(col, T.s("Comidas que probó"))
	for i in mini(4, tried.size()):
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


func _skills(col: VBoxContainer, p: Pompon, _now: int) -> void:
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
