extends SceneTree
## Herramienta de prueba: desliza con el dedo (toques simulados de celular) las listas del juego y mide
## si se mueven. Hay que correrla con ventana (no --headless) porque necesita la pantalla del juego:
##   godot --path . --resolution 540x960 --script tools/touch_scroll_check.gd
## OJO: cambia la partida local (respaldar user://save.json* antes y restaurar despues).

var k := 1.0   # de la pantalla del juego (720 de ancho) a la ventana


func _touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos * k
	e.pressed = pressed
	Input.parse_input_event(e)


## Arrastra de `from` a `to` (en coordenadas del juego) en `steps` cuadros.
func drag(from: Vector2, to: Vector2, steps := 12, release := true) -> void:
	_touch(from, true)
	await process_frame
	for i in range(1, steps + 1):
		var e := InputEventScreenDrag.new()
		e.index = 0
		e.position = from.lerp(to, float(i) / steps) * k
		e.relative = (to - from) / steps * k
		Input.parse_input_event(e)
		await process_frame
	if release:
		_touch(to, false)
		await process_frame


func tap(pos: Vector2) -> void:
	_touch(pos, true)
	await process_frame
	await process_frame
	_touch(pos, false)
	await process_frame


func _scene(path: String) -> Control:
	for c in root.get_children():
		if c is Control:
			c.queue_free()
	await process_frame
	var s: Control = load(path).instantiate()
	root.add_child(s)
	await create_timer(0.5).timeout
	return s


func _main_scroll(s: Control) -> ScrollContainer:
	var best: ScrollContainer = null
	for sc in s.find_children("*", "ScrollContainer", true, false):
		if best == null or sc.size.y * sc.size.x > best.size.y * best.size.x:
			best = sc
	return best


func _initialize() -> void:
	await process_frame
	var touch := root.get_node("TouchScroll")
	touch.force = true
	k = float(root.size.x) / 720.0
	var gs := root.get_node("GameState")
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.pompon.born_at = int(Time.get_unix_time_from_system()) - 30 * 86400
	gs.coins = 5000
	gs.owned = ["furn_crib"]
	gs.daily_gift_day = Missions.today(int(Time.get_unix_time_from_system()))
	gs.tutorial["off"] = true

	# ---------- tienda
	var shop := await _scene("res://scenes/shop.tscn")
	var scroll := _main_scroll(shop)
	var r := scroll.get_global_rect()
	var card_point := Vector2(r.position.x + r.size.x * 0.25, r.position.y + r.size.y * 0.55)
	var ok := true
	var moves := []
	for i in 4:
		var before := scroll.scroll_vertical
		await drag(card_point, card_point - Vector2(0, 300))
		await create_timer(0.3).timeout
		moves.append(scroll.scroll_vertical - before)
		var at_end: bool = before >= scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page - 1
		ok = ok and (scroll.scroll_vertical > before or at_end)
	print("tienda, arrastrar desde una tarjeta 4 veces: ", moves, " | se mueve cada vez (hasta el final): ", ok)
	scroll.scroll_vertical = 0
	await create_timer(0.2).timeout
	# desde el boton de comprar (no tiene que comprar)
	var coins_before: int = gs.coins
	var buy: Button = null
	for b in shop.find_children("*", "Button", true, false):
		if b.get_global_rect().get_center().y > r.position.y + 200 and b.get_global_rect().get_center().y < r.end.y - 100 and not b.disabled and b.custom_minimum_size.y == 72:
			buy = b
			break
	var bp := buy.get_global_rect().get_center()
	var before2 := scroll.scroll_vertical
	await drag(bp, bp - Vector2(0, 260))
	await create_timer(0.3).timeout
	print("arrastrar empezando sobre 'Comprar': se movio ", scroll.scroll_vertical - before2, " px | no compro nada: ", gs.coins == coins_before)
	# hacia abajo de nuevo
	var before3 := scroll.scroll_vertical
	await drag(card_point - Vector2(0, 300), card_point)
	await create_timer(0.3).timeout
	print("deslizar para abajo vuelve: ", scroll.scroll_vertical < before3)
	# un toque rapido sobre comprar si compra
	scroll.scroll_vertical = 0
	await create_timer(0.2).timeout
	for b in shop.find_children("*", "Button", true, false):
		if b.custom_minimum_size.y == 72 and not b.disabled and b.is_visible_in_tree() and b.get_global_rect().end.y < r.end.y:
			buy = b
			break
	var c2: int = gs.coins
	await tap(buy.get_global_rect().get_center())
	await create_timer(0.3).timeout
	print("un toque en 'Comprar' compra: ", gs.coins < c2)
	# un deslizar rapido sigue con inercia
	scroll.scroll_vertical = 0
	await create_timer(0.2).timeout
	await drag(card_point, card_point - Vector2(0, 220), 4)
	var right_after := scroll.scroll_vertical
	await create_timer(0.6).timeout
	print("inercia: al soltar ", right_after, " -> despues ", scroll.scroll_vertical, " (sigue un poco)")

	# ---------- otras pantallas con listas
	for path in ["res://scenes/missions.tscn", "res://scenes/neighbors.tscn", "res://scenes/minigames.tscn", "res://scenes/wardrobe.tscn"]:
		var s := await _scene(path)
		var sc := _main_scroll(s)
		if sc == null:
			print(path.get_file(), ": sin lista")
			continue
		var rr := sc.get_global_rect()
		var p := Vector2(rr.get_center().x, rr.position.y + rr.size.y * 0.7)
		var b0 := sc.scroll_vertical
		await drag(p, p - Vector2(0, 250))
		await create_timer(0.3).timeout
		var can: bool = sc.get_v_scroll_bar().max_value - sc.get_v_scroll_bar().page > 1.0
		print(path.get_file(), ": ", b0, " -> ", sc.scroll_vertical, " | tiene para deslizar: ", can)
	# el pueblo (de costado)
	var town := await _scene("res://scenes/town.tscn")
	var tsc := _main_scroll(town)
	var h0 := tsc.scroll_horizontal
	await drag(Vector2(500, 500), Vector2(150, 500))
	await create_timer(0.3).timeout
	print("pueblo de costado: ", h0, " -> ", tsc.scroll_horizontal)

	# ---------- con una ventana encima no se mueve la lista de abajo
	var shop2 := await _scene("res://scenes/shop.tscn")
	var sc2 := _main_scroll(shop2)
	var n := BigNotice.new(600.0)
	shop2.add_child(n)
	n.title("Una ventana encima")
	n.button("Ok", n.close)
	await process_frame
	var rr2 := sc2.get_global_rect()
	var b1 := sc2.scroll_vertical
	await drag(Vector2(80, rr2.position.y + rr2.size.y * 0.8), Vector2(80, rr2.position.y + rr2.size.y * 0.8 - 300))
	await create_timer(0.3).timeout
	print("con un cartel encima la lista no se mueve: ", sc2.scroll_vertical == b1)
	quit()
