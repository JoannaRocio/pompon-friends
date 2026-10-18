extends SceneTree
## Juego de ordenar del trabajo: los objetos aparecen, se arrastran a su lugar (estante, vaso, canasta);
## si se sueltan en el lugar equivocado vuelven solos y no pasa nada malo.


func _mouse(field: Control, pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	field._gui_input(e)


func _move(field: Control, pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	field._gui_input(e)


func _initialize() -> void:
	await process_frame
	var field: Control = load("res://scripts/sort_field.gd").new()
	var holder := Control.new()
	root.add_child(holder)
	holder.add_child(field)
	field.size = Vector2(680, 450)
	await process_frame
	print("zona de objetos arriba de los 3 lugares: ", field.item_zone().end.y < field.bin_rect(0).position.y)
	var results := []
	field.sorted.connect(func(ok: bool, kind: String): results.append([ok, kind]))
	await create_timer(2.0).timeout
	print("aparecen objetos solos: ", field.items.size() >= 1)

	# arrastrar al lugar correcto
	var it: Dictionary = field.items[0]
	var kind: String = it["kind"]
	var right: int = field.KINDS.find(kind)
	_mouse(field, it["pos"], true)
	_move(field, field.bin_rect(right).get_center())
	_mouse(field, field.bin_rect(right).get_center(), false)
	await create_timer(0.6).timeout
	print("bien ordenado (", kind, "): resultados=", results, " | en el lugar=", field.bin_count[right], " | total=", field.sorted_total)

	# arrastrar al lugar equivocado: vuelve solo
	await create_timer(2.5).timeout
	var it2: Dictionary = field.items[0]
	var wrong: int = (field.KINDS.find(it2["kind"]) + 1) % 3
	var home: Vector2 = it2["pos"]
	_mouse(field, it2["pos"], true)
	_move(field, field.bin_rect(wrong).get_center())
	_mouse(field, field.bin_rect(wrong).get_center(), false)
	await create_timer(0.8).timeout
	print("lugar equivocado: avisa sin castigo=", results.size() == 2 and results[1][0] == false, " | vuelve a su sitio=", (it2["pos"] as Vector2).distance_to(home) < 4.0, " | sigue sin ordenar=", field.sorted_total)

	# soltar en el aire: se queda donde esta
	var it3: Dictionary = field.items[0]
	_mouse(field, it3["pos"], true)
	_move(field, Vector2(300, 90))
	_mouse(field, Vector2(300, 90), false)
	print("soltar en el aire: se queda=", (it3["pos"] as Vector2).distance_to(Vector2(300, 90)) < 80.0)

	# arrastrar mientras otro objeto termina de entrar (la lista cambia): no debe fallar
	while field.items.size() < 2:
		await create_timer(0.5).timeout
	var last_it: Dictionary = field.items[field.items.size() - 1]
	_mouse(field, last_it["pos"], true)
	field.items[0]["state"] = "done"
	await process_frame
	await process_frame
	_move(field, field.bin_rect(0).get_center())
	_mouse(field, field.bin_rect(0).get_center(), false)
	await process_frame
	print("arrastre estable aunque cambie la lista: ", field.items.size() >= 1)

	# en pausa no se juega
	field.paused = true
	var before: int = field.items.size()
	await create_timer(3.0).timeout
	print("en pausa no aparecen objetos: ", field.items.size() == before)
	quit()
