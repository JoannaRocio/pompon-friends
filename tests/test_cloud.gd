extends SceneTree
## Partidas en la nube con codigo (con un servidor de mentira en memoria que imita server/supabase.sql).


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var cloud := root.get_node("Cloud")
	var cc: GDScript = load("res://scripts/cloud_code.gd")

	# --- codigos
	var codes := {}
	var all_ok := true
	for i in 300:
		var c: String = cc.new_code()
		all_ok = all_ok and cc.clean_code(c) == c
		codes[c] = true
	print("codigos validos: ", all_ok, " | distintos: ", codes.size(), " de 300 | ejemplo: ", cc.format_code(codes.keys()[0]))
	print("lo que escribe el jugador: '", cc.clean_code("abcd-efgh jklm"), "' | con letras de mas o de menos: '", cc.clean_code("ABCD-EFGH-JKL"), "' '", cc.clean_code("ABCD-EFGH-JKL0"), "'")

	# --- sin servidor no hace nada (las pruebas nunca usan el Supabase real)
	cloud.enabled = false
	var off: Dictionary = await cloud.upload()
	print("sin servidor: ", off["error"], " (esperado off)")
	cloud.enabled = true

	# --- primera subida: crea el codigo
	cloud.fake_server = {}
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Mochi"
	gs.coins = 77
	gs.player_name = "Ana"
	gs.player_title = "f"
	var up1: Dictionary = await cloud.upload()
	var code: String = gs.cloud_code
	print("primera subida: ok=", up1["ok"], " codigo=", cc.format_code(code), " | en el servidor: ", cloud.fake_server.has(code))
	gs.coins = 90
	var up2: Dictionary = await cloud.upload()
	print("segunda subida (mismo codigo): ok=", up2["ok"], " mismo codigo=", gs.cloud_code == code, " monedas en la nube=", cloud.fake_server[code]["data"]["coins"])
	var old_sync: String = gs.cloud_synced_at

	# --- otro dispositivo: recupera con el codigo y sigue jugando
	gs.reset_game()
	print("dispositivo nuevo: sin partida=", gs.pompon == null)
	var bad: Dictionary = await cloud.restore("ABCD")
	var missing: Dictionary = await cloud.restore("ABCD-EFGH-JKLM")
	print("codigo mal escrito: ", bad["error"], " | codigo que no existe: ", missing["error"])
	var rs: Dictionary = await cloud.restore(cc.format_code(code).to_lower())
	print("recuperar: ok=", rs["ok"], " pompon=", gs.pompon.nickname if gs.pompon else "-", " monedas=", gs.coins, " nombre=", gs.player_name, " codigo guardado=", gs.cloud_code == code)
	gs.coins = 150
	var up3: Dictionary = await cloud.upload()
	print("sigue jugando en el nuevo y sube: ok=", up3["ok"], " monedas en la nube=", cloud.fake_server[code]["data"]["coins"])

	# --- el dispositivo viejo vuelve con su partida vieja: no pisa la nueva
	gs.coins = 95
	gs.cloud_synced_at = old_sync
	var up4: Dictionary = await cloud.upload()
	print("dispositivo viejo: error=", up4["error"], " conflicto=", cloud.conflict, " la nube conserva=", cloud.fake_server[code]["data"]["coins"])
	var up5: Dictionary = await cloud.upload(true)
	print("elegir 'usar la de este dispositivo': ok=", up5["ok"], " nube=", cloud.fake_server[code]["data"]["coins"], " sin conflicto=", not cloud.conflict)

	# --- subida automatica cuando hay cambios
	var before: String = cloud.fake_server[code]["updated_at"]
	gs.coins = 200
	gs.save_game()
	cloud._auto_t = 0.05
	await create_timer(0.3).timeout
	print("subida automatica con cambios: ", cloud.fake_server[code]["updated_at"] != before, " monedas=", cloud.fake_server[code]["data"]["coins"])
	var before2: String = cloud.fake_server[code]["updated_at"]
	cloud._auto_t = 0.05
	await create_timer(0.3).timeout
	print("sin cambios no vuelve a subir: ", cloud.fake_server[code]["updated_at"] == before2)
	cloud.fake_server = null
	cloud.enabled = false   # al cerrar no intenta subir al servidor real
	quit()
