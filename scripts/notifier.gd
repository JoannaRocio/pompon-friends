extends Node
## Aviso en el celular, pensado para NO molestar: como mucho uno por semana, y solo si el jugador no
## volvio a entrar. Cada vez que el juego se abre se cancela el aviso pendiente y, al salir, se deja
## programado uno para dentro de 7 dias (a las 18 h). Si el jugador entra antes, nunca le llega.
## El texto cuenta algo concreto (el Pompon lo extraña, la pelicula nueva del cine, el sello de la
## semana). Se puede apagar desde el menu (campana): GameState.notify_on.
##
## Enviar el aviso de verdad necesita un plugin de Android de notificaciones locales (un "singleton"
## llamado NotificationScheduler). Si no esta instalado, todo esto funciona igual pero no se envia
## nada: lo planeado queda en `planned` (sirve para las pruebas).

const NOTIFY_ID := 7
const DAYS_AWAY := 7
const HOUR := 18          # hora local a la que llega
const CHANNEL := "pompon_semanal"
const PLUGIN := "NotificationScheduler"

var planned := {}         # {"at": unix, "title", "text"} lo ultimo que se programo ({} si nada)


func _ready() -> void:
	cancel()   # abrio el juego: el aviso pendiente ya no hace falta


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			schedule()
		NOTIFICATION_APPLICATION_RESUMED:
			cancel()


## Cuando llegaria: dentro de 7 dias, a las 18 h (hora del celular).
static func fire_time(now: int) -> int:
	var local := now + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var day_start := local - posmod(local, 86400)
	var target_local := day_start + DAYS_AWAY * 86400 + HOUR * 3600
	return target_local - (local - now)


## Que dice el aviso (algo concreto y amable, nunca "¡vuelve ya!").
static func message(now: int, pompon_name: String, has_pompon: bool) -> Dictionary:
	var day := Missions.today(now)
	var fire_day := day + DAYS_AWAY
	var movie_changes: bool = Movies.of_day(fire_day)["id"] != Movies.of_day(day)["id"]
	if not has_pompon:
		return {"title": "Pompon Friends", "text": "Tu huevo sigue esperando su cuna."}
	match posmod(Movies.week_of(day), 3):
		0:
			return {"title": "%s te extraña" % pompon_name, "text": "Pasa a saludarlo cuando quieras. Tu sello de la semana te espera."}
		1:
			if movie_changes:
				return {"title": "Película nueva en el Cine Pompon", "text": "Esta semana dan \"%s\". ¿Vas con %s?" % [Movies.of_day(fire_day)["title"], pompon_name]}
			return {"title": "%s está creciendo" % pompon_name, "text": "Mira cómo está y qué escribió en su diario."}
	return {"title": "%s quiere jugar" % pompon_name, "text": "Hay un sello nuevo en tu calendario de la semana."}


## Deja programado el aviso de la semana (si estan prendidos).
func schedule(now := -1) -> void:
	cancel()
	if not GameState.notify_on:
		return
	if now < 0:
		now = int(Time.get_unix_time_from_system())
	var p: Pompon = GameState.pompon
	var msg := message(now, p.display_name() if p != null else "", p != null and p.hatched)
	planned = {"at": fire_time(now), "title": msg["title"], "text": msg["text"]}
	_backend_schedule(planned["at"] - now, msg["title"], msg["text"])


func cancel() -> void:
	planned = {}
	if Engine.has_singleton(PLUGIN):
		var plugin := Engine.get_singleton(PLUGIN)
		if plugin.has_method("cancel"):
			plugin.call("cancel", NOTIFY_ID)


## Envia al sistema (solo si el plugin de Android esta instalado).
func _backend_schedule(delay_seconds: int, title: String, text: String) -> void:
	if not Engine.has_singleton(PLUGIN):
		return
	var plugin := Engine.get_singleton(PLUGIN)
	if plugin.has_method("schedule"):
		plugin.call("schedule", NOTIFY_ID, CHANNEL, title, text, maxi(60, delay_seconds))
