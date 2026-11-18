extends SceneTree
## Ahorro de bateria en la casa: sin tocar la pantalla un rato baja a 30 cuadros por segundo; al tocar
## vuelve a 60, y al salir de la casa siempre queda en 60 (los minijuegos necesitan ir suaves).


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var now := int(Time.get_unix_time_from_system())
	gs.new_pompon("Conejo", "Hembra")
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.pompon.born_at = now - 3 * 86400
	gs.hatch_anim_pending = false
	gs.daily_gift_day = Missions.today(now)
	gs.tips_seen = ["egg1", "job1", "shopcrib", "notify_ask", "night1"]
	gs.tutorial = {"chapter": 0, "step": 0, "off": true, "done_at": 0, "done_day": -1}
	var h: Control = load("res://scenes/home.tscn").instantiate()
	root.add_child(h)
	await create_timer(0.5).timeout
	print("en la PC no se activa solo: ", not h.calm_fps_enabled or OS.has_feature("mobile"), " | empieza en 60: ", Engine.max_fps == 60)
	h.calm_fps_enabled = true
	await create_timer(h.CALM_AFTER + 0.8).timeout
	print("sin tocar un rato baja a 30: ", Engine.max_fps == 30)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	h._input(touch)
	print("al tocar vuelve a 60: ", Engine.max_fps == 60)
	await create_timer(h.CALM_AFTER + 0.8).timeout
	print("otra vez quieto: 30=", Engine.max_fps == 30)
	h.queue_free()
	await process_frame
	await process_frame
	print("al salir de la casa queda en 60: ", Engine.max_fps == 60)
	quit()
