extends SceneTree
## Tazones de la tienda: se compran, se usan enseguida al comer o beber, se pueden quitar y se guardan.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var catalog: GDScript = load("res://scripts/catalog.gd")
	var bowls: Array = catalog.ITEMS.filter(func(i): return i["category"] in ["bowl_food", "bowl_water"])
	print("tazones en el catalogo: ", bowls.size(), " | comida=", bowls.filter(func(i): return i["category"] == "bowl_food").size(), " agua=", bowls.filter(func(i): return i["category"] == "bowl_water").size())
	print("todos con nombre, precio y estilo de dibujo: ", bowls.all(func(i): return i["name"] != "" and i["price"] > 0 and load("res://scripts/bowl_art.gd").STYLES.has(i["id"])))
	gs.new_pompon("Felino", "Hembra")
	gs.pompon.hatched = true
	gs.owned = []
	gs.equipped = {}
	gs.coins = 100
	print("sin comprar: tazon de siempre=", gs.equipped.get("bowl_food", "") == "")
	print("comprar tazon de comida: ", gs.buy("bowl_food_pink"), " | se usa solo=", gs.equipped.get("bowl_food", "") == "bowl_food_pink")
	print("comprar tazon de agua: ", gs.buy("bowl_water_fish"), " | se usa solo=", gs.equipped.get("bowl_water", "") == "bowl_water_fish", " | monedas=", gs.coins)
	gs.buy("bowl_food_star")
	print("tercer tazon (de comida) reemplaza al anterior: ", gs.equipped.get("bowl_food", ""))
	gs.equip("bowl_food_star")
	print("tocar de nuevo lo quita (vuelve el de siempre): ", gs.equipped.get("bowl_food", "") == "")
	gs.equip("bowl_food_pink")
	gs.save_game()
	gs.equipped = {}
	gs.load_game()
	print("se guardan: ", gs.equipped)

	# la animacion usa el tazon equipado (sin errores al dibujar)
	var holder := Control.new()
	root.add_child(holder)
	var v := PomponView.new()
	holder.add_child(v)
	v.size = Vector2(200, 300)
	v.set_pompon(gs.pompon, gs.equipped)
	v.act("eat")
	await create_timer(0.5).timeout
	v.act("drink")
	await create_timer(0.5).timeout
	print("dibuja comer y beber con tazones lindos: ok")
	quit()
