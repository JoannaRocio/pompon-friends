extends SceneTree
## Guardado a prueba de golpes: un .tmp a medio escribir, un corte justo entre los dos renombres,
## un save.json cortado, que un guardado roto no pise el respaldo bueno, y que se guarde al pausar,
## al cerrar y en los momentos clave (fin de turno, compra, nacimiento).

const SAVE := "user://save.json"
const TMP := "user://save.json.tmp"
const BAK := "user://save.json.bak"

var gs: Node


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _coins_in(path: String) -> int:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return int(d.get("coins", -1)) if typeof(d) == TYPE_DICTIONARY else -1


func _check(what: String, ok: bool) -> void:
	print(what, ": ", ok)
	if not ok:
		print("FALLA: ", what)


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	gs.new_pompon()
	gs.coins = 100
	gs.save_game()
	gs.coins = 200
	var saved: bool = gs.save_game()
	_check("guardado normal: devuelve true, save y respaldo, sin .tmp sobrante",
		saved and _coins_in(SAVE) == 200 and _coins_in(BAK) == 100 and not FileAccess.file_exists(TMP))

	# 1) el celular se apago mientras escribia el .tmp: queda a medias -> se usa save.json
	var good := FileAccess.get_file_as_string(SAVE)
	_write(TMP, good.substr(0, good.length() / 2))
	gs.coins = 0
	gs.load_game()
	_check("tmp a medio escribir: carga save.json (200)", gs.coins == 200 and gs.last_load_from == SAVE)
	gs.coins = 250
	gs.save_game()
	_check("  el siguiente guardado reemplaza el tmp roto", _coins_in(SAVE) == 250 and not FileAccess.file_exists(TMP))

	# 2) se corto justo despues de mover save.json al respaldo y antes de renombrar el .tmp
	gs.coins = 300
	gs.save_game()
	var newest := FileAccess.get_file_as_string(SAVE)
	DirAccess.remove_absolute(BAK)
	DirAccess.rename_absolute(SAVE, BAK)   # el respaldo queda con lo de antes (300)...
	var d: Dictionary = JSON.parse_string(newest)
	d["coins"] = 350
	d["last_saved"] = int(d["last_saved"]) + 5
	_write(TMP, JSON.stringify(d))         # ...y el .tmp, entero, con lo nuevo (350)
	gs.coins = 0
	gs.load_game()
	_check("corte entre los dos renombres (sin save.json): carga el tmp, que es el mas nuevo (350)",
		gs.coins == 350 and gs.last_load_from == TMP)
	gs.save_game()
	_check("  al guardar vuelve a quedar save.json y no queda tmp", _coins_in(SAVE) == 350 and not FileAccess.file_exists(TMP))

	# 3) save.json cortado (o con basura): se usa el respaldo, y guardar no pisa el respaldo bueno
	gs.coins = 400
	gs.save_game()
	_write(SAVE, FileAccess.get_file_as_string(SAVE).substr(0, 40))
	gs.coins = 0
	gs.load_game()
	_check("save.json cortado: carga el respaldo (350)", gs.coins == 350 and gs.last_load_from == BAK)
	_write(SAVE, "{ esto no es json")
	gs.coins = 500
	gs.save_game()
	_check("  guardar con save.json roto no lo copia al respaldo (sigue 350) y guarda bien (500)",
		_coins_in(BAK) == 350 and _coins_in(SAVE) == 500)

	# 4) los tres rotos: no se cae y no cambia nada
	_write(SAVE, "basura")
	_write(TMP, "{\"coins\": 9")
	_write(BAK, "[1,2]")
	gs.coins = 77
	gs.load_game()
	_check("los tres rotos: sin caida, la partida en memoria sigue (77)", gs.coins == 77 and gs.last_load_from == "")
	DirAccess.remove_absolute(TMP)

	# 5) se guarda al pausar (Android), al salir de foco (web y PC) y al cerrar
	for n in [[Node.NOTIFICATION_APPLICATION_PAUSED, "pausar"], [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, "salir de foco"], [Node.NOTIFICATION_WM_CLOSE_REQUEST, "cerrar"]]:
		gs.coins += 1
		var before: int = gs.save_count
		gs._notification(n[0])
		_check("guarda al " + n[1], gs.save_count == before + 1 and _coins_in(SAVE) == gs.coins)

	# 6) momentos clave: comprar, nacer y terminar un turno
	gs.new_pompon()
	gs.coins = 1000
	gs.owned = []
	var before_buy: int = gs.save_count
	gs.buy(gs.CRIB_ID)   # comprar la cuna tambien hace nacer al huevo
	_check("guarda al comprar (y nacer)", gs.save_count > before_buy and _coins_in(SAVE) == gs.coins and gs.pompon.hatched)
	gs.new_pompon()
	var before_hatch: int = gs.save_count
	gs.hatch_now()
	_check("guarda al nacer", gs.save_count == before_hatch + 1)
	var before_job: int = gs.save_count
	gs.finish_job("addsub", 5, 5, true)
	_check("guarda al terminar el turno", gs.save_count == before_job + 1 and _coins_in(SAVE) == gs.coins)
	print("FIN test_save_crash")
	quit()
