extends SceneTree
## Herramienta de desarrollo: una hoja con el dibujo de cada objeto del catalogo (para revisar el arte).
## No guarda la partida. Uso (con ventana): Godot_*win64.exe --path . --script tools/catalog_sheet.gd -- <archivo.png> [nuevos|todo|muebles]


func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://catalogo.png")
	var which: String = args[1] if args.size() > 1 else "todo"
	var ids: Array = []
	var seen_new := false
	for it in Catalog.ITEMS:
		var id: String = it["id"]
		if id == "furn_chair":
			seen_new = true
		if id.begins_with("hat_crown_diamond"):
			seen_new = false
		if which == "nuevos" and not seen_new:
			continue
		if which == "muebles" and not (it["category"] in ["furniture", "deco", "wall", "floor"]):
			continue
		ids.append(id)
	var cols := 6
	var cell := Vector2(150, 176)
	var rows := int(ceil(ids.size() / float(cols)))
	var sv := SubViewport.new()
	sv.size = Vector2i(int(cell.x * cols), int(cell.y * rows))
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	var bg := ColorRect.new()
	bg.color = Color("fff1de")
	bg.size = Vector2(sv.size)
	sv.add_child(bg)
	for i in ids.size():
		var icon := ItemIcon.new()
		icon.set_item(ids[i], 132.0)
		icon.position = Vector2((i % cols) * cell.x + 9.0, (i / cols) * cell.y + 4.0)
		sv.add_child(icon)
		var l := Label.new()
		l.text = Catalog.item_name(ids[i])
		l.position = Vector2((i % cols) * cell.x, (i / cols) * cell.y + 138.0)
		l.size = Vector2(cell.x, 30)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color("5b3a4a"))
		l.clip_text = true
		sv.add_child(l)
	for k in 4:
		await process_frame
	var img := sv.get_texture().get_image()
	print("guardado: ", out, " -> ", img.save_png(out), " ", ids.size(), " objetos")
	quit()
