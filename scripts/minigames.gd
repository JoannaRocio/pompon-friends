extends Control
## Minijuegos: tu Pompon juega y aprende. Cada juego entrena algo y hace que crezca mas
## inteligente, feliz y querido. Poco texto: se entiende mirando los iconos.

const GAMES := [
	{"name": "Matemáticas", "tag": "Tu nivel", "scene": "res://scenes/math_game.tscn", "color": "5bb8f5", "icon": "math", "max": 10},
	{"name": "Simón Dice", "tag": "Memoria", "scene": "res://scenes/simon_game.tscn", "color": "ff7aa8", "icon": "simon", "max": 12},
	{"name": "Patrones", "tag": "Lógica", "scene": "res://scenes/pattern_game.tscn", "color": "5fd48a", "icon": "patterns", "max": 10},
	{"name": "Salto al cielo", "tag": "Físico", "scene": "res://scenes/jump_game.tscn", "color": "ffb938", "icon": "jump", "max": 20},
	{"name": "Pintar", "tag": "Creatividad", "scene": "res://scenes/paint_game.tscn", "color": "e0609e", "icon": "paint", "max": 10},
	{"name": "Hacer música", "tag": "Música", "scene": "res://scenes/music_game.tscn", "color": "8a7be0", "icon": "music", "max": 10},
]


## Dibujito de cada juego dentro de un circulo de color.
class GameIcon extends Control:
	var kind := "math"
	var tint := Color("5bb8f5")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		draw_circle(c + Vector2(0, 5), r, Color(tint.darkened(0.4), 0.45))
		draw_circle(c, r, Color.WHITE)
		draw_circle(c, r - 6.0, tint)
		match kind:
			"math":
				var font := get_theme_default_font()
				draw_string(font, c + Vector2(-r, r * 0.3), "+ ×", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, int(r * 0.95), Color.WHITE)
			"simon":
				var cols := [Color("ff6b7a"), Color("5bb8f5"), Color("5fd48a"), Color("ffd24d")]
				for i in 4:
					var off := Vector2(-1 if i % 2 == 0 else 1, -1 if i < 2 else 1) * r * 0.27
					draw_circle(c + off, r * 0.24, Color.WHITE)
					draw_circle(c + off, r * 0.19, cols[i])
			"patterns":
				var cols2 := [Color("ff6b7a"), Color("ffd24d"), Color("ff6b7a")]
				for i in 3:
					var p := c + Vector2((i - 1) * r * 0.5, 0)
					draw_circle(p, r * 0.22, Color.WHITE)
					draw_circle(p, r * 0.17, cols2[i])
			"jump":   # nube y flecha hacia arriba
				for part in [[-0.3, 0.38, 0.2], [0.0, 0.32, 0.26], [0.3, 0.38, 0.2]]:
					draw_circle(c + Vector2(part[0], part[1]) * r, part[2] * r, Color.WHITE)
				draw_line(c + Vector2(0, 0.2) * r, c + Vector2(0, -0.5) * r, Color.WHITE, r * 0.14, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -0.72) * r, c + Vector2(-0.28, -0.38) * r, c + Vector2(0.28, -0.38) * r]), Color.WHITE)
			"paint":  # cuadritos de pixel art
				var cols3 := [Color("ff6b7a"), Color("ffd24d"), Color("5bb8f5"), Color("5fd48a")]
				for i in 9:
					var cell := Vector2(i % 3 - 1, i / 3 - 1) * r * 0.36
					draw_rect(Rect2(c + cell - Vector2(r, r) * 0.16, Vector2(r, r) * 0.32), Color.WHITE if i % 2 == 1 else cols3[i / 2 % 4])
			"music":
				Hud.draw_icon(self, "note", c, r * 1.2, Color.WHITE, Color(0, 0, 0, 0))


var _int_bar: StatBar


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("fff1de")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 18)
	add_child(root)

	# arriba: volver, titulo y monedas
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	top.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/home.tscn")))
	var title := Label.new()
	title.text = T.s("Minijuegos")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("7a56c4"))
	top.add_child(title)
	var coin_card := PanelContainer.new()
	coin_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(coin_card)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 6)
	coin_row.add_child(Hud.coin_icon(34.0))
	var coin_label := Label.new()
	coin_label.text = str(GameState.coins)
	coin_label.add_theme_font_size_override("font_size", 30)
	coin_label.add_theme_color_override("font_color", Color("b87400"))
	coin_row.add_child(coin_label)
	coin_card.add_child(coin_row)

	# tu Pompon: lo que mejora al jugar
	root.add_child(_pompon_card())

	# los juegos, en una lista que se desliza (son seis)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	for g in GAMES:
		list.add_child(_game_card(g))
	if GameState.minigame_gain_pending:
		_show_gain.call_deferred()


## Al volver de un minijuego: la barra de crecimiento sube y aparece "+x" con el brotecito.
func _show_gain() -> void:
	GameState.minigame_gain_pending = false
	if _int_bar == null or GameState.pompon == null or GameState.last_minigame_gain < 0.05:
		return
	var now := _int_bar.value
	_int_bar.value = maxf(0.0, now - GameState.last_minigame_gain)
	var tw := _int_bar.create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(_int_bar, "value", now, 0.8).set_trans(Tween.TRANS_SINE)
	var chip := MiniGameBase.RewardChip.new().setup("sprout", "+%.1f" % maxf(GameState.last_minigame_gain, 0.0), Color("5fc77f"))
	add_child(chip)
	chip.global_position = _int_bar.global_position + Vector2(60, -52)
	chip.modulate.a = 0.0
	var pop := chip.create_tween()
	pop.tween_interval(0.4)
	pop.tween_property(chip, "modulate:a", 1.0, 0.25)
	pop.parallel().tween_property(chip, "position:y", chip.position.y - 24.0, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_interval(1.0)
	pop.tween_property(chip, "modulate:a", 0.0, 0.5)
	pop.tween_callback(chip.queue_free)


func _pompon_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 40, Color.WHITE, 3, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var view := PomponView.new()
	view.custom_minimum_size = Vector2(190, 240)
	view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if GameState.pompon != null:
		view.set_pompon(GameState.pompon, GameState.equipped)
	row.add_child(view)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	row.add_child(col)
	var hint := Label.new()
	hint.text = T.s("¡Jugar lo hace crecer y aprender cosas nuevas!")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 28)
	hint.add_theme_color_override("font_color", Color("d6336c"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	for stat in ["crecimiento", "diversion", "amor"]:
		var bar := StatBar.new().setup("" if stat == "crecimiento" else stat, "sprout" if stat == "crecimiento" else "", Color("5fc77f") if stat == "crecimiento" else Color.TRANSPARENT)
		bar.custom_minimum_size = Vector2(0, 44)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if GameState.pompon != null:
			bar.value = PomponGrowth.quality(GameState.pompon, int(Time.get_unix_time_from_system())) if stat == "crecimiento" else float(GameState.pompon.stats.get(stat, 0.0))
		if stat == "crecimiento":
			bar.text = T.s("Crecimiento")
			bar.font_size = 18
		col.add_child(bar)
		if stat == "crecimiento":
			_int_bar = bar
	return card


func _game_card(g: Dictionary) -> Control:
	var color := Color(g["color"])
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 170)
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 40, Color.WHITE, 3, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var icon := GameIcon.new()
	icon.kind = g["icon"]
	icon.tint = color
	icon.custom_minimum_size = Vector2(130, 130)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 6)
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = T.s(g["name"])
	name_label.add_theme_font_size_override("font_size", 38)
	info.add_child(name_label)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	info.add_child(chips)
	chips.add_child(Hud.chip(T.s(g["tag"]), color.lightened(0.7), color.darkened(0.45), 22))
	var gain := HBoxContainer.new()
	gain.add_theme_constant_override("separation", 6)
	gain.add_child(Hud.coin_icon(28.0))
	var gain_label := Label.new()
	gain_label.text = T.s("hasta %d") % g["max"]
	gain_label.add_theme_font_size_override("font_size", 22)
	gain_label.add_theme_color_override("font_color", Color("b87400"))
	gain.add_child(gain_label)
	chips.add_child(gain)
	var play := Button.new()
	play.text = T.s("¡Jugar!")
	play.custom_minimum_size = Vector2(176, 92)
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	Hud.style_primary(play, 32, color)
	var scene_path: String = g["scene"]
	play.pressed.connect(func(): get_tree().change_scene_to_file(scene_path))
	row.add_child(play)
	return card
