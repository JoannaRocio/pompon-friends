extends SceneTree
## La noche (22 a 8 h): Sueño, el Pompon en su camita, el cartel de la primera noche y la mañana.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var P: GDScript = load("res://scripts/pompon.gd")
	var thoughts: GDScript = load("res://scripts/pompon_thoughts.gd")

	print("noche a las 23, 2 y 7:59: ", DayClock.is_night(23.0), DayClock.is_night(2.0), DayClock.is_night(7.99),
		" | dia a las 8 y 21:59: ", not DayClock.is_night(8.0), not DayClock.is_night(21.99))

	# --- Sueño: baja de dia, sube de noche (mas rapido con su mueble especial)
	gs.new_pompon()
	var p: Pompon = gs.pompon
	p.hatched = true
	p.stats["sueno"] = 50.0
	DayClock.debug_hour = 13.0
	p.advance(3600.0, false)
	var day_v: float = p.stats["sueno"]
	DayClock.debug_hour = 23.0
	p.advance(3600.0, false)
	var night_v: float = p.stats["sueno"]
	p.advance(3600.0, true)
	print("Sueño: de dia 50 -> ", snappedf(day_v, 0.1), " (-5) | de noche -> ", snappedf(night_v, 0.1), " (+11) | con su mueble -> ", snappedf(p.stats["sueno"], 0.1), " (+15)")
	print("ya no existe Felicidad: ", not P.STAT_NAMES.has("felicidad"), " | Sueño es una necesidad: ", P.STAT_NAMES.has("sueno"))
	var old = P.from_dict({"species": "Felino", "stats": {"alimentacion": 70.0, "felicidad": 40.0}})
	print("partida vieja: sueño=", old.stats["sueno"], " (80) felicidad borrada=", not old.stats.has("felicidad"))
	# tiempo con la app cerrada: un dia largo lo cansa, una noche entera lo deja descansado
	p.stats["sueno"] = 100.0
	DayClock.debug_hour = 12.0
	p.advance(14.0 * 3600.0, false)
	var tired: float = p.stats["sueno"]
	DayClock.debug_hour = 23.0
	p.advance(10.0 * 3600.0, false)
	print("14 h de dia: sueño=", snappedf(tired, 0.1), " (30) | despues de 10 h de noche: ", snappedf(p.stats["sueno"], 0.1), " (100)")

	# --- la casa de noche
	DayClock.debug_hour = 23.0
	gs.new_pompon()
	p = gs.pompon
	p.hatched = true
	p.nickname = "Mochi"
	p.born_at = int(Time.get_unix_time_from_system()) - 3 * 86400
	gs.player_name = "Ana"
	gs.daily_gift_day = Missions.today(int(Time.get_unix_time_from_system()))
	gs.tips_seen = ["egg1", "job1", "shopcrib", "care", "pet", "decor", "coins", "friends", "growth"]
	gs.owned = ["furn_crib", "hat_bow", "shirt_dress"]
	gs.equipped = {"hat": "hat_bow", "shirt": "shirt_dress"}
	gs.placed = []
	gs.place_item("furn_crib")
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.8).timeout
	print("de noche: modo noche=", h._night, " | en su camita durmiendo=", h._night_state == "sleep" and h.pet.sleeping, " | mantita=", h.pet.sleep_props,
		" | pijama=", h.pet.equipped.get("shirt", ""), " sin gorro=", not h.pet.equipped.has("hat"))
	print("cartel de la primera noche: ", h._night_notice != null)
	h._night_notice.close()
	h._night_notice = null
	await process_frame
	print("  visto una vez: ", gs.tips_seen.has("night1"))
	h._on_pet_tapped()
	print("tocarlo de noche: se despierta un ratito=", not h.pet.sleeping, " dice='", h._speech.text, "'")
	print("actividad: '", h._night_activity_text(), "'")
	var dream: Dictionary = thoughts.spontaneous(p, {"now": int(Time.get_unix_time_from_system()), "hour": 23.0, "sleeping": true,
		"room": 0, "items": [], "on_pairs": [], "equipped": {}, "events": {}, "jobs_done": 0, "level": 4}, [], RandomNumberGenerator.new())
	print("mientras duerme, sueña: '", dream.get("text", ""), "'")
	print("reloj: ", h._clock_label.text)

	# --- llega la mañana
	DayClock.debug_hour = 8.5
	await create_timer(0.3).timeout
	print("a las 8:30: modo noche=", h._night, " | durmiendo=", h.pet.sleeping, " | ropa de siempre=", h.pet.equipped.get("shirt", ""), " | dice='", h._speech.text, "'")
	DayClock.debug_hour = -1.0
	h.queue_free()
	await process_frame
	quit()
