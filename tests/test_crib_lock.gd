extends SceneTree
## Primera compra: mientras el huevo espera su cuna, la tienda solo deja comprar la cuna
## (el resto queda apagado y una flecha señala la cuna). Despues, todo se puede comprar.


func _buy_buttons(shop: Control) -> Array:
	var out := []
	for card in shop._grid.get_children():
		out.append(card.get_meta("buy"))
	return out


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon("Conejo", "Hembra")
	gs.owned = []
	gs.placed = []
	gs.coins = 60
	var shop: Control = load("res://scenes/shop.tscn").instantiate()
	root.add_child(shop)
	await create_timer(0.3).timeout
	var buttons := _buy_buttons(shop)
	var crib_btn: Button = buttons[0]
	print("la cuna va primera y se puede comprar: ", crib_btn.text, " | activa=", not crib_btn.disabled)
	var others_off := true
	for i in range(1, buttons.size()):
		others_off = others_off and (buttons[i] as Button).disabled
	print("lo demas esta apagado (", buttons.size() - 1, " items): ", others_off)
	print("la flecha señala la cuna: visible=", shop._arrow.visible, " | objetivo=", shop._arrow.target == crib_btn)

	# sin monedas suficientes: nada se puede comprar y no hay flecha
	gs.coins = 30
	shop._rebuild()
	await process_frame
	var b2 := _buy_buttons(shop)
	print("con 30 monedas todo apagado: ", b2.all(func(b): return b.disabled), " | sin flecha=", not shop._arrow.visible)

	# comprar la cuna destraba la tienda
	gs.coins = 100
	shop._rebuild()
	await process_frame
	print("comprar la cuna: ", gs.buy("furn_crib"))
	shop._rebuild()
	await process_frame
	var b3 := _buy_buttons(shop)
	var open_ok := true
	for b in b3:
		var btn: Button = b
		if not btn.disabled:
			open_ok = true
	var affordable := 0
	for b in b3:
		if not (b as Button).disabled:
			affordable += 1
	print("con la cuna comprada ya se puede comprar de todo: items activos=", affordable > 0, " | sin flecha=", not shop._arrow.visible)
	quit()
