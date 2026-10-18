extends SceneTree
## Intro de Jojo Games: aparece el logo, se anima a tamano completo y se puede saltar.


func _initialize() -> void:
	await process_frame
	var intro: Control = load("res://scenes/intro.tscn").instantiate()
	root.add_child(intro)
	await create_timer(0.15).timeout
	print("al empezar el logo esta escondido: escala=", intro._logo.scale.x < 0.2)
	await create_timer(1.3).timeout
	print("el logo ya esta a tamano completo: escala=", snappedf(intro._logo.scale.x, 0.05), " | rotacion=", snappedf(intro._logo.rotation, 0.05))
	var rect: Rect2 = intro._logo.get_global_rect()
	print("ancho del logo respecto a la pantalla: ", snappedf(rect.size.x / 720.0, 0.01), " | centrado en x=", absf(rect.get_center().x - intro.size.x * 0.5) < 4.0)
	print("textura del logo con transparencia: ", intro.LOGO.get_image().detect_alpha() != Image.ALPHA_NONE)
	intro._go_next()
	print("tocar salta la intro: done=", intro._done)
	quit()
