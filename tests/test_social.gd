extends SceneTree


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.pompon.born_at = int(Time.get_unix_time_from_system()) - 90 * 86400
	gs.last_stage = 4
	gs.coins = 100
	gs.friend_points = {}
	gs.friend_actions = {}
	gs.daily_gift_day = 0
	gs.gift_streak = 0

	# --- vecinos: determinista y completo
	var load_nb: GDScript = load("res://scripts/neighbors.gd")
	for entry in load_nb.ROSTER:
		var a: Dictionary = load_nb.build(entry)
		var b: Dictionary = load_nb.build(entry)
		var same: bool = a["pompon"].color_primary == b["pompon"].color_primary and a["wall"] == b["wall"] and a["placed"] == b["placed"]
		var req: String = Catalog.required_furniture(entry["species"])["id"]
		var has_req := false
		for p in a["placed"]:
			if p["id"] == req:
				has_req = true
		print(entry["name"], ": igual en cada carga=", same, " mueble clave=", has_req, " items=", a["placed"].size(), " ropa=", a["equipped"].size())

	# --- amistad: 1 punto por dia por visitar y por cada actividad; repetir es gratis y sin puntos
	var v1: Dictionary = gs.friend_visit("luna")
	var v2: Dictionary = gs.friend_visit("luna")
	print("visita: pts=", v1["pts"], " (esperado 1) otra visita hoy: pts=", v2["pts"], " (esperado 0) mision visitar=", gs.mission_done("visit"))
	var r1: Dictionary = gs.friend_action("luna", "pet")
	var r2: Dictionary = gs.friend_action("luna", "pet")
	print("acariciar: pts=", r1["pts"], " repetir hoy: ok=", r2["ok"], " pts=", r2["pts"], " (esperado true 0)")
	print("puntos con Luna: ", gs.friend_points["luna"], " (esperado 2)")
	var coins_before: int = gs.coins
	var r3: Dictionary = gs.friend_action("luna", "gift")
	var r3b: Dictionary = gs.friend_action("luna", "gift")
	print("regalo: pts=", r3["pts"], " cobra=", coins_before - gs.coins, " (esperado 5; repetir no cobra) repetir pts=", r3b["pts"])
	var logic_before := PomponSkills.xp(gs.pompon, "logica")
	var r4: Dictionary = gs.friend_action("luna", "play")
	gs.friend_action("luna", "play")
	print("jugar: pts=", r4["pts"], " logica +", PomponSkills.xp(gs.pompon, "logica") - logic_before, " (esperado ", load_nb.SKILL_XP, " una sola vez) puntos=", gs.friend_points["luna"], " (esperado 4)")
	gs.coins = 2
	var r5: Dictionary = gs.friend_action("nube", "gift")
	print("sin monedas: ok=", r5["ok"], " msg='", r5["msg"], "'")
	gs.pompon.stats["amistad"] = 10.0
	print("socializando: ", gs.friend_watch_reward("luna"), " (esperado 20) socializar=", gs.pompon.stats["amistad"], " (esperado 100) otra vez hoy: ", gs.friend_watch_reward("luna"), " (esperado 0)")
	print("conocidos: ", gs.has_met("luna"), " -> ", (func(): gs.mark_met("luna"); return gs.has_met("luna")).call())
	print("niveles: 0=", load_nb.level_name(0), " 30=", load_nb.level_name(30), " 50=", load_nb.level_name(50), " 99=", load_nb.level_name(99))
	# otro dia: vuelve a sumar
	for k in gs.friend_actions:
		gs.friend_actions[k] = int(gs.friend_actions[k]) - 1
	print("al dia siguiente: pts=", gs.friend_action("luna", "pet")["pts"], " (esperado 1)")
	gs.friend_points["luna"] = 49
	gs.coins = 0
	gs.friend_actions.clear()
	print("hito 50: bonus=", gs.friend_action("luna", "pet")["bonus"], " monedas=", gs.coins, " (esperado 20)")
	gs.friend_points["luna"] = 100
	gs.friend_actions.clear()
	gs.friend_action("luna", "play")
	print("tope de amistad: ", gs.friend_points["luna"], " (max ", load_nb.MAX_POINTS, ")")
	gs.pompon = null
	print("sin Pompon: ", gs.friend_action("luna", "pet")["msg"])
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"

	# --- regalo diario
	gs.coins = 0
	var g1: int = gs.claim_daily_gift()
	var g2: int = gs.claim_daily_gift()
	print("regalo hoy: ", g1, " repetir: ", g2, " racha=", gs.gift_streak)
	gs.daily_gift_day -= 1  # como si ayer hubieras entrado
	var g3: int = gs.claim_daily_gift()
	print("al dia siguiente seguido: ", g3, " racha=", gs.gift_streak)
	gs.daily_gift_day -= 5  # faltaste varios dias: vuelve a 10, sin castigo
	var g4: int = gs.claim_daily_gift()
	print("tras faltar dias: ", g4, " racha=", gs.gift_streak)
	gs.gift_streak = 5
	gs.daily_gift_day -= 2  # falto un solo dia: la racha no se pierde
	var g5: int = gs.claim_daily_gift()
	print("falto un dia: ", g5, " racha=", gs.gift_streak)
	gs.daily_gift_day -= 4  # falto tres dias: baja de a un escalon por dia
	var g6: int = gs.claim_daily_gift()
	print("falto tres dias: ", g6, " racha=", gs.gift_streak)
	gs.gift_streak = 9
	gs.daily_gift_day = int(Time.get_unix_time_from_system()) / 86400 - 1
	print("racha larga: ", gs.claim_daily_gift(), " (tope 30)")

	# --- guardado
	gs.save_game()
	gs.friend_points = {}
	gs.daily_gift_day = 0
	gs.load_game()
	print("recarga: puntos luna=", gs.friend_points.get("luna"), " dia regalo ok=", gs.daily_gift_day > 0)

	# --- pantallas
	for scn in ["neighbors", "visit", "home", "missions"]:
		load_nb.current = "bruno"
		var s: Control = load("res://scenes/%s.tscn" % scn).instantiate()
		root.add_child(s)
		await process_frame
		await process_frame
		print("escena ", scn, " ok")
		s.queue_free()
	quit()
