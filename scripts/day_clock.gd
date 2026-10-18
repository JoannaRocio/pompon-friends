class_name DayClock
extends RefCounted
## La hora del jugador (la de su celular) para todo el juego: el cielo del cuarto, la noche del Pompon
## (de 22 a 8 h duerme en su camita) y la necesidad Sueño (baja de dia y se recupera de noche).
## `debug_hour` fija una hora para pruebas y capturas. La variable de entorno POMPON_HOUR tambien la fija
## (tests/run_all.ps1 la pone en 12: las pruebas no dependen de la hora real de la computadora).

const NIGHT_START := 22.0
const NIGHT_END := 8.0

static var debug_hour := -1.0


## Hora fija para pruebas (debug_hour o POMPON_HOUR), o -1 si se usa la hora real.
static func _fixed_hour() -> float:
	if debug_hour >= 0.0:
		return debug_hour
	var env := OS.get_environment("POMPON_HOUR")
	return float(env) if env.is_valid_float() else -1.0


## Hora local de ahora (13.5 = 13:30).
static func hour_now() -> float:
	if _fixed_hour() >= 0.0:
		return _fixed_hour()
	var t := Time.get_time_dict_from_system()
	return float(t["hour"]) + float(t["minute"]) / 60.0


## Hora local de un momento (unix), para repartir el tiempo que la app estuvo cerrada.
static func hour_at(unix: int) -> float:
	if _fixed_hour() >= 0.0:
		return _fixed_hour()
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))   # minutos respecto de UTC
	var d := Time.get_datetime_dict_from_unix_time(unix + bias * 60)
	return float(d["hour"]) + float(d["minute"]) / 60.0


static func is_night(hour: float) -> bool:
	return hour >= NIGHT_START or hour < NIGHT_END


static func night_now() -> bool:
	return is_night(hour_now())


## "22:05"
static func time_text() -> String:
	var h := hour_now()
	var hh := int(h)
	var mm := int(round((h - hh) * 60.0)) % 60
	return "%02d:%02d" % [hh, mm]
