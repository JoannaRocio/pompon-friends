extends SceneTree
## Vestidor: solapas, tarjetas por solapa, poner y quitar, y el aviso cuando no hay nada.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.owned = ["hat_bow", "glasses_round", "shirt_dress", "wall_stars", "floor_wood", "bowl_food_star"]
	gs.equipped = {}
	var W = load("res://scripts/wardrobe.gd")
	W._tab = "wear"
	var scene: Control = load("res://scenes/wardrobe.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	print("ropa: tarjetas=", scene._grid.get_child_count(), " (esperado 3) vacio=", scene._empty.visible)

	scene._toggle("hat_bow")
	await process_frame
	print("poner gorro: ", gs.equipped.get("hat", ""), " (esperado hat_bow)")
	scene._toggle("hat_bow")
	await process_frame
	print("quitar gorro: ", gs.equipped.has("hat"), " (esperado false)")

	W._tab = "room"
	scene._rebuild()
	await process_frame
	print("cuarto: tarjetas=", scene._grid.get_child_count(), " (esperado 2) chip=", scene._room_chip.visible)
	scene._toggle("wall_stars")
	print("pared: ", gs.equipped.get("wall", ""), " (esperado wall_stars)")

	W._tab = "bowls"
	scene._rebuild()
	await process_frame
	print("tazones: tarjetas=", scene._grid.get_child_count(), " (esperado 1)")

	gs.owned = ["hat_bow"]
	scene._rebuild()
	await process_frame
	print("sin tazones: vacio=", scene._empty.visible, " (esperado true)")
	scene.queue_free()
	quit()
