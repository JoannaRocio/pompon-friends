extends SceneTree


func _initialize() -> void:
	var gs := root.get_node("GameState")
	await process_frame  # deja que el autoload corra su _ready antes de usarlo
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.coins = 100
	gs.owned = []
	gs.mission_progress = {}
	gs.missions_claimed = []
	gs.pass_xp = 0
	gs.pass_claimed = []

	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await process_frame

	# Comida: la gourmet cuesta 12 y suma confianza (+5).
	gs.pompon.stats["alimentacion"] = 10.0
	gs.pompon.stats["amor"] = 50.0
	h._on_food(h.FOODS[2])
	print("gourmet: monedas=", gs.coins, " comida=", gs.pompon.stats["alimentacion"], " confianza=", gs.pompon.stats["amor"])
	h._on_food(h.FOODS[0])
	print("basica: monedas=", gs.coins, " care=", gs.mission_progress.get("care"))
	for i in 3:
		h._on_action("Beber")
	print("care tras 5 usos: ", gs.mission_progress.get("care"), " lista=", gs.mission_done("care"))
	print("reclamar care: ", gs.claim_mission("care"), " otra vez: ", gs.claim_mission("care"), " monedas=", gs.coins, " xp=", gs.pass_xp)

	gs.reward_minigame(0)
	gs.reward_minigame(0)
	gs.buy("hat_cap")
	print("minigame/buy listos: ", gs.mission_done("minigame"), gs.mission_done("buy"))
	gs.claim_mission("minigame")
	gs.claim_mission("buy")
	print("xp total=", gs.pass_xp)
	print("nivel1 reclamar: ", gs.claim_pass_tier(0), " nivel3 sin xp: ", gs.claim_pass_tier(2))
	gs.pass_xp = 100
	print("nivel3 con xp (corona): ", gs.claim_pass_tier(2), " owned corona=", gs.owned.has("hat_crown"))

	gs.save_game()
	gs.mission_progress = {}
	gs.pass_claimed = []
	gs.load_game()
	print("recarga: claimed=", gs.missions_claimed, " pass_claimed=", gs.pass_claimed, " xp=", gs.pass_xp)

	# Cambio de dia: las misiones se reinician, el pase no.
	gs.missions_day -= 1
	gs.track("care", 0)
	print("dia nuevo: claimed=", gs.missions_claimed, " progreso=", gs.mission_progress, " xp conserva=", gs.pass_xp)

	var m: Control = load("res://scenes/missions.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	print("pantalla misiones ok")
	quit()
