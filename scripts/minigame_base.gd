class_name MiniGameBase
extends Control
## Base de los minijuegos de inteligencia: fondo suave, barra de arriba (salir, estrellas de avance y
## monedas), tu Pompon mirando y animando desde abajo, y la tarjeta final con los premios.
## Cada juego pone su contenido en `content` y llama a `_mark()` en cada ronda y a `_end()` al terminar.

const INK := Color("5b3a4a")

var results: Array = []        # true/false por ronda
var total_rounds := 5
var earned := 0                # monedas ganadas hasta ahora
var coins_per_round := 2
var content: VBoxContainer
var _dots: StarDots
var _coin_label: Label
var _pet: PomponView
var _layer: Control
var _ended := false
var game_id := ""               # "math", "simon" o "pattern": el Pompon aprende cual le gusta mas


class StarDots extends Control:
	var results: Array = []
	var total := 5

	func _draw() -> void:
		var step := minf(size.x / total, size.y * 1.15)
		var r := step * 0.42
		var x0 := (size.x - step * total) * 0.5 + step * 0.5
		for i in total:
			var c := Vector2(x0 + step * i, size.y * 0.5)
			var pts := PackedVector2Array()
			for k in 10:
				var rr := r if k % 2 == 0 else r * 0.46
				var a := -PI / 2.0 + PI * k / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			var col := Color("ece3ea")
			if i < results.size():
				col = Color("ffcf3f") if results[i] else Color("ffb3c8")
			draw_colored_polygon(pts, col)
			pts.append(pts[0])
			draw_polyline(pts, Color("5b3a4a"), 2.5, true)


## Premio: circulo de color con icono + texto corto ("+10", "+1"...).
class RewardChip extends HBoxContainer:
	func setup(kind: String, text: String, color: Color) -> RewardChip:
		add_theme_constant_override("separation", 8)
		alignment = BoxContainer.ALIGNMENT_CENTER
		var badge := Control.new()
		badge.custom_minimum_size = Vector2(58, 58)
		badge.draw.connect(func():
			var c := badge.size * 0.5
			badge.draw_circle(c, 29.0, Color.WHITE)
			badge.draw_circle(c, 25.0, color)
			Hud.draw_icon(badge, kind, c, 38.0, Color.WHITE, color.darkened(0.3)))
		add_child(badge)
		var l := Label.new()
		l.text = text
		l.add_theme_font_size_override("font_size", 34)
		l.add_theme_color_override("font_color", color.darkened(0.35))
		add_child(l)
		return self


func _build_chrome(bg_color: Color, rounds: int, pay := 2) -> void:
	total_rounds = rounds
	coins_per_round = pay
	var bg := ColorRect.new()
	bg.color = bg_color
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# nubes suaves de decoracion
	var deco := Control.new()
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.draw.connect(func():
		for p in [Vector2(0.15, 0.2), Vector2(0.85, 0.32), Vector2(0.2, 0.58), Vector2(0.8, 0.72)]:
			deco.draw_circle(deco.size * p, 90.0, Color(1, 1, 1, 0.22))
			deco.draw_circle(deco.size * p + Vector2(60, 20), 60.0, Color(1, 1, 1, 0.22)))
	add_child(deco)

	content = VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 30
	content.offset_right = -30
	content.offset_top = 130
	content.offset_bottom = -330
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 26)
	add_child(content)

	# tu Pompon mira y festeja desde abajo
	_pet = PomponView.new()
	_pet.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_pet.offset_left = -170
	_pet.offset_right = 170
	_pet.offset_top = -360
	_pet.offset_bottom = -10
	_pet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if GameState.pompon != null:
		_pet.set_pompon(GameState.pompon, GameState.equipped)
	add_child(_pet)

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14
	top.offset_right = -14
	top.offset_top = 14
	top.add_theme_constant_override("separation", 10)
	add_child(top)
	top.add_child(Hud.back_button(_leave))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var dots_card := PanelContainer.new()
	dots_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dots_card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(dots_card)
	_dots = StarDots.new()
	_dots.total = rounds
	_dots.custom_minimum_size = Vector2(maxf(190.0, rounds * 36.0), 34)
	dots_card.add_child(_dots)
	var pay_card := PanelContainer.new()
	pay_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pay_card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(pay_card)
	var pay_row := HBoxContainer.new()
	pay_row.add_theme_constant_override("separation", 4)
	pay_row.add_child(Hud.coin_icon(30.0))
	_coin_label = Label.new()
	_coin_label.text = "0"
	_coin_label.add_theme_font_size_override("font_size", 28)
	_coin_label.add_theme_color_override("font_color", Color("b87400"))
	pay_row.add_child(_coin_label)
	pay_card.add_child(pay_row)


func _label(text: String, size: int, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Anota una ronda (bien o mal): estrella, monedas y festejo del Pompon.
func _mark(right: bool) -> void:
	results.append(right)
	if right:
		earned += coins_per_round
		_coin_label.text = str(earned)
		if is_instance_valid(_pet):
			_pet.celebrate(3)
	_dots.results = results
	_dots.queue_redraw()


## Barra de crecimiento que sube con un "+x" y su brotecito flotando (para que se vea que ayudo a crecer).
func _growth_bar(before: float, gain: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 76)
	var green := Color("5fc77f")
	var bar := StatBar.new().setup("", "sprout", green)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -48
	bar.text = "Crecimiento"
	bar.font_size = 22
	bar.value = before
	holder.add_child(bar)
	var tw := bar.create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(bar, "value", before + gain, 0.8).set_trans(Tween.TRANS_SINE)
	if gain >= 0.05:
		var chip := RewardChip.new().setup("sprout", "+%.1f" % gain, green)
		chip.position = Vector2(40, 0)
		chip.modulate.a = 0.0
		holder.add_child(chip)
		var pop := chip.create_tween()
		pop.tween_interval(0.5)
		pop.tween_property(chip, "modulate:a", 1.0, 0.2)
		pop.parallel().tween_property(chip, "position:y", -14.0, 0.7).from(8.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return holder


func _leave() -> void:
	get_tree().change_scene_to_file("res://scenes/minigames.tscn")


## Tarjeta final: estrellas, premios (monedas, crecimiento, alegria, confianza) y los botones.
func _show_result(title: String, rounds_ok: int, rounds_total: int) -> void:
	if _layer != null:
		return
	var growth_before := 0.0
	if GameState.pompon != null:
		growth_before = PomponGrowth.quality(GameState.pompon, int(Time.get_unix_time_from_system()))
	GameState.reward_minigame(earned, game_id, float(rounds_ok) / maxf(float(rounds_total), 1.0))
	var growth_gain := maxf(GameState.last_minigame_gain, 0.0)
	_layer = Control.new()
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.25, 0.12, 0.2, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 40, Color("ffb3d1"), 6, 16))
	_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_label(title, 52, Color("d6336c")))
	var stars := StarDots.new()
	stars.total = rounds_total
	stars.results = []
	for i in rounds_total:
		stars.results.append(i < rounds_ok)
	stars.custom_minimum_size = Vector2(0, 54)
	box.add_child(stars)
	var rewards := HBoxContainer.new()
	rewards.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards.add_theme_constant_override("separation", 18)
	box.add_child(rewards)
	rewards.add_child(RewardChip.new().setup("coin", "+%d" % earned, Color("ffb938")))
	if growth_gain >= 0.05:
		rewards.add_child(RewardChip.new().setup("sprout", "+%.1f" % growth_gain, Color("5fc77f")))
	var rewards2 := HBoxContainer.new()
	rewards2.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards2.add_theme_constant_override("separation", 18)
	box.add_child(rewards2)
	rewards2.add_child(RewardChip.new().setup("game", "+15", Hud.STAT_COLORS["diversion"]))
	rewards2.add_child(RewardChip.new().setup("heart", "+3", Hud.STAT_COLORS["amor"]))
	box.add_child(_label("¡Tu Pompon aprendió algo nuevo!", 26, Color("a0527a")))
	box.add_child(_growth_bar(growth_before, growth_gain))
	var again := Button.new()
	again.text = "Jugar otra vez"
	again.custom_minimum_size = Vector2(0, 88)
	Hud.style_primary(again, 36)
	again.pressed.connect(func(): get_tree().reload_current_scene())
	box.add_child(again)
	var leave := Button.new()
	leave.text = "Salir"
	leave.custom_minimum_size = Vector2(0, 76)
	Hud.style_soft(leave, 30)
	leave.pressed.connect(_leave)
	box.add_child(leave)
	if is_instance_valid(_pet):
		_pet.celebrate(8)
