extends SceneTree
## Genera los iconos de la app a partir de la gatita Pompon:
##   assets/icon.png (512)            - icono principal y de la tienda
##   assets/icon_192.png              - icono clasico de Android
##   assets/icon_fg.png / icon_bg.png - icono adaptativo (432, primer plano transparente + fondo)
## Uso: godot --path . --rendering-method gl_compatibility --resolution 512x512 --script tools/make_icon.gd

const PINK := Color("ffd6e3")
const STAR_TINTS := [Color("fff3c4"), Color("e9d9ff"), Color("d7f3e6")]


func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var cat := PomponView.make_sample("Felino", Color("ffb3cc"), Color("fff0f5"), "brillantes", "sonrisa", "redonda")

	var main_img := await _render(Vector2i(512, 512), false, func(sv):
		_background(sv, 512.0)
		_cat(sv, cat, Vector2(36, 34), 440.0))
	print("icon.png ", main_img.save_png("res://assets/icon.png"))
	var small := main_img.duplicate()
	small.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	print("icon_192.png ", small.save_png("res://assets/icon_192.png"))

	# adaptativo: el personaje debe quedar dentro del 66% central (zona segura de Android)
	var fg := await _render(Vector2i(432, 432), true, func(sv):
		_cat(sv, cat, Vector2(72, 66), 290.0))
	print("icon_fg.png ", fg.save_png("res://assets/icon_fg.png"))
	var bg := await _render(Vector2i(432, 432), false, func(sv):
		_background(sv, 432.0))
	print("icon_bg.png ", bg.save_png("res://assets/icon_bg.png"))
	quit()


func _render(size: Vector2i, transparent: bool, build: Callable) -> Image:
	var sv := SubViewport.new()
	sv.size = size
	sv.transparent_bg = transparent
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sv)
	build.call(sv)
	await create_timer(0.5).timeout
	var img := sv.get_texture().get_image()
	sv.queue_free()
	return img


func _background(parent: Node, side: float) -> void:
	var bg := ColorRect.new()
	bg.color = PINK
	bg.size = Vector2(side, side)
	parent.add_child(bg)
	for i in 14:
		var star := Label.new()
		star.text = "*"
		star.add_theme_font_size_override("font_size", int(side / 7.0))
		star.add_theme_color_override("font_color", STAR_TINTS[i % 3])
		star.position = Vector2((i * 97) % int(side * 0.94), (i * 61) % int(side * 0.86))
		bg.add_child(star)


func _cat(parent: Node, pompon: Pompon, pos: Vector2, side: float) -> void:
	var v := PomponView.new()
	v.animated = false
	v.size = Vector2(side, side)
	v.position = pos
	v.set_pompon(pompon, {"hat": "hat_bow"})
	parent.add_child(v)
