extends Node
## Aviso en el celular, pensado para NO molestar: como mucho uno por semana, y solo si el jugador no
## volvio a entrar. Cada vez que el juego se abre se cancela el aviso pendiente y, al salir, se deja
## programado uno para dentro de 7 dias (a las 18 h). Si el jugador entra antes, nunca le llega.
## El texto cuenta algo concreto (el Pompon lo extraña, la pelicula nueva del cine, el sello de la
## semana). Se puede apagar desde el menu (campana): GameState.notify_on.
##
## El envio real lo hace el plugin "Notification Scheduler" (addons/NotificationSchedulerPlugin, v6.0,
## licencia MIT): solo existe en Android. En la PC y en las pruebas todo funciona igual pero no se envia
## nada; lo planeado queda en `planned`. Android 13+ pide permiso: se pregunta UNA vez, con un cartel
## amable en la casa (ver `should_ask`), nunca de golpe.

const NOTIFY_ID := 7
const DAYS_AWAY := 7
const HOUR := 18          # hora local a la que llega
const CHANNEL := "pompon_semanal"
const PLUGIN := "NotificationSchedulerPlugin"   # el singleton de Android
const ASK_TIP := "notify_ask"                    # ya se pregunto si quiere avisos (tips_seen)

var planned := {}         # {"at": unix, "title", "text"} lo ultimo que se programo ({} si nada)
var _ns: NotificationScheduler    # el nodo del plugin (solo en Android)
var _ready_ok := false


func _ready() -> void:
	if Engine.has_singleton(PLUGIN):
		_ns = NotificationScheduler.new()
		add_child(_ns)
		_ns.initialization_completed.connect(_on_plugin_ready)
		_ns.initialize()
	cancel()   # abrio el juego: el aviso pendiente ya no hace falta


func _on_plugin_ready() -> void:
	_ready_ok = true
	_ns.create_notification_channel(NotificationChannel.new()
		.set_id(CHANNEL)
		.set_name("Tu Pompon")
		.set_description("Como mucho un aviso por semana, solo si no entraste")
		.set_importance(NotificationChannel.Importance.DEFAULT))
	cancel()


## ¿Se pueden enviar avisos en este celular? (plugin listo)
func available() -> bool:
	return _ready_ok


func has_permission() -> bool:
	return _ready_ok and _ns.has_post_notifications_permission()


func request_permission() -> void:
	if _ready_ok and not has_permission():
		_ns.request_post_notifications_permission()


## ¿Hay que preguntarle si quiere avisos? Una sola vez, desde el segundo dia que juega y si el
## celular todavia no dio permiso.
func should_ask() -> bool:
	return available() and GameState.notify_on and not has_permission() \
		and GameState.days_visited >= 2 and not GameState.tips_seen.has(ASK_TIP)


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
	if _ready_ok:
		_ns.cancel(NOTIFY_ID)


## Envia al sistema (solo en Android, con el plugin listo).
func _backend_schedule(delay_seconds: int, title: String, text: String) -> void:
	if not _ready_ok:
		return
	_ns.schedule(NotificationData.new()
		.set_id(NOTIFY_ID)
		.set_channel_id(CHANNEL)
		.set_title(title)
		.set_content(text)
		.set_delay(maxi(60, delay_seconds)))
