class_name LessonView
extends PanelContainer
## Tarjeta con la leccion de un nivel antes de practicarlo: un truco corto y un ejemplo en la pizarra
## (sirve para matematicas y para ingles).

signal closed


func setup(camino: String, level: int) -> void:
	var problems := Jobs.problems(Jobs.subject_of(camino))
	var data: Dictionary = problems.lesson(camino, level)
	add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 40, Color("ffb3d1"), 6, 16))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var head := Label.new()
	head.text = "Nivel %d" % level
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 44)
	head.add_theme_color_override("font_color", Color("d6336c"))
	box.add_child(head)
	var sub := Label.new()
	sub.text = problems.level_name(camino, level)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color("a0527a"))
	box.add_child(sub)

	if data.has("flags"):   # geografia: las banderas de la region, para mirarlas antes de jugar
		var flags := HFlowContainer.new()
		flags.alignment = FlowContainer.ALIGNMENT_CENTER
		flags.add_theme_constant_override("h_separation", 8)
		flags.add_theme_constant_override("v_separation", 8)
		box.add_child(flags)
		for id in data["flags"]:
			var f := FlagArt.new()
			f.custom_minimum_size = Vector2(72, 48)
			f.show_flag(id)
			flags.add_child(f)
	var lines: Array = data["lines"]
	var first := String(lines[0]).split("\n")
	var trick := Label.new()
	trick.text = first[0]
	trick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trick.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trick.add_theme_font_size_override("font_size", 36)
	box.add_child(trick)

	# la pizarra con el ejemplo
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", Hud.card(Color("4f8a76"), 30, Color("c99560"), 8, 8))
	box.add_child(board)
	var chalk := VBoxContainer.new()
	chalk.add_theme_constant_override("separation", 10)
	board.add_child(chalk)
	for i in range(1, first.size()):
		chalk.add_child(_chalk(first[i], 44 if first[i].length() <= 14 else (36 if first[i].length() <= 22 else 30)))
	for i in range(1, lines.size()):  # tablas para repasar
		chalk.add_child(_chalk(String(lines[i]), 22, true))
	if first.size() == 1 and lines.size() == 1:
		board.visible = false

	var ok := Button.new()
	ok.text = "¡Entendido!"
	ok.custom_minimum_size = Vector2(0, 88)
	Hud.style_primary(ok, 38)
	ok.pressed.connect(func(): closed.emit())
	box.add_child(ok)


func _chalk(text: String, font_size: int, small := false) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("fffbe8") if not small else Color("e6f4ea"))
	return l
