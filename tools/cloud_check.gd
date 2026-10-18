extends SceneTree
## Herramienta de desarrollo: prueba la nube contra el Supabase real (CloudConfig) con una partida
## inventada: subir, volver a subir, recuperar en un "dispositivo nuevo" y el conflicto.
## OJO: borra la partida local (reset_game). Respaldar antes user://save.json* y restaurar despues.
## Uso: godot --headless --path . --script tools/cloud_check.gd
## Deja en el servidor una partida de prueba (nombre "Prueba"); se puede borrar desde Supabase.


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	var cloud := root.get_node("Cloud")
	print("configurado: ", cloud.is_configured())
	gs.reset_game()
	gs.new_pompon()
	gs.pompon.hatched = true
	gs.pompon.nickname = "Prueba"
	gs.player_name = "Prueba"
	gs.player_title = "n"
	gs.coins = 11
	var up1: Dictionary = await cloud.upload()
	print("1) subir por primera vez: ok=", up1["ok"], " error='", up1["error"], "' codigo=", CloudCode.format_code(gs.cloud_code), " fecha=", gs.cloud_synced_at)
	if not up1["ok"]:
		quit()
		return
	var code: String = gs.cloud_code
	gs.coins = 22
	var up2: Dictionary = await cloud.upload()
	print("2) volver a subir: ok=", up2["ok"], " error='", up2["error"], "'")
	var old_sync: String = gs.cloud_synced_at
	gs.reset_game()
	var rs: Dictionary = await cloud.restore(code)
	print("3) recuperar en otro dispositivo: ok=", rs["ok"], " error='", rs["error"], "' pompon=", gs.pompon.nickname if gs.pompon else "-", " monedas=", gs.coins, " (esperado 22)")
	gs.coins = 33
	var up3: Dictionary = await cloud.upload()
	print("4) seguir jugando y subir: ok=", up3["ok"], " error='", up3["error"], "'")
	gs.cloud_synced_at = old_sync   # como un dispositivo viejo con la partida de antes
	gs.coins = 5
	var up4: Dictionary = await cloud.upload()
	print("5) dispositivo viejo intenta pisar: error='", up4["error"], "' (esperado conflict)")
	var check: Dictionary = await cloud._rpc("pompon_download", {"p_code": code})
	print("   la nube conserva monedas=", check["value"]["data"]["coins"] if check["ok"] and check["value"] != null else "?", " (esperado 33)")
	var nf: Dictionary = await cloud.restore("ZZZZ-ZZZZ-ZZZZ")
	print("6) codigo que no existe: error='", nf["error"], "' (esperado not_found)")
	print("codigo de la partida de prueba en el servidor: ", CloudCode.format_code(code))
	quit()
