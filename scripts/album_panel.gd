class_name AlbumPanel
extends PanelContainer
## Album de recuerdos (se abre desde el diario): las figuritas por pagina, con un hueco y una pista
## para las que faltan. Ver PomponAlbum.

signal closed

const INK := Color("5b3a4a")


var _sex := ""   # (para {he}/{his} en inglés)


func setup(p: Pompon) -> AlbumPanel:
	_sex = p.sex
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 22
	offset_right = -22
	offset_top = 110
	offset_bottom = -22
	add_theme_stylebox_override("panel", Hud.card(Color("fffaf0"), 40, Color("f2c94c"), 6, 16))
	var now := int(Time.get_unix_time_from_system())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	var title := Label.new()
	title.text = T.s("Álbum de %s") % p.display_name()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("d6336c"))
	box.add_child(title)
	var prog := PomponAlbum.progress(p, now)
	var bar := StatBar.new().setup("", "star", Color("ffcf3f"))
	bar.custom_minimum_size = Vector2(0, 44)
	bar.font_size = 20
	bar.warn_low = false
	bar.max_value = float(prog["total"])
	bar.value = float(prog["won"])
	bar.text = T.s("%d de %d figuritas") % [prog["won"], prog["total"]]
	box.add_child(bar)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var all := PomponAlbum.stickers()
	for page in PomponAlbum.PAGES.size():
		var page_label := Label.new()
		page_label.text = T.s(PomponAlbum.PAGES[page])
		page_label.add_theme_font_size_override("font_size", 30)
		page_label.add_theme_color_override("font_color", Color("a0527a"))
		list.add_child(page_label)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		list.add_child(grid)
		for s in all:
			if int(s["page"]) == page:
				grid.add_child(_sticker(s, PomponAlbum.unlocked(p, s["id"], now), PomponAlbum.day_won(p, s["id"])))

	var close := Button.new()
	close.text = T.s("Cerrar")
	close.custom_minimum_size = Vector2(0, 80)
	close.focus_mode = Control.FOCUS_NONE
	Hud.style_primary(close, 34)
	close.pressed.connect(closed.emit)
	box.add_child(close)
	return self


## Una figurita: ganada (sticker de color, su nombre y el dia) o el hueco con "?" y la pista.
func _sticker(s: Dictionary, won: bool, day: int) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 196)
	card.add_theme_stylebox_override("panel", Hud.card(Color.WHITE if won else Color("f6f0f3"), 26,
		Color(s["color"]).lightened(0.35) if won else Color("e8dce3"), 3, 4 if won else 0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	var art := Control.new()
	art.custom_minimum_size = Vector2(0, 92)
	var tint: Color = s["color"]
	var kind: String = s["icon"]
	art.draw.connect(func():
		var c := art.size * 0.5
		if won:  # sticker redondo con borde ondulado
			var pts := PackedVector2Array()
			for i in 48:
				var a := TAU * i / 48.0
				pts.append(c + Vector2(cos(a), sin(a)) * (42.0 + 3.0 * sin(a * 12.0)))
			art.draw_colored_polygon(pts, Color.WHITE)
			pts.append(pts[0])
			art.draw_polyline(pts, tint.darkened(0.15), 2.0, true)
			art.draw_circle(c, 36.0, tint)
			Hud.draw_icon(art, kind, c, 46.0, Color.WHITE, tint.darkened(0.25))
		else:  # hueco: circulo punteado con "?"
			for i in 24:
				var a := TAU * i / 24.0
				art.draw_arc(c, 38.0, a, a + TAU / 48.0, 4, Color("d8c8d2"), 4.0, true)
			var font := art.get_theme_default_font()
			art.draw_string(font, c + Vector2(-40, 14), "?", HORIZONTAL_ALIGNMENT_CENTER, 80, 40, Color("cbb8c4")))
	col.add_child(art)
	var name_label := Label.new()
	name_label.text = T.with_pron(s["title"] if won else s["hint"], _sex)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.add_theme_font_size_override("font_size", 18 if won else 16)
	name_label.add_theme_color_override("font_color", INK if won else Color(INK, 0.45))
	col.add_child(name_label)
	if won and day > 0:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(Hud.chip(T.s("Día %d") % day, Color("fff3d1"), Color("8a6d00"), 15))
		col.add_child(row)
	return card
