class_name TeacherCard
extends PanelContainer
## Ficha de profesor/a: nombre, puesto, nivel (estrella), cuanto paga cada turno y cuanto falta para
## ascender. Se ve en las ofertas de empleo, al conseguir el primer trabajo y al ascender.

signal change_pressed   # tocar T.s("Cambiar") (nombre y pronombres)

const GOLD := Color("ffcf3f")

var _level := 1
var _star: Control


## `level` = nivel a mostrar (-1: el actual). `can_change` agrega el boton T.s("Cambiar").
func setup(level := -1, can_change := false) -> TeacherCard:
	_level = GameState.career_level() if level < 0 else level
	add_theme_stylebox_override("panel", Hud.card(Color("fffdf6"), 32, Color("f2c94c"), 5, 8))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	col.add_child(top)
	var badge := Control.new()  # maletin de trabajo en un circulo
	badge.custom_minimum_size = Vector2(84, 84)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.draw.connect(func():
		var c := badge.size * 0.5
		badge.draw_circle(c, 42.0, Color("e0609e"))
		Hud.draw_icon(badge, "case", c, 54.0, Color.WHITE, Color("e0609e").darkened(0.25)))
	top.add_child(badge)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	top.add_child(info)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	info.add_child(name_row)
	var who := Label.new()
	who.text = Jobs.full_title(GameState.player_title, GameState.player_name)
	who.add_theme_font_size_override("font_size", 30)
	who.add_theme_color_override("font_color", Hud.INK)
	name_row.add_child(who)
	if can_change:
		var change := Button.new()
		change.text = T.s("Cambiar")
		change.custom_minimum_size = Vector2(0, 44)
		change.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		change.focus_mode = Control.FOCUS_NONE
		Hud.style_soft(change, 18)
		change.pressed.connect(change_pressed.emit)
		name_row.add_child(change)
	var job := Label.new()
	job.text = T.s("%s · Escuela Pompon") % subjects()
	job.add_theme_font_size_override("font_size", 24)
	job.add_theme_color_override("font_color", Color("a0527a"))
	info.add_child(job)
	_star = Control.new()
	_star.custom_minimum_size = Vector2(88, 88)
	_star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_star.draw.connect(_draw_star)
	top.add_child(_star)

	# paga por turno y cuanto falta para ascender
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	col.add_child(bottom)
	var pay := PanelContainer.new()
	pay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pay.add_theme_stylebox_override("panel", Hud.card(Color("fff3d1"), 24, Color("f2c94c"), 2, 0))
	var pay_row := HBoxContainer.new()
	pay_row.add_theme_constant_override("separation", 6)
	pay_row.add_child(Hud.coin_icon(30.0))
	var pay_label := Label.new()
	pay_label.text = T.s("+%d por turno") % Jobs.pay_for_level(_level)
	pay_label.add_theme_font_size_override("font_size", 24)
	pay_label.add_theme_color_override("font_color", Color("8a6d00"))
	pay_row.add_child(pay_label)
	pay.add_child(pay_row)
	bottom.add_child(pay)
	var bar := StatBar.new().setup("", "star", GOLD)
	bar.custom_minimum_size = Vector2(0, 40)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.font_size = 18
	bar.warn_low = false
	if _level >= Jobs.CAREER_MAX:
		bar.max_value = 1.0
		bar.value = 1.0
		bar.text = T.s("¡Nivel máximo!")
	else:
		var start := Jobs.shifts_for_level(_level)
		var goal := Jobs.shifts_for_level(_level + 1)
		var done := clampi(GameState.jobs_done - start, 0, goal - start)
		bar.max_value = float(goal - start)
		bar.value = float(done)
		var left := goal - start - done
		bar.text = T.s("Nivel %d en %d %s") % [_level + 1, left, T.s("turno") if left == 1 else T.s("turnos")]
	bottom.add_child(bar)
	return self


## Las materias que ya dio (sin clases todavia: la que eligio en el periodico).
static func subjects() -> String:
	var names: Array = []
	for s in Jobs.SUBJECTS:
		if GameState.taught(s):
			names.append(Jobs.subject_name(s))
	if names.is_empty():
		return Jobs.subject_name(Jobs.current)
	if names.size() == 1:
		return names[0]
	var last: String = names.pop_back()
	return "%s %s %s" % [", ".join(names), T.s("e") if last.begins_with("I") else T.s("y"), last]


func _draw_star() -> void:
	var c := _star.size * 0.5
	var pts := PackedVector2Array()
	for i in 20:
		var a := -PI / 2.0 + PI * i / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * (44.0 if i % 2 == 0 else 32.0))
	_star.draw_colored_polygon(pts, GOLD)
	pts.append(pts[0])
	_star.draw_polyline(pts, Color("b87400"), 4.0, true)
	var font := _star.get_theme_default_font()
	var fs := 34 if _level < 10 else (28 if _level < 100 else 22)
	_star.draw_string(font, c + Vector2(-44, fs * 0.36), str(_level), HORIZONTAL_ALIGNMENT_CENTER, 88, fs, Color("7a4a00"))
