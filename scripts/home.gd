extends Control
## Casa: el cuarto, el Pompon (o su huevo), sus estadisticas y las acciones de cuidado.

const STAT_LABELS := {
	"alimentacion": "Comida", "hidratacion": "Agua", "aseo": "Aseo",
	"diversion": "Diversión", "comodidad": "Comodidad", "sueno": "Sueño",
	"amor": "Confianza", "amistad": "Social", "inteligencia": "Inteligencia",
}

# Acciones basicas: gratis y sin esperas.
const ACTIONS := {
	"Beber": {"stats": {"hidratacion": 40.0}, "sfx": "drink", "anim": "drink"},
	"Bañar": {"stats": {"aseo": 40.0}, "sfx": "bath", "anim": "bath"},
	"Caricia": {"stats": {"amor": 5.0}, "sfx": "pet", "anim": "love"},
}
const WALK_SPEED := 70.0  # px/s en el cuarto de 720 de ancho
const PET_SIZE := 400.0
const ACT_PAUSE := 3.0   # el Pompon se queda quieto mientras come, bebe o se banya

# Comida: la cara da mas felicidad (+10), la media +5 (segun el GDD).
const FOODS := [
	{"name": "Comida básica", "price": 0, "alimentacion": 30.0, "felicidad": 0.0},
	{"name": "Comida rica", "price": 5, "alimentacion": 40.0, "felicidad": 5.0},
	{"name": "Comida gourmet", "price": 12, "alimentacion": 50.0, "felicidad": 10.0},
]
const SPEECH_SECONDS := 6.0

@onready var room: RoomView = $Room
@onready var title: Label = $InfoPanel/Info/Title
@onready var details: Label = $InfoPanel/Info/Details
@onready var bars: VBoxContainer = $InfoPanel/Info/Bars
@onready var pet: PomponView = $Pet
@onready var hatch_button: Button = $HatchButton

var _bar_nodes := {}
var _mini_nodes := {}
var _mini_row: HBoxContainer
var _toggle_button: Button
var _toggle_icon := "chevron_down"
var _sex_badge: Control
var _sex_kind := "female"
var _arrow: GuideArrow
var _avatar_view: PomponView
var _avatar_panel: Panel
var _avatar_sex := ""
var _profile_panel: PanelContainer
var _crib_bar: StatBar
var _growth_bar: StatBar
var _growth_hint: Label
var _growth_timer := 0.0
var _dock: HomeDock
var _coin_pill: PanelContainer
var _expanded := false
var _top_buttons: Array[Button] = []
var _shop_button: Button
var _job_button: Button
var _friends_dot: Control
var _pulses := {}   # boton -> animacion de latido
var _gift_panel: PanelContainer
var _edit := false
var _edit_panel: PanelContainer
var _edit_room_label: Label
var _tray: HBoxContainer
var _store_button: Button
var _follow_pause := 0.0           # la camara no sigue al Pompon hasta que pase este tiempo
var _nav_left: Button
var _nav_right: Button
var _journal_panel: PanelContainer
var _rooms_sig := -1
var _activity_chip: PanelContainer
var _activity_label: Label
var _activity_timer := 0.0
var _activity_walking := false
var _activity_last := ""
var _practice_text := ""          # lo que esta haciendo con un objeto ("Mochi toca el piano")
var _practice_left := 0.0
# jugar con los objetos del cuarto (ver PomponPlay)
var _play_id := ""                 # objeto con el que juega (o hacia el que va)
var _play_state := ""              # "" | "going" (caminando) | "using" (jugando)
var _play_t := 0.0
var _play_spot := {}               # {"pos", "walk", "pose", "face", "fx_at", "info"}
var _play_cd := 8.0                # pausa entre una actividad y otra
var _play_last := ""
var _play_fx_t := 0.0
var _play_new := false             # va a ver algo recien puesto: al llegar dice un comentario
var _discover: Array = []          # objetos recien colocados que todavia no fue a ver
var _edit_before: Array = []       # lo que estaba colocado al empezar a decorar
var _door: Button                  # puerta de la sala: sale al pueblo
var _missions_dot: Control         # punto rojo en Misiones (sello o medalla para cobrar)
var _tut: TutorialOverlay          # paso del tutorial que se esta mostrando
var _tut_check := 1.5
var _tut_tips_done := false
var _dot_check := 0.0
var _tip_id := ""                  # aviso que se esta mostrando
const DOOR_W := 130.0
const DOOR_H := 250.0
var _thought_timer := 90.0
var _stat_check := 0.0
var _offline_checked := false
var _pill_left := 0.0
var _pet_pos := Vector2.ZERO       # donde pisa el Pompon en la habitacion (x en px del mundo, y pies)
var _night := false                # es de noche y el Pompon esta en modo dormir
var _night_state := ""             # "to_bed", "sleep", "play", "trip", "snack", "back"
var _night_t := 0.0
var _night_pos := Vector2.ZERO     # su camita (pies, en el mundo)
var _night_props := "bed"
var _night_trip := Vector2.ZERO
var _wake_t := 0.0                 # despierto un ratito porque lo tocaron
var _night_seen := false           # ya paso por la noche en esta sesion (si no, aparece directo en la cama)
var _night_notice: BigNotice
var _album_panel: AlbumPanel
var _album_check := 2.0
var _clock_label: Label
var _clock_icon: Control
var _pet_ready := false
var _moving := false
var _wander_target := Vector2.ZERO
var _wander_wait := 2.0
var _coins_label: Label
var _bubble: PanelContainer
var _speech: Label
var _speech_timer := 0.0
var _food_panel: PanelContainer
var _note_panel: PanelContainer
var _mystery_egg: Pompon


func _ready() -> void:
	Town.from_town = false   # desde la casa, la tienda y las visitas vuelven a la casa
	_discover = GameState.discover_next.duplicate()   # algo recien colgado (por ejemplo un dibujo)
	GameState.discover_next = []
	_mystery_egg = PomponView.make_sample("Felino", Color("f5d0a9"), Color("fff6e8"))
	_mystery_egg.born_at = int(Time.get_unix_time_from_system())
	_mystery_egg.hatched = false  # huevo
	GameState.pompon_left.connect(_on_pompon_left)
	hatch_button.text = T.t("common.adopt")
	Hud.style_primary(hatch_button, 38)
	hatch_button.pressed.connect(_on_hatch_pressed)
	pet.petted.connect(_on_pet_tapped)
	pet.set_anchors_preset(Control.PRESET_TOP_LEFT)  # se mueve a mano al caminar
	pet.size = Vector2(PET_SIZE, PET_SIZE)
	pet.pivot_offset = Vector2(PET_SIZE * 0.5, PET_SIZE - 6.0)
	room.mouse_filter = Control.MOUSE_FILTER_STOP   # deslizar el cuarto: lo demas (Pompon, botones) va encima
	room.selection_changed.connect(func(id: String): _store_button.disabled = id == "")
	room.panned.connect(func(): _follow_pause = 4.0)
	var fx := AmbientFx.new()
	add_child(fx)
	move_child(fx, room.get_index() + 1)
	_build_door()
	_build_bubble()
	_build_bars()
	_build_actions()
	_build_mood()
	_build_activity()
	_arrow = GuideArrow.new()
	add_child(_arrow)
	_build_edit_panel()
	_build_scroll_arrows()
	_bubble.visible = false
	_refresh()


func _process(delta: float) -> void:
	_speech_timer -= delta
	if _speech_timer <= 0.0 and _bubble.visible:
		_bubble.visible = false
	_wander(delta)
	_update_arrow()
	_place_arrows()
	_place_door()
	_update_tutorial(delta)
	_dot_check -= delta
	if _missions_dot != null and _dot_check <= 0.0:   # (cada tanto: mirar todos los logros cuesta)
		_dot_check = 2.0
		_missions_dot.visible = GameState.progress_to_claim()
	_place_tip()
	_update_mood(delta)
	_update_activity(delta)
	_update_thoughts(delta)
	_update_tastes(delta)
	_update_practice(delta)
	_update_growth(delta)
	_update_night(delta)
	_update_album(delta)
	_update_prehatch(delta)
	_check_news()
	_refresh()


# ------------------------------------------------- el Pompon camina por el cuarto

func _floor_bounds() -> Rect2:
	# x: centro del Pompon en toda la habitacion (varias pantallas); y: donde pisa (los pies)
	var ww := room.world_w()
	return Rect2(ww * 0.08, size.y * 0.655, ww * 0.84, size.y * 0.075)


func _world_center() -> Vector2:
	return Vector2(room.world_w() * 0.5, _floor_bounds().end.y)


func _wander(delta: float) -> void:
	if size.x <= 0.0:
		return
	var bounds := _floor_bounds()
	if not _pet_ready:
		_pet_pos = _world_center()
		room.scroll_to(room.max_scroll() * 0.5, false)
		_pet_ready = true
	var p := GameState.pompon
	var grown: bool = p != null and p.stage_index(int(Time.get_unix_time_from_system())) > 0
	var busy := _edit or _any_modal() or _prehatch
	if _play_state != "" and (busy or not grown or _night):
		_end_play(false)
	if _night and grown and not _edit and not _prehatch:   # de noche: en su camita (ver _night_wander)
		_night_wander(delta)
		_place_pet(bounds)
		return
	_follow_pause = maxf(_follow_pause - delta, 0.0)
	if not grown or busy:
		pet.walking = false
		_moving = false
		if not grown or _prehatch:
			_pet_pos = _world_center()  # el huevo se queda en el centro
	elif _play_state == "using":
		_play_step(delta)
	elif _moving:
		var to := _wander_target - _pet_pos
		var step := WALK_SPEED * delta
		if to.length() <= step:
			_pet_pos = _wander_target
			_moving = false
			pet.walking = false
			_wander_wait = randf_range(2.0, 5.5)
			if _play_state == "going":
				_start_play()
		else:
			_pet_pos += to.normalized() * step
			var step_news := PomponSkills.add_walk_xp(p, step / PomponSkills.WALK_PIXELS_PER_XP)   # explorar entrena el fisico
			if not step_news.is_empty():
				GameState.pending_thoughts.append(step_news)
			pet.facing = 1.0 if to.x >= 0.0 else -1.0
			pet.walking = true
	else:
		_wander_wait -= delta
		if _wander_wait <= 0.0 and not _try_play():
			# a veces camina cerca de donde esta mirando el jugador y a veces se va lejos
			var near_view := randf() < 0.6
			var lo := bounds.position.x
			var hi := bounds.end.x
			if near_view:
				lo = clampf(room.scroll + size.x * 0.15, bounds.position.x, bounds.end.x)
				hi = clampf(room.scroll + size.x * 0.85, lo, bounds.end.x)
			_wander_target = Vector2(randf_range(lo, hi), randf_range(bounds.position.y, bounds.end.y))
			_moving = true
	# la camara acompaña al Pompon cuando se aleja (salvo un rato despues de mover la camara a mano)
	if grown and not busy and _follow_pause <= 0.0:
		var sx := _pet_pos.x - room.scroll
		if sx < size.x * 0.2 or sx > size.x * 0.8:
			room.scroll = move_toward(room.scroll, _pet_pos.x - size.x * 0.5, 150.0 * delta)
	_place_pet(bounds)


# ------------------------------------------------- tutorial guiado

## El boton que se resalta en un paso del tutorial (null si no hay o no se ve).
func _tutorial_target(key: String) -> Control:
	if key == "":
		return null
	var parts := key.split(":")
	match parts[0]:
		"dock":
			return _dock.buttons.get(parts[1], null)
		"tab":
			return _dock.tab_button(0 if parts[1] == "Pompon" else 1)
		"top":
			for tb in _top_buttons:
				if tb is ActionButton and (tb as ActionButton).caption == parts[1]:
					return tb
		"info":
			return $InfoPanel
		"door":
			return _door
	return null


## Muestra el paso del tutorial que toca (de a uno, sin tapar otras ventanas).
func _update_tutorial(delta: float) -> void:
	if _tut != null:
		return
	_tut_check -= delta
	if _tut_check > 0.0:
		return
	_tut_check = 0.5
	var p := GameState.pompon
	if GameState.tutorial_active() and not _tut_tips_done:   # el tutorial explica lo mismo que esos avisos sueltos
		_tut_tips_done = true
		for tip in TutorialSteps.COVERS_TIPS:
			if not GameState.tips_seen.has(tip):
				GameState.tips_seen.append(tip)
		if _tip_panel != null and _tip_id in TutorialSteps.COVERS_TIPS:
			_dismiss_tip()
	if not _is_born(p) or _needs_name() or _any_modal() or _edit or _night or _prehatch or _tip_panel != null \
			or GameState.farewell != "":
		return
	if not GameState.pending_art.is_empty():   # le mandaron un dibujo: se ve primero y elige guardarlo o no
		var art_notice := FriendSafety.show_received_art(self, func(): _night_notice = null)
		_night_notice = art_notice
		return
	if Notifier.should_ask():   # una sola vez: ¿quiere que le avisemos?
		_ask_notifications()
		return
	if not GameState.tutorial_ready():
		return
	var step := GameState.tutorial_current()
	if step.has("screen"):   # este paso es en otra pantalla: se vuelve a pedir que vaya
		GameState.tutorial["step"] = 0
		step = GameState.tutorial_current()
	var target := _tutorial_target(step["target"])
	if step["target"] != "" and (target == null or not target.is_visible_in_tree()):
		if step["target"] == "door" and GameState.current_room != 0:
			_on_room_pressed(0)   # la puerta esta en la sala
			return
		GameState.tutorial_step_done()   # (no se ve: se saltea este paso)
		return
	if step["target"] == "door":
		room.scroll_to(0.0)
		_follow_pause = 6.0
	var now := int(Time.get_unix_time_from_system())
	var days := PomponGrowth.days_left(p, now)
	var text := TutorialSteps.fill(step["text"], p.display_name(), days)
	var extra: Control = null
	if step.get("card", "") == "growth":
		extra = TutorialOverlay.growth_card(p.stage_index(now))
		if p.stage_index(now) > 1:
			text = T.t("tut.grown", {"name": p.display_name()})
	_tut = TutorialOverlay.new().setup(text, target, step["mode"], extra)
	add_child(_tut)
	_tut.done.connect(func():
		GameState.tutorial_step_done()
		_close_tutorial())
	_tut.skipped.connect(func():
		GameState.tutorial_skip()
		_close_tutorial())


## Pregunta amable (una vez) si quiere el aviso semanal; recien con un "si" se pide el permiso de Android.
func _ask_notifications() -> void:
	GameState.tips_seen.append(Notifier.ASK_TIP)
	GameState.save_game()
	var notice := BigNotice.new(640.0)
	_night_notice = notice   # (cuenta como ventana abierta mientras esta)
	add_child(notice)
	notice.add(BigNotice.icon_strip([["heart", Color("ff7aa8")], ["moon", Color("7b8ce0")], ["smile", Color("ffcf3f")]]))
	notice.title(T.t("home.notify_title"))
	notice.text_line(T.t("home.notify_text", {"name": GameState.pompon.display_name()}), 28)
	notice.button(T.t("home.notify_yes"), func():
		Notifier.request_permission()
		notice.close()
		_night_notice = null, true, Color("5fc77f"))
	notice.button(T.t("home.notify_no"), func():
		GameState.notify_on = false
		GameState.save_game()
		notice.close()
		_night_notice = null, false)


func _close_tutorial() -> void:
	if _tut != null and is_instance_valid(_tut):
		_tut.queue_free()
	_tut = null
	_tut_check = 0.6


func _red_dot() -> Control:
	var dot := Control.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.position = Vector2(62, 2)
	dot.size = Vector2(22, 22)
	dot.draw.connect(func():
		dot.draw_circle(Vector2(11, 11), 11.0, Color.WHITE)
		dot.draw_circle(Vector2(11, 11), 8.0, Color("e0295f")))
	dot.visible = false
	return dot


## Puerta de la sala (a la izquierda de todo): sale al pueblo. Se dibuja sobre la pared, con un
## cartelito, y se desliza con la habitacion.
func _build_door() -> void:
	_door = Button.new()
	_door.flat = true
	_door.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_door.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_door.size = Vector2(DOOR_W, DOOR_H)
	_door.draw.connect(func():
		var out := Color("5b3a4a")
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("c9925f")
		sb.border_color = out
		sb.set_border_width_all(5)
		sb.corner_radius_top_left = 60
		sb.corner_radius_top_right = 60
		sb.anti_aliasing = true
		_door.draw_style_box(sb, Rect2(8, 40, DOOR_W - 16, DOOR_H - 40))
		var inner := sb.duplicate() as StyleBoxFlat
		inner.bg_color = Color("b07a52")
		inner.set_border_width_all(3)
		inner.corner_radius_top_left = 40
		inner.corner_radius_top_right = 40
		_door.draw_style_box(inner, Rect2(26, 64, DOOR_W - 52, 70))
		_door.draw_style_box(inner, Rect2(26, 146, DOOR_W - 52, 80))
		_door.draw_circle(Vector2(DOOR_W - 30, 150), 7.0, Color("ffd84d"))
		_door.draw_arc(Vector2(DOOR_W - 30, 150), 7.0, 0.0, TAU, 14, out, 2.0, true)
		# cartelito con una casita y una flecha: "al pueblo"
		var sign := StyleBoxFlat.new()
		sign.bg_color = Color("fffaf0")
		sign.border_color = out
		sign.set_border_width_all(4)
		sign.set_corner_radius_all(12)
		sign.anti_aliasing = true
		_door.draw_style_box(sign, Rect2(10, 0, DOOR_W - 20, 44))
		Hud.draw_icon(_door, "house", Vector2(44, 22), 30.0, Color("5fc77f"), Color(0, 0, 0, 0))
		_door.draw_line(Vector2(66, 22), Vector2(96, 22), out, 4.0, true)
		_door.draw_colored_polygon(PackedVector2Array([Vector2(104, 22), Vector2(92, 13), Vector2(92, 31)]), out))
	_door.pressed.connect(_go_town)
	add_child(_door)
	move_child(_door, room.get_index() + 1)


func _place_door() -> void:
	if _door == null:
		return
	_door.visible = GameState.current_room == 0 and not _edit and GameState.pompon != null and _hatch_layer == null
	_door.position = Vector2(18.0 - room.scroll, size.y * 0.61 - DOOR_H)


func _go_town() -> void:
	if _any_modal() or _edit:
		return
	Audio.play("click")
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/town.tscn")


## Lleva la camara hasta el Pompon si esta fuera de la pantalla (por ejemplo al darle de comer).
func _focus_pet() -> void:
	var sx := _pet_pos.x - room.scroll
	if sx < size.x * 0.2 or sx > size.x * 0.8:
		room.center_on(_pet_pos.x)
		_follow_pause = 1.0


func _place_pet(bounds: Rect2) -> void:
	var depth := clampf(inverse_lerp(bounds.position.y, bounds.end.y, _pet_pos.y), 0.0, 1.0)
	pet.scale = Vector2.ONE * lerpf(0.9, 1.06, depth)  # mas cerca = un poco mas grande
	var sx := _pet_pos.x - room.scroll   # posicion en la pantalla (la habitacion se desliza)
	pet.position = Vector2(sx - PET_SIZE * 0.5, _pet_pos.y - PET_SIZE + 6.0)
	_bubble.size = _bubble.get_combined_minimum_size()   # el globo se achica solo al cambiar el texto
	var mid_w := _bubble.size.x
	var top_limit := 8.0
	if $InfoPanel.visible:  # el globo siempre queda debajo de la tarjeta de estado (aunque este desplegada)
		top_limit = $InfoPanel.position.y + $InfoPanel.size.y + 10.0
		if _mood_pill.visible:
			top_limit += _mood_pill.size.y + 8.0
		if _activity_chip.visible:
			top_limit += _activity_chip.size.y + 8.0
	_bubble.position = Vector2(
		clampf(sx - mid_w * 0.5, 10.0, maxf(10.0, size.x - mid_w - 10.0)),
		maxf(_pet_pos.y - 412.0 * pet.scale.y - _bubble.size.y, top_limit))


# ------------------------------------------------- jugar con los objetos del cuarto

## Lo colocado de esta habitacion con ese id ({} si no esta).
func _placed_entry(id: String) -> Dictionary:
	for pl in GameState.placed:
		if pl["id"] == id and int(pl.get("room", 0)) == GameState.current_room:
			return pl
	return {}


## Que hace con el objeto: lo de PomponPlay, o si no tiene nada propio (estantes...), lo mira un ratito.
func _play_info(id: String) -> Dictionary:
	var info := PomponPlay.play_of(id)
	if info.is_empty():
		info = {"pose": "look", "secs": [4.0, 6.0], "fx": "sparkle", "text": "mira " + PomponThoughts._poss(id).replace("mi ", "su ").replace("mis ", "sus "), "stats": {}}
	return info


## Donde se pone para jugar con `id` (en px del mundo): {} si ya no esta en esta habitacion.
func _play_spot_for(id: String) -> Dictionary:
	var pl := _placed_entry(id)
	if pl.is_empty():
		return {}
	var info := _play_info(id)
	var rect: Rect2 = room._item_rect(pl)
	var c := rect.get_center()
	var bounds := _floor_bounds()
	var floor_y := clampf(rect.end.y, bounds.position.y, bounds.end.y)
	var pose: String = info["pose"]
	if pl.has("on") or Catalog.get_item(id).get("category", "") == "deco":
		pose = "look"   # lo de la pared y lo apoyado en estantes o mesas se mira desde abajo
	var spot := {"pose": pose, "info": info, "fx_at": Vector2(c.x, rect.position.y + 10.0)}
	match pose:
		"sit", "swing", "run":
			spot["pos"] = Vector2(c.x, rect.end.y - rect.size.y * float(info.get("seat", 0.35)))
			spot["walk"] = Vector2(c.x, floor_y)
			spot["face"] = 1.0
		"lie":
			spot["pos"] = Vector2(c.x, c.y + rect.size.y * 0.42)
			spot["walk"] = Vector2(c.x, floor_y)
			spot["face"] = 1.0
		"look":
			var x := clampf(c.x + randf_range(-25.0, 25.0), bounds.position.x, bounds.end.x)
			spot["pos"] = Vector2(x, bounds.position.y + bounds.size.y * 0.25)
			spot["walk"] = spot["pos"]
			spot["face"] = -1.0 if randf() < 0.5 else 1.0
		_:  # "side": parado al lado, mirandolo
			var gap := 70.0 if info.get("near", false) else 105.0
			var left := rect.position.x - gap
			var right := rect.end.x + gap
			var x2 := left if absf(_pet_pos.x - left) < absf(_pet_pos.x - right) else right
			if x2 < bounds.position.x or x2 > bounds.end.x:
				x2 = right if x2 == left else left
			x2 = clampf(x2, bounds.position.x, bounds.end.x)
			spot["pos"] = Vector2(x2, floor_y)
			spot["walk"] = spot["pos"]
			spot["face"] = 1.0 if c.x >= x2 else -1.0
	return spot


## Al terminar de pasear: a veces va a jugar con algo del cuarto (y siempre a ver lo recien puesto).
func _try_play() -> bool:
	var id := ""
	_play_new = false
	while id == "" and not _discover.is_empty():
		id = _discover.pop_front()
		_play_new = not _placed_entry(id).is_empty()
		if not _play_new:
			id = ""
	if id == "" and _play_cd <= 0.0 and randf() < 0.6:
		id = PomponPlay.pick(_thought_ctx()["items"], _play_last, _mood_rng)
	if id == "":
		return false
	var spot := _play_spot_for(id)
	if spot.is_empty():
		return false
	_play_id = id
	_play_spot = spot
	_play_state = "going"
	_wander_target = spot["walk"]
	_moving = true
	if _play_new:
		room.center_on(spot["walk"].x)
		_follow_pause = 1.5
	return true


## Llego: se sienta, se acuesta o se pone a jugar (y si es nuevo, dice algo).
func _start_play() -> void:
	var p := GameState.pompon
	var info: Dictionary = _play_spot["info"]
	_play_state = "using"
	var secs: Array = info.get("secs", [8.0, 12.0])
	_play_t = _mood_rng.randf_range(secs[0], secs[1])
	_play_fx_t = 0.6
	_moving = false
	pet.walking = false
	if _play_spot["pose"] in ["sit", "swing", "run", "lie"]:
		_pet_pos = _play_spot["pos"]
		pet.celebrate(0)   # saltito para subirse
	pet.facing = _play_spot["face"]
	pet.face_mood = "happy" if _play_spot["pose"] in ["look", "lie", "sit"] else ""
	if _play_spot["pose"] == "lie":
		pet.sleep_props = "bed"
	_practice_text = "%s %s" % [p.display_name(), info["text"]]
	_practice_left = _play_t
	_activity_timer = 0.0
	if _play_new:
		pet.celebrate(4)
		Audio.play("ding")
		_log_thought({"kind": PomponThoughts.KIND_SAY, "text": PomponPlay.comment(_play_id, _mood_rng), "stat": "comodidad"})
	elif PomponSkills.item_skill(_play_id) != "":   # primera vez con un objeto de practica: al diario
		_log_first(PomponFirsts.experience(p, "item", _play_id, PomponThoughts._poss(_play_id), int(Time.get_unix_time_from_system()), _mood_rng))


## Mientras juega: la pose se mueve un poquito y salen notas, brillitos o burbujas.
func _play_step(delta: float) -> void:
	var info: Dictionary = _play_spot["info"]
	var t := Time.get_ticks_msec() / 1000.0
	_play_t -= delta
	_practice_left = maxf(_play_t, 0.0)
	match _play_spot["pose"]:
		"swing":
			pet.lean = sin(t * 2.6) * 0.22
		"run":
			pet.walking = true
		"look":
			pet.lean = -0.07 * pet.facing   # mirando hacia arriba
		"side":
			pet.lean = sin(t * 7.0) * float(info.get("bob", 0.03)) * pet.facing
	_play_fx_t -= delta
	if _play_fx_t <= 0.0:
		_play_fx_t = randf_range(0.9, 1.4)
		var fx: String = info.get("fx", "")
		var at: Vector2 = _play_spot["fx_at"] if fx in ["note", "bubble", "sparkle"] and _play_spot["pose"] != "sit" else _pet_pos + Vector2(0, -300.0 * pet.scale.y)
		if fx == "zzz":
			at = _pet_pos + Vector2(60.0, -260.0 * pet.scale.y)
		PlayFx.spawn(self, fx, Vector2(at.x - room.scroll, at.y))
	if _play_t <= 0.0:
		_end_play(true)


## Termina de jugar (`done`: llego al final y suma lo suyo) y vuelve a pasear.
func _end_play(done: bool) -> void:
	var p := GameState.pompon
	if done and _play_state == "using" and p != null:
		PomponPlay.apply_stats(p, _play_id)
		var skill := PomponSkills.item_skill(_play_id)
		if skill != "":   # los objetos de practica entrenan sus habilidades
			var news := PomponSkills.add_xp(p, skill, PomponSkills.PRACTICE_XP)
			if not news.is_empty():
				GameState.pending_thoughts.append(news)
	if _play_state == "using" and _play_spot.get("pose", "") in ["sit", "swing", "run", "lie"]:
		_pet_pos = _play_spot["walk"]   # se baja
	pet.lean = 0.0
	pet.face_mood = ""
	pet.walking = false
	if not _night:
		pet.sleep_props = ""
	_play_last = _play_id
	_play_id = ""
	_play_state = ""
	_play_cd = PomponPlay.COOLDOWN if done else 6.0
	_practice_left = 0.0
	_moving = false
	_wander_wait = randf_range(1.5, 3.0)


## "Tofu se siente un poco aburrido": una frase bajo la tarjeta de estado que cambia cada tanto y
## cuenta como esta el Pompon (lo urgente primero), para que el jugador este atento a lo que necesita.
func _build_mood() -> void:
	_mood_rng.randomize()
	_mood_pill = PanelContainer.new()
	_mood_pill.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_mood_pill.offset_left = 16
	_mood_pill.offset_right = -16
	_mood_pill.mouse_filter = Control.MOUSE_FILTER_STOP   # tocarla abre el diario
	_mood_pill.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_show_journal())
	_mood_pill.visible = false
	add_child(_mood_pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_mood_pill.add_child(row)
	_mood_icon = Control.new()
	_mood_icon.custom_minimum_size = Vector2(50, 50)
	_mood_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mood_icon.draw.connect(func():
		var c := _mood_icon.size * 0.5
		_mood_icon.draw_circle(c, 25.0, Color.WHITE)
		_mood_icon.draw_circle(c, 21.0, _mood_color)
		Hud.draw_icon(_mood_icon, _mood_kind, c, 32.0, Color.WHITE, _mood_color.darkened(0.3)))
	row.add_child(_mood_icon)
	_mood_label = Label.new()
	_mood_label.add_theme_font_size_override("font_size", 27)
	_mood_label.add_theme_color_override("font_color", Hud.INK)
	_mood_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mood_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mood_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mood_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mood_label.custom_minimum_size = Vector2(520, 0)   # sin esto el texto se parte letra por letra
	row.add_child(_mood_label)
	_set_mood_style(KIND_COLORS["sentimiento"])


func _set_mood_style(border: Color) -> void:
	_mood_pill.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 32, border, 4, 8))


func _update_mood(delta: float) -> void:
	var p := GameState.pompon
	_pill_left = maxf(_pill_left - delta, 0.0)
	var show := _is_born(p) and _pill_left > 0.0 and not _edit and not _any_modal()
	_mood_pill.visible = show
	if not show:
		return
	_mood_pill.position.y = $InfoPanel.position.y + $InfoPanel.size.y + 10.0
	if _pill_left < 0.6:
		_mood_pill.modulate.a = _pill_left / 0.6


## Ya nacio para la interfaz: mientras falta ver el nacimiento (el huevo golpeando y la animacion)
## la casa se sigue viendo como con el huevo, para no arruinar la sorpresa.
func _is_born(p: Pompon) -> bool:
	return p != null and p.hatched and not GameState.hatch_anim_pending


## Antes de nacer: el huevo se mueve solo y golpea la cascara; tocarlo lo ayuda a salir
## (cada toque, una rajadura). Al tercer toque, o si pasa un rato, empieza el nacimiento.
func _start_prehatch() -> void:
	_prehatch = true
	_prehatch_t = 0.0
	_knock_t = 0.8
	pet.show_egg = true
	pet.egg_cracks = 0
	if _egg_anchor == null:
		_egg_anchor = Control.new()
		_egg_anchor.size = Vector2(4, 4)
		_egg_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_egg_anchor)
	_dismiss_tip()
	_show_tip({"id": "", "text": "tip.prehatch"})
	Audio.play("ding")


func _update_prehatch(delta: float) -> void:
	if not _prehatch or _prehatch_ending:
		return
	_egg_anchor.position = pet.position + pet.head_point() - Vector2(2, 2)
	_prehatch_t += delta
	_knock_t -= delta
	if _knock_t <= 0.0:
		_knock_t = randf_range(1.3, 2.1)
		_knock(false)
	if _prehatch_t >= PREHATCH_AUTO:
		pet.egg_cracks = PREHATCH_TAPS
		_end_prehatch()


## Golpecito en la cascara: el huevo se sacude y sale un "toc" (si lo tocaste, se raja un poco mas).
func _knock(tapped: bool) -> void:
	pet.celebrate(0)
	Audio.play("stamp", randf_range(1.25, 1.45) if not tapped else 1.0)
	var toc := Label.new()
	toc.text = T.t("home.knock_tap") if tapped else T.t("home.knock")
	toc.add_theme_font_size_override("font_size", 34 if tapped else 28)
	toc.add_theme_color_override("font_color", Color("a0527a"))
	toc.add_theme_color_override("font_outline_color", Color.WHITE)
	toc.add_theme_constant_override("outline_size", 10)
	toc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toc)
	var side := -1.0 if randf() < 0.5 else 1.0
	toc.position = pet.position + pet.head_point() + Vector2(side * 110.0 - 40.0, -20.0)
	var tw := toc.create_tween().set_parallel()
	tw.tween_property(toc, "position:y", toc.position.y - 70.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(toc, "modulate:a", 0.0, 0.5).set_delay(0.4)
	tw.chain().tween_callback(toc.queue_free)


func _tap_prehatch() -> void:
	if _prehatch_ending:
		return
	pet.egg_cracks += 1
	_knock(true)
	_knock_t = maxf(_knock_t, 0.9)
	if pet.egg_cracks >= PREHATCH_TAPS:
		_end_prehatch()


func _end_prehatch() -> void:
	if _prehatch_ending:
		return
	_prehatch_ending = true
	_dismiss_tip()
	await get_tree().create_timer(0.5).timeout
	pet.show_egg = false
	pet.egg_cracks = 0
	_play_hatch()   # deja de estar pendiente: ya no vuelve a empezar
	_prehatch = false
	_prehatch_ending = false


## Animacion del nacimiento (una vez, al comprar la cuna): despues viene ponerle nombre.
func _play_hatch() -> void:
	GameState.hatch_anim_pending = false
	var anim := HatchAnimation.new()
	anim.pompon = GameState.pompon
	add_child(anim)
	_hatch_layer = anim
	pet.visible = false
	anim.finished.connect(func():
		_hatch_layer = null
		pet.visible = true
		pet.celebrate(6))


## Avisos importantes: el Pompon crecio / nacio, o se fue de casa.
func _any_modal() -> bool:
	return _gift_panel != null or _note_panel != null or _name_panel != null or _kid_layer != null \
		or _food_panel != null or _hatch_layer != null or _journal_panel != null or _profile_panel != null 		or _night_notice != null or _album_panel != null


func _check_news() -> void:
	if GameState.hatch_anim_pending and _hatch_layer == null and not _any_modal() and not _edit 			and GameState.pompon != null and GameState.pompon.hatched:
		if not _prehatch:
			_start_prehatch()
	elif GameState.farewell != "" and _note_panel == null:
		_show_farewell()
	elif GameState.daily_gift_available() and not _any_modal() and not _edit:
		_show_daily_gift()
	elif _needs_name() and not _any_modal() and not _edit:
		_show_name_dialog()
	elif (_needs_age() or _needs_kid_names()) and not _any_modal() and not _edit and _tut == null \
			and _tip_panel == null and not _prehatch:
		if _needs_age():
			_ask_age_once()
		else:
			_show_kid_names_notice()
	elif _night and not GameState.tips_seen.has(NIGHT_TIP) and not _any_modal() and not _edit:
		_show_night_notice()
	elif not _any_modal() and not _edit:
		_check_tips()
	if GameState.stage_news != "" and GameState.pompon != null and _hatch_layer == null and not GameState.hatch_anim_pending:
		var news := GameState.stage_news
		GameState.stage_news = ""
		pet.celebrate(8)
		Audio.play("hatch" if news.begins_with("¡Tu huevo") else "success")
		_speech.text = news
		_bubble.visible = true
		_speech_timer = 8.0


# Guias para la primera vez: de una en una y solo una vez ("text" = clave en locale/textos.csv). Primero la Tienda (el baul de
# Decorar esta vacio hasta que compres algo), y recien despues "Decorar".
const TIPS := [
	{"id": "egg1", "when": "egg", "text": "tip.egg1", "critical": true},
	{"id": "job1", "when": "egg", "text": "tip.job1", "critical": true},
	{"id": "shopcrib", "when": "crib_affordable", "text": "tip.shopcrib", "critical": true},
	{"id": "growth", "when": "born", "text": "tip.growth", "critical": true},
	{"id": "care", "when": "born", "text": "tip.care"},
	{"id": "pet", "when": "born", "text": "tip.pet"},
	{"id": "decor", "when": "furniture", "text": "tip.decor"},
	{"id": "coins", "when": "born", "text": "tip.coins"},
	{"id": "friends", "when": "born", "text": "tip.friends"},
	{"id": "town1", "when": "door", "text": "tip.town1"},
]
var _hatch_layer: HatchAnimation
# antes de nacer: el huevo golpea la cascara ("toc, toc") y se raja con cada toque
const PREHATCH_TAPS := 3
const PREHATCH_AUTO := 12.0       # si nadie lo toca, nace solo
var _prehatch := false
var _prehatch_ending := false   # ya se rompio: en medio segundo empieza la animacion
var _prehatch_t := 0.0
var _knock_t := 0.0
var _egg_anchor: Control          # punto sobre el huevo (para la flecha)
var _level_badge: Control
var _level_value := 0
var _mood_pill: PanelContainer
var _mood_icon: Control
var _mood_label: Label
var _mood_kind := "smile"
var _mood_color := Color("5fc77f")
var _mood_rng := RandomNumberGenerator.new()
const PILL_SECONDS := 12.0        # cuanto se ve un pensamiento o sentimiento nuevo
const THOUGHT_MIN := 240.0        # entre un pensamiento espontaneo y el siguiente (segundos)
const THOUGHT_MAX := 420.0
const THOUGHT_GAP := 45.0         # minimo entre dos entradas del diario (para no llenar de mensajes)
const SPONTANEOUS_GAP := 180.0    # un pensamiento espontaneo solo sale si pasaron al menos 3 min desde el ultimo
const URGENT_GAP := 1200.0        # una misma necesidad urgente se vuelve a decir cada 20 min como maximo
const KIND_COLORS := {"pensamiento": Color("a98bea"), "sentimiento": Color("ff7aa8"), "frase": Color("5fc77f")}
var _tip_panel: PanelContainer
var _tip_tween: Tween
var _tip_timer := 1.5
var _visit_time := 0.0
var _optional_shown := false
const TIP_SECONDS := 8.0
const OPTIONAL_TIP_DELAY := 40.0       # segundos en la casa antes de una guia opcional
const OPTIONAL_TIP_COOLDOWN := 240.0   # entre una guia opcional y la siguiente
static var _last_optional_tip := -100000.0


## Tarjeta blanca con borde rosa para los avisos.
func _style_modal(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 38, Color("ffb3d1"), 6, 16))


## La flecha señala el siguiente paso: primero Trabajo (para ganar monedas) y despues la Tienda (la cuna).
func _update_arrow() -> void:
	var target: Control = null
	if _prehatch:
		target = _egg_anchor  # "¡tócalo!"
	elif GameState.egg_waiting() and not GameState.owns_crib() and not _edit and not _any_modal():
		target = _shop_button if GameState.coins >= _crib_price() else _job_button
	elif _tip_id == "town1" and _tip_panel != null and _door.visible:
		target = _door   # "¡toca la puerta!"
	_arrow.set_target(target)


func _crib_price() -> int:
	return int(Catalog.get_item(GameState.CRIB_ID)["price"])


func _tip_ready(tip: Dictionary) -> bool:
	var p := GameState.pompon
	match tip["when"]:
		"egg":
			return not _is_born(p)
		"crib_affordable":
			return not _is_born(p) and not GameState.owns_crib() and GameState.coins >= _crib_price()
		"born":
			return _is_born(p)
		"furniture":
			return _is_born(p) and GameState.owned.any(func(id): return Catalog.is_placeable(id))
		"door":
			return _is_born(p) and _door != null and _door.visible
	return true


## Las guias del primer paso (la cuna) salen enseguida; las demas son opcionales: una por visita,
## con pausas largas, para no molestar. Todas son avisos chicos que no tapan el juego.
## Cuando el Pompon sube de nivel (cada dia) avisa los items nuevos de la tienda.
func _check_level_up() -> bool:
	var p := GameState.pompon
	if not _is_born(p):
		return false
	var level := GameState.pompon_level()
	if GameState.level_seen <= 0:
		GameState.level_seen = level  # primera vez (o partida vieja): sin aviso
		GameState.save_game()
		return false
	if level <= GameState.level_seen:
		return false
	var old_level := GameState.level_seen
	var fresh: Array = Catalog.ITEMS.filter(func(i): return Catalog.unlock_level(i["id"]) > old_level and Catalog.unlock_level(i["id"]) <= level)
	var new_rooms: Array = []
	for i in Rooms.count():
		if Rooms.unlock_level(i) > old_level and Rooms.unlock_level(i) <= level:
			new_rooms.append(Rooms.room_name(i))
	GameState.level_seen = level
	GameState.save_game()
	_sync_rooms()
	_react("levelup", 1.0, true)
	var text := "¡Nivel %d!" % level
	if not new_rooms.is_empty():
		text += "
¡Nueva habitación: %s!" % " y ".join(new_rooms)
	elif not fresh.is_empty():
		var names: Array = fresh.slice(0, 2).map(func(i): return i["name"])
		text += "
Nuevo en la tienda: %s" % (" y ".join(names) if fresh.size() <= 2 else "%s y %d más" % [", ".join(names), fresh.size() - 2])
	_show_tip({"id": "", "text": text})
	Audio.play("success")
	return true


func _check_tips() -> void:
	var delta := get_process_delta_time()
	_visit_time += delta
	_tip_timer -= delta
	if _tip_timer > 0.0 or GameState.pompon == null or _tip_panel != null:
		return
	_tip_timer = 1.0
	if _check_level_up():
		return
	var now := Time.get_ticks_msec() / 1000.0
	for tip in TIPS:
		if GameState.tips_seen.has(tip["id"]) or not _tip_ready(tip):
			continue
		if not tip.get("critical", false):
			if _optional_shown or _visit_time < OPTIONAL_TIP_DELAY or now - _last_optional_tip < OPTIONAL_TIP_COOLDOWN:
				continue
			_last_optional_tip = now
			_optional_shown = true
		_show_tip(tip)
		return


## Aviso chico sobre la barra de abajo: desaparece solo a los 8 segundos o al tocarlo.
func _show_tip(tip: Dictionary) -> void:
	_tip_id = tip["id"]
	if tip["id"] != "":
		GameState.tips_seen.append(tip["id"])  # se marca como vista al mostrarse: no se repite
		GameState.save_game()
	var panel := PanelContainer.new()
	_tip_panel = panel
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 22
	panel.offset_right = -22
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 32, Color("ffb3d1"), 5, 12))
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	var label := Label.new()
	var furniture_name: String = Catalog.required_furniture(GameState.pompon.species).get("name", "mueble")
	label.text = T.t(str(tip["text"])).replace("\r", "").replace("{coins}", str(GameState.coins)).replace("{furniture}", furniture_name).replace("{price}", str(_crib_price())).replace("{name}", GameState.pompon.display_name()).replace("{days}", str(PomponGrowth.days_left(GameState.pompon, int(Time.get_unix_time_from_system()))))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_constant_override("line_spacing", -2)
	label.add_theme_color_override("font_color", Color("a0527a"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var balance := Control.new()  # mismo ancho que el boton: el texto queda centrado en el aviso
	balance.custom_minimum_size = Vector2(66, 0)
	balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(balance)
	row.add_child(label)
	# boton redondo con una tilde (no se estira con el texto)
	var ok := Button.new()
	ok.custom_minimum_size = Vector2(66, 66)
	ok.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ok.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover"]:
		ok.add_theme_stylebox_override(state, Hud.pill(Color("5fc77f"), Color.WHITE, 33, 4))
	ok.add_theme_stylebox_override("pressed", Hud.pill(Color("4fb06d"), Color.WHITE, 33, 0))
	ok.draw.connect(func(): Hud.draw_icon(ok, "check", ok.size * 0.5, 40.0, Color.WHITE))
	ok.pressed.connect(_dismiss_tip)
	row.add_child(ok)
	panel.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_dismiss_tip())
	_place_tip()
	panel.modulate.a = 0.0
	if _tip_tween != null:
		_tip_tween.kill()
	_tip_tween = panel.create_tween()
	_tip_tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	_tip_tween.tween_interval(TIP_SECONDS)
	_tip_tween.tween_callback(func():
		if _tip_panel == panel:
			_dismiss_tip())


func _dismiss_tip() -> void:
	if _tip_panel == null:
		return
	var panel := _tip_panel
	_tip_panel = null
	_tip_timer = 1.5  # una pausa antes de la siguiente guia
	if _tip_tween != null:
		_tip_tween.kill()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 0.2)
	tw.tween_callback(panel.queue_free)


## El aviso queda justo encima de la barra de abajo.
func _place_tip() -> void:
	if _tip_panel == null:
		return
	var top := _dock.position.y if _dock.visible else size.y - 20.0
	_tip_panel.offset_bottom = -(size.y - top) - 12.0


## Regalo diario de monedas (sin presion: si faltas un dia solo vuelve a empezar en 10).
func _show_daily_gift() -> void:
	_gift_panel = PanelContainer.new()
	_gift_panel.set_anchors_preset(Control.PRESET_CENTER)
	_gift_panel.offset_left = -300
	_gift_panel.offset_right = 300
	_gift_panel.offset_top = -170
	_gift_panel.offset_bottom = 170
	_style_modal(_gift_panel)
	add_child(_gift_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	_gift_panel.add_child(box)
	var next_streak := GameState.gift_streak + 1 if Missions.today(int(Time.get_unix_time_from_system())) == GameState.daily_gift_day + 1 else 1
	var amount := 10 + 5 * mini(next_streak - 1, 4)
	var label := Label.new()
	label.text = T.t("home.gift", {"n": amount})
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color("d6336c"))
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(label)
	var ok := Button.new()
	ok.text = T.t("common.thanks")
	ok.custom_minimum_size = Vector2(0, 90)
	Hud.style_primary(ok, 38)
	ok.pressed.connect(func():
		GameState.claim_daily_gift()
		_gift_panel.queue_free()
		_gift_panel = null)
	box.add_child(ok)


func _show_farewell() -> void:
	_note_panel = PanelContainer.new()
	_note_panel.set_anchors_preset(Control.PRESET_CENTER)
	_note_panel.offset_left = -310
	_note_panel.offset_right = 310
	_note_panel.offset_top = -300
	_note_panel.offset_bottom = 300
	_style_modal(_note_panel)
	add_child(_note_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	_note_panel.add_child(box)
	var note := Label.new()
	note.text = GameState.farewell
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 28)
	note.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(note)
	var ok := Button.new()
	ok.text = T.t("home.adopt_another")
	ok.custom_minimum_size = Vector2(0, 90)
	Hud.style_primary(ok, 32)
	ok.pressed.connect(func():
		GameState.farewell = ""
		GameState.save_game()
		_note_panel.queue_free()
		_note_panel = null
		get_tree().change_scene_to_file("res://scenes/welcome.tscn"))
	box.add_child(ok)
	var later := Button.new()
	later.text = T.t("home.later")
	later.custom_minimum_size = Vector2(0, 70)
	Hud.style_soft(later, 28)
	later.pressed.connect(func():
		GameState.farewell = ""
		GameState.save_game()
		_note_panel.queue_free()
		_note_panel = null)
	box.add_child(later)


# ------------------------------------------------------------------ interfaz

func _build_bubble() -> void:
	_bubble = PanelContainer.new()
	_bubble.set_anchors_preset(Control.PRESET_TOP_LEFT)  # sigue al Pompon (ver _place_pet)
	_bubble.custom_minimum_size = Vector2(380, 0)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 30, Color("ffd0e2"), 4, 6))
	add_child(_bubble)
	_speech = Label.new()
	_speech.add_theme_font_size_override("font_size", 28)
	_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.custom_minimum_size = Vector2(340, 0)   # sin ancho minimo el texto se parte letra por letra y el globo se estira
	_bubble.add_child(_speech)


func _make_bar(stat: String, height: float, font_size: int, with_text := false) -> StatBar:
	var bar := StatBar.new().setup(stat)
	bar.custom_minimum_size = Vector2(0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.font_size = font_size
	if with_text:
		bar.text = T.label(STAT_LABELS[stat])
	return bar


## Tarjeta de arriba: foto del Pompon, nombre, las 4 necesidades con iconos y "Ver todo" (las 9).
func _build_bars() -> void:
	var panel: PanelContainer = $InfoPanel
	panel.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.93), 34, Color.WHITE, 3, 10))
	panel.offset_left = 16
	panel.offset_right = -16
	panel.offset_top = 112
	var info: VBoxContainer = $InfoPanel/Info
	info.add_theme_constant_override("separation", 10)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	var avatar := Panel.new()
	_avatar_panel = avatar
	avatar.custom_minimum_size = Vector2(112, 112)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.add_theme_stylebox_override("panel", _avatar_style("Hembra"))
	header.add_child(avatar)
	_avatar_view = PomponView.new()
	_avatar_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_avatar_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.add_child(_avatar_view)
	# estrellita con el nivel: en la esquina de abajo a la derecha, un poco afuera de la foto
	_level_badge = Control.new()
	_level_badge.set_anchors_preset(Control.PRESET_FULL_RECT)
	_level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_badge.draw.connect(func():
		var c := Vector2(_level_badge.size.x - 8.0, _level_badge.size.y - 8.0)
		var pts := PackedVector2Array()
		for i in 20:
			var a := -PI / 2.0 + PI * i / 10.0
			pts.append(c + Vector2(cos(a), sin(a)) * (24.0 if i % 2 == 0 else 18.0))
		_level_badge.draw_colored_polygon(pts, Color("ffcf3f"))
		pts.append(pts[0])
		_level_badge.draw_polyline(pts, Color("b87400"), 3.0, true)
		_level_badge.draw_string(_level_badge.get_theme_default_font(), c + Vector2(-24, 7), str(_level_value), HORIZONTAL_ALIGNMENT_CENTER, 48, 20, Color("7a4a00")))
	avatar.add_child(_level_badge)
	var tap := Button.new()   # tocar la foto abre el perfil
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		tap.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	tap.pressed.connect(_show_profile)
	avatar.add_child(tap)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 2)
	title.reparent(texts)
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 10)
	_sex_badge = Control.new()
	_sex_badge.custom_minimum_size = Vector2(40, 40)
	_sex_badge.draw.connect(func():
		var col := Color("ff7aa8") if _sex_kind == "female" else Color("5bb8f5")
		var c := _sex_badge.size * 0.5
		_sex_badge.draw_circle(c, 19.0, Color.WHITE)
		_sex_badge.draw_circle(c, 16.0, col)
		Hud.draw_icon(_sex_badge, _sex_kind, c, 30.0, Color.WHITE))
	detail_row.add_child(_sex_badge)
	details.reparent(detail_row)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texts.add_child(detail_row)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Hud.INK)
	details.add_theme_font_size_override("font_size", 21)
	details.add_theme_color_override("font_color", Color("a0527a"))
	header.add_child(texts)

	_toggle_button = Button.new()
	_toggle_button.custom_minimum_size = Vector2(64, 64)
	_toggle_button.focus_mode = Control.FOCUS_NONE
	Hud.style_soft(_toggle_button)
	_toggle_button.draw.connect(func():
		Hud.draw_icon(_toggle_button, _toggle_icon, _toggle_button.size * 0.5, 40.0, Color("d6336c")))
	_toggle_button.pressed.connect(func():
		_expanded = not _expanded
		_toggle_icon = "chevron_up" if _expanded else "chevron_down"
		_toggle_button.queue_redraw())
	var toggle_holder := CenterContainer.new()
	toggle_holder.add_child(_toggle_button)
	header.add_child(toggle_holder)
	info.add_child(header)
	info.move_child(header, 0)

	var mini := HBoxContainer.new()
	mini.add_theme_constant_override("separation", 10)
	for s in ["alimentacion", "hidratacion", "aseo", "diversion", "sueno"]:
		var bar := _make_bar(s, 40.0, 16)
		mini.add_child(bar)
		_mini_nodes[s] = bar
	info.add_child(mini)
	info.move_child(mini, 1)
	_mini_row = mini

	# calidad de crecimiento: la barra mas importante (se ve siempre mientras crece). Tocarla abre el perfil.
	_growth_bar = StatBar.new().setup("", "sprout", Color("5fc77f"))
	_growth_bar.custom_minimum_size = Vector2(0, 54)
	_growth_bar.font_size = 23
	info.add_child(_growth_bar)
	info.move_child(_growth_bar, 2)
	_growth_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_growth_bar.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_show_profile())
	_growth_hint = Label.new()
	_growth_hint.add_theme_font_size_override("font_size", 20)
	_growth_hint.add_theme_color_override("font_color", Color("a0527a"))
	_growth_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(_growth_hint)
	info.move_child(_growth_hint, 3)

	# el huevo: cuanto falta para la cuna
	_crib_bar = StatBar.new().setup("", "crib", Color("ffb938"))
	_crib_bar.custom_minimum_size = Vector2(0, 46)
	_crib_bar.font_size = 21
	_crib_bar.max_value = 50.0
	info.add_child(_crib_bar)
	info.move_child(_crib_bar, 2)

	# las 9 estadisticas, de a dos por fila
	var names: Array = Pompon.STAT_NAMES.filter(func(n): return n != "inteligencia")   # el crecimiento la reemplaza
	var row: HBoxContainer = null
	for i in names.size():
		if i % 2 == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			bars.add_child(row)
		var bar2 := _make_bar(names[i], 42.0, 17, true)
		row.add_child(bar2)
		_bar_nodes[names[i]] = bar2
	bars.add_theme_constant_override("separation", 8)


func _build_actions() -> void:
	# monedas: pildora arriba a la derecha
	_coin_pill = PanelContainer.new()
	_coin_pill.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_coin_pill.offset_left = -240
	_coin_pill.offset_right = -16
	_coin_pill.offset_top = 22
	_coin_pill.offset_bottom = 82
	_coin_pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_coin_pill.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.93), 30, Color.WHITE, 3, 6))
	add_child(_coin_pill)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 8)
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_coin_pill.add_child(coin_row)
	# reloj (la hora del jugador): solcito de dia, luna de noche
	_clock_icon = Control.new()
	_clock_icon.custom_minimum_size = Vector2(30, 30)
	_clock_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_clock_icon.draw.connect(func():
		var c := _clock_icon.size * 0.5
		if DayClock.night_now():
			Hud.draw_icon(_clock_icon, "moon", c, 34.0, Color("7b8ce0"))
		else:
			for i in 8:
				var a := TAU * i / 8.0
				_clock_icon.draw_line(c + Vector2(cos(a), sin(a)) * 10.0, c + Vector2(cos(a), sin(a)) * 14.0, Color("ffb938"), 3.0, true)
			_clock_icon.draw_circle(c, 8.0, Color("ffcf3f")))
	coin_row.add_child(_clock_icon)
	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 24)
	_clock_label.add_theme_color_override("font_color", Hud.INK)
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_row.add_child(_clock_label)
	var sep := ColorRect.new()
	sep.color = Color("f0dfe7")
	sep.custom_minimum_size = Vector2(3, 34)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_row.add_child(sep)
	var coin_icon := Control.new()
	coin_icon.custom_minimum_size = Vector2(36, 36)
	coin_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_icon.draw.connect(func(): Hud.draw_icon(coin_icon, "coin", coin_icon.size * 0.5, 36.0, Color.WHITE))
	coin_row.add_child(coin_icon)
	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 28)
	_coins_label.add_theme_color_override("font_color", Color("b87400"))
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_row.add_child(_coins_label)

	# arriba a la izquierda, las cosas del cuidador: Menu, Misiones, Vecinos, Trabajo y Diario
	# (circulo con icono y nombre corto). Abajo quedan solo los cuidados del Pompon.
	var x := 12.0
	for entry in [["Menú", "menu", "menu", Color("a98bea")], ["Misiones", "missions", "star", Color("ffb938")],
			["Vecinos", "neighbors", "people", Color("5fc77f")], ["Trabajo", "job_board", "case", Color("ff9b54")],
			["Diario", "", "book", Color("5bb8f5")]]:
		var tb := ActionButton.new().setup(entry[2], entry[0], entry[3], 54.0)
		tb.label_size = 17
		tb.set_anchors_preset(Control.PRESET_TOP_LEFT)
		tb.position = Vector2(x, 10)
		tb.custom_minimum_size = Vector2(90, 90)
		tb.size = Vector2(90, 90)
		var scene_name: String = entry[1]
		if scene_name == "":
			tb.pressed.connect(_show_journal)
		else:
			tb.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene_name))
		add_child(tb)
		_top_buttons.append(tb)
		if entry[0] == "Trabajo":
			_job_button = tb
		if entry[0] == "Misiones":  # punto rojo: hay un sello de la semana o una medalla para cobrar
			_missions_dot = _red_dot()
			tb.add_child(_missions_dot)
		if entry[0] == "Vecinos":  # punto rojo: hay solicitudes de amistad esperando
			_friends_dot = Control.new()
			_friends_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_friends_dot.position = Vector2(62, 2)
			_friends_dot.size = Vector2(22, 22)
			_friends_dot.draw.connect(func():
				_friends_dot.draw_circle(Vector2(11, 11), 11.0, Color.WHITE)
				_friends_dot.draw_circle(Vector2(11, 11), 8.0, Color("e0295f")))
			_friends_dot.visible = false
			tb.add_child(_friends_dot)
		x += 92.0

	# barra de abajo: dos solapas (Pompon y Casa), ver HomeDock
	_dock = HomeDock.new()
	add_child(_dock)
	_dock.eat_pressed.connect(_show_food_menu)
	_dock.care_pressed.connect(_on_action)
	_dock.games_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/minigames.tscn"))
	_dock.shop_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	_dock.wardrobe_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/wardrobe.tscn"))
	_dock.decorate_pressed.connect(func(): _set_edit(true))
	_dock.room_pressed.connect(_on_room_pressed)
	_shop_button = _dock.shop_button


# ------------------------------------------------------------ pensamientos y diario

## Lo que el Pompon dice, piensa y siente: sale cada tanto, queda en el diario y se ve un rato.
## Las frases ("dijo") salen en el globo sobre el Pompon; los pensamientos y sentimientos, en la pildora de arriba.
func _can_think() -> bool:
	var p := GameState.pompon
	return _is_born(p) and p.stage_index(int(Time.get_unix_time_from_system())) > 0 \
		and _hatch_layer == null and GameState.farewell == "" and not _needs_name()


func _thought_ctx() -> Dictionary:
	var items: Array = []
	var on_pairs: Array = []
	for pl in GameState.placed:
		if int(pl.get("room", 0)) != GameState.current_room:
			continue
		items.append(pl["id"])
		if pl.has("on"):
			on_pairs.append([pl["id"], pl["on"]])
	return {"now": int(Time.get_unix_time_from_system()), "hour": DayClock.hour_now(), "sleeping": pet.sleeping,
		"room": GameState.current_room, "items": items, "on_pairs": on_pairs, "equipped": GameState.equipped,
		"events": GameState.events, "jobs_done": GameState.jobs_done, "level": GameState.pompon_level()}


func _since_last_entry() -> float:
	return float(int(Time.get_unix_time_from_system()) - GameState.last_journal_time())


## Anota la entrada en el diario y la muestra: globo (frase) o pildora (pensamiento / sentimiento).
func _log_thought(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	GameState.add_journal(entry)
	_thought_timer = randf_range(THOUGHT_MIN, THOUGHT_MAX)
	if entry["kind"] == PomponThoughts.KIND_SAY:
		_say(entry["text"], 6.0)
	else:
		_show_thought_pill(entry)


func _show_thought_pill(entry: Dictionary) -> void:
	var color: Color = KIND_COLORS[entry["kind"]]
	_mood_label.text = entry["text"]
	_mood_kind = Hud.STAT_ICONS.get(entry["stat"], "smile")
	_mood_color = color
	_set_mood_style(color)
	_mood_icon.queue_redraw()
	_pill_left = PILL_SECONDS
	_mood_pill.modulate.a = 0.0
	create_tween().tween_property(_mood_pill, "modulate:a", 1.0, 0.35)


func _say(text: String, seconds: float) -> void:
	_speech.text = text
	_bubble.visible = not _edit and not _any_modal()
	_speech_timer = seconds


## Reaccion a algo que acaba de pasar: solo a veces (`chance`) y sin llenar el diario (THOUGHT_GAP).
func _react(event: String, chance := 0.7, force := false) -> void:
	if not _can_think() or randf() > chance:
		return
	if not force and _since_last_entry() < THOUGHT_GAP:
		return
	_log_thought(PomponThoughts.reaction(event, GameState.pompon, _thought_ctx(), _mood_rng))


func _update_thoughts(delta: float) -> void:
	if not _can_think() or _edit or _any_modal():
		return
	var p := GameState.pompon
	var now := int(Time.get_unix_time_from_system())
	if not _offline_checked:  # al abrir el juego despues de un rato: te extraño
		_offline_checked = true
		var away := GameState.offline_seconds
		GameState.offline_seconds = 0
		_log_thought(PomponThoughts.welcome_back(p, now, away, _mood_rng))
		return
	if p.age_seconds(now) < 86400:  # recien nacido: sorpresa, curiosidad y cariño (una sola vez)
		var ev: Dictionary = GameState.events
		var step := 0
		if not ev.has("birth1"):
			step = 1
		elif not ev.has("birth2") and now - int(ev["birth1"]) >= 60:
			step = 2
		elif not ev.has("birth3") and ev.has("birth2") and now - int(ev["birth1"]) >= 150:
			step = 3
		if step > 0:
			ev["birth%d" % step] = now
			if step == 1:
				pet.celebrate(3)
			_log_thought(PomponThoughts.birth(p, step))
			return
	_stat_check -= delta
	if _stat_check <= 0.0:  # una necesidad que se vuelve urgente se dice enseguida (una vez cada tanto)
		_stat_check = 5.0
		for stat in PomponThoughts.NEED_TEXT:
			if PomponThoughts.need_level(stat, float(p.stats.get(stat, 100.0))) < 2:
				continue
			var key: String = "alert:" + stat
			if float(now - int(GameState.events.get(key, 0))) < URGENT_GAP or _since_last_entry() < 60.0:
				continue
			GameState.events[key] = now
			_log_thought(PomponThoughts.urgent(p, stat, now, _mood_rng))
			return
	_thought_timer -= delta
	if _thought_timer <= 0.0:
		_thought_timer = randf_range(THOUGHT_MIN, THOUGHT_MAX)
		if _since_last_entry() >= SPONTANEOUS_GAP:
			_log_thought(PomponThoughts.spontaneous(p, _thought_ctx(), GameState.recent_journal_texts(14), _mood_rng))


## Gustos: cuenta el tiempo en cada habitacion y anota en el diario los favoritos nuevos.
func _update_tastes(delta: float) -> void:
	var p := GameState.pompon
	if not _is_born(p):
		return
	PomponTastes.add_room_time(p, GameState.current_room, delta)
	if not GameState.pending_thoughts.is_empty() and _can_think() and not _edit and not _any_modal() and _since_last_entry() >= 4.0:
		_log_thought(GameState.pending_thoughts.pop_front())


## Cada minuto mira como estan sus necesidades (cuenta para la calidad de crecimiento) y si aprendio palabras.
func _update_growth(delta: float) -> void:
	var p := GameState.pompon
	if not _is_born(p):
		return
	_growth_timer -= delta
	if _growth_timer > 0.0:
		return
	_growth_timer = 60.0
	var now := int(Time.get_unix_time_from_system())
	PomponGrowth.sample_needs(p, now)
	for e in PomponGrowth.check_words(p, now):
		GameState.pending_thoughts.append(e)


## La pausa entre una actividad con objetos y la siguiente (las actividades estan en _try_play).
func _update_practice(delta: float) -> void:
	if _play_state != "using":
		_practice_left = maxf(_practice_left - delta, 0.0)
	_play_cd = maxf(_play_cd - delta, 0.0)


## Perfil: todo lo que se sabe del Pompon y lo que fue aprendiendo (se abre tocando su foto).
func _show_profile() -> void:
	var p := GameState.pompon
	if _profile_panel != null or not _is_born(p) or _any_modal():
		return
	var panel := ProfilePanel.new().setup(p)
	_profile_panel = panel
	panel.closed.connect(func():
		panel.queue_free()
		_profile_panel = null)
	add_child(panel)


func _avatar_style(sex: String) -> StyleBoxFlat:
	var female := sex != "Macho"
	return Hud.card(Color("ffe3ee") if female else Color("dcecfb"), 56, Color("ff9ec0") if female else Color("8cc8f5"), 5, 4)


## Cuadrito que explica que esta haciendo ahora el Pompon (siempre hace algo).
func _build_activity() -> void:
	_activity_chip = PanelContainer.new()
	_activity_chip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_activity_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_activity_chip.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.84), 24, Color("ffd0e2"), 3, 4))
	_activity_chip.visible = false
	add_child(_activity_chip)
	_activity_label = Label.new()
	_activity_label.add_theme_font_size_override("font_size", 23)
	_activity_label.add_theme_color_override("font_color", Color("a0527a"))
	_activity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_activity_chip.add_child(_activity_label)


func _update_activity(delta: float) -> void:
	var p := GameState.pompon
	var show := _is_born(p) and p.stage_index(int(Time.get_unix_time_from_system())) > 0 		and not _edit and not _any_modal()
	_activity_chip.visible = show
	if not show:
		return
	_activity_timer -= delta
	if _night:  # de noche: durmiendo, jugando en la cama o tomando algo
		_activity_label.text = _night_activity_text()
	elif _practice_left > 0.0 and (not pet.walking or _play_state == "using"):  # jugando con un objeto de su cuarto
		_activity_label.text = _practice_text
		_activity_timer = 8.0   # despues de practicar, se queda un rato antes de cambiar
		_activity_walking = false
	elif _activity_timer <= 0.0 or _activity_label.text == "":   # cambia cada 8 a 14 segundos, no cada vez que se frena o arranca
		_activity_walking = pet.walking
		_activity_timer = randf_range(8.0, 14.0)
		var ctx := _thought_ctx()
		var text: String
		if _activity_walking:
			text = PomponActivity.walking(p, ctx, _mood_rng)
		else:
			text = PomponActivity.idle(p, ctx, _mood_rng, _activity_last)
		_activity_last = text.substr(p.display_name().length() + 1)
		_activity_label.text = text
	var y: float = $InfoPanel.position.y + $InfoPanel.size.y + 10.0
	if _mood_pill.visible:
		y += _mood_pill.size.y + 8.0
	_activity_chip.size = _activity_chip.get_combined_minimum_size()
	_activity_chip.position = Vector2(16.0, y)


## Diario: todo lo que el Pompon penso, sintio y dijo (lo mas nuevo arriba).
func _show_journal() -> void:
	if _journal_panel != null or GameState.pompon == null:
		return
	_journal_panel = PanelContainer.new()
	_journal_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_journal_panel.offset_left = 24
	_journal_panel.offset_right = -24
	_journal_panel.offset_top = 110
	_journal_panel.offset_bottom = -24
	_style_modal(_journal_panel)
	add_child(_journal_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_journal_panel.add_child(box)
	var head := Label.new()
	head.text = "Diario de %s" % GameState.pompon.display_name()
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 40)
	head.add_theme_color_override("font_color", Color("d6336c"))
	box.add_child(head)
	var sub := Label.new()
	sub.text = "Lo que piensa, siente y dice"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color("a0527a"))
	box.add_child(sub)
	var prog := PomponAlbum.progress(GameState.pompon, int(Time.get_unix_time_from_system()))
	var album := Button.new()
	album.text = "Álbum de recuerdos (%d/%d)" % [prog["won"], prog["total"]]
	album.custom_minimum_size = Vector2(0, 68)
	album.focus_mode = Control.FOCUS_NONE
	Hud.style_primary(album, 26, Color("ffb938"))
	album.pressed.connect(func():
		_journal_panel.queue_free()
		_journal_panel = null
		_show_album())
	box.add_child(album)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var journal: Array = GameState.journal
	if journal.is_empty():
		var empty := Label.new()
		empty.text = "Todavía no hay recuerdos.\n%s irá anotando lo que piensa y siente." % GameState.pompon.display_name()
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 28)
		empty.add_theme_color_override("font_color", Hud.INK)
		list.add_child(empty)
	var now := int(Time.get_unix_time_from_system())
	var bias := int(Time.get_time_zone_from_system()["bias"]) * 60
	var last_day := -999999
	for i in range(journal.size() - 1, -1, -1):
		var e: Dictionary = journal[i]
		var day := (int(e["t"]) + bias) / 86400
		if day != last_day:
			last_day = day
			list.add_child(_journal_day_label(day, (now + bias) / 86400, int(e["t"]) + bias))
		list.add_child(_journal_card(e, now, bias))
	var close := Button.new()
	close.text = "Cerrar"
	close.custom_minimum_size = Vector2(0, 80)
	Hud.style_primary(close, 34)
	close.pressed.connect(func():
		_journal_panel.queue_free()
		_journal_panel = null)
	box.add_child(close)


func _journal_day_label(day: int, today: int, local_t: int) -> Label:
	var l := Label.new()
	if day == today:
		l.text = "Hoy"
	elif day == today - 1:
		l.text = "Ayer"
	else:
		var d := Time.get_date_dict_from_unix_time(local_t)
		l.text = "%d/%d" % [d["day"], d["month"]]
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color("a0527a"))
	return l


func _journal_card(e: Dictionary, now: int, bias: int) -> PanelContainer:
	var color: Color = KIND_COLORS[e["kind"]]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.97), 26, color.lightened(0.35), 3, 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(56, 56)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon: String = Hud.STAT_ICONS.get(e["stat"], "smile")
	badge.draw.connect(func():
		var c := badge.size * 0.5
		badge.draw_circle(c, 27.0, color)
		Hud.draw_icon(badge, icon, c, 34.0, Color.WHITE, color.darkened(0.3)))
	row.add_child(badge)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var age := now - int(e["t"])
	var when := "ahora" if age < 60 else ("hace %d min" % (age / 60) if age < 3600 else "%02d:%02d" % [Time.get_datetime_dict_from_unix_time(int(e["t"]) + bias)["hour"], Time.get_datetime_dict_from_unix_time(int(e["t"]) + bias)["minute"]])
	var meta := Label.new()
	meta.text = "%s · %s" % [String(PomponThoughts.KIND_VERBS[e["kind"]]).capitalize(), when]
	meta.add_theme_font_size_override("font_size", 20)
	meta.add_theme_color_override("font_color", color.darkened(0.25))
	col.add_child(meta)
	var text := Label.new()
	text.text = e["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 28)
	text.add_theme_color_override("font_color", Hud.INK)
	col.add_child(text)
	return card


# ------------------------------------------------------------ habitaciones y flechas

func _sync_rooms() -> void:
	_dock.refresh_rooms(GameState.pompon_level(), GameState.current_room)


## Pasa a la habitacion anterior o siguiente que ya este abierta (al decorar).
func _step_room(dir: int) -> void:
	var i := GameState.current_room + dir
	if i < 0 or i >= Rooms.count():
		return
	_on_room_pressed(i)


## Flechas para recorrer la habitacion: botones de verdad, siempre encima del Pompon y del globo.
func _build_scroll_arrows() -> void:
	for side in [-1, 1]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(68, 68)
		b.size = Vector2(68, 68)
		b.focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		b.set_anchors_preset(Control.PRESET_TOP_LEFT)
		b.draw.connect(func():
			var c := b.size * 0.5
			b.draw_circle(c, 29.0, Color(1, 1, 1, 0.92))
			b.draw_arc(c, 29.0, 0.0, TAU, 28, Color("ffb3d1"), 3.0, true)
			var d := float(side)
			b.draw_polyline(PackedVector2Array([c + Vector2(-6.0 * d, -13.0), c + Vector2(7.0 * d, 0.0), c + Vector2(-6.0 * d, 13.0)]), Color("d6336c"), 6.0, true))
		b.pressed.connect(func():
			room.scroll_to(room.scroll + side * size.x * 0.7)
			_follow_pause = 4.0)
		add_child(b)
		if side < 0:
			_nav_left = b
		else:
			_nav_right = b


func _place_arrows() -> void:
	var show := room.max_scroll() > 0.0 and not _any_modal()
	var y := maxf(size.y * 0.40 - 34.0, $InfoPanel.position.y + $InfoPanel.size.y + 100.0) if $InfoPanel.visible else size.y * 0.40 - 34.0
	_nav_left.position = Vector2(6.0, y)
	_nav_right.position = Vector2(size.x - 74.0, y)
	_nav_left.visible = show and room.scroll > 2.0
	_nav_right.visible = show and room.scroll < room.max_scroll() - 2.0


# ------------------------------------------------------------ modo decorar

func _build_edit_panel() -> void:
	_edit_panel = PanelContainer.new()
	_edit_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_edit_panel.offset_left = 12
	_edit_panel.offset_right = -12
	_edit_panel.offset_top = -310
	_edit_panel.offset_bottom = -12
	_edit_panel.visible = false
	_edit_panel.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 36, Color.WHITE, 3, 12))
	add_child(_edit_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_edit_panel.add_child(box)
	var room_row := HBoxContainer.new()
	room_row.add_theme_constant_override("separation", 10)
	box.add_child(room_row)
	var prev_room := Button.new()
	prev_room.text = "‹"
	prev_room.custom_minimum_size = Vector2(80, 56)
	Hud.style_soft(prev_room, 34)
	prev_room.pressed.connect(_step_room.bind(-1))
	room_row.add_child(prev_room)
	_edit_room_label = Label.new()
	_edit_room_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit_room_label.add_theme_font_size_override("font_size", 30)
	_edit_room_label.add_theme_color_override("font_color", Color("d6336c"))
	room_row.add_child(_edit_room_label)
	var next_room := Button.new()
	next_room.text = "›"
	next_room.custom_minimum_size = Vector2(80, 56)
	Hud.style_soft(next_room, 34)
	next_room.pressed.connect(_step_room.bind(1))
	room_row.add_child(next_room)
	var hint := Label.new()
	hint.text = "Arrastra para mover. Los adornos se apoyan en mesas y estantes."
	hint.add_theme_font_size_override("font_size", 20)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 112)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_tray = HBoxContainer.new()
	_tray.add_theme_constant_override("separation", 8)
	scroll.add_child(_tray)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	_store_button = Button.new()
	_store_button.text = "Guardar mueble"
	_store_button.disabled = true
	_store_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_store_button.custom_minimum_size = Vector2(0, 64)
	Hud.style_soft(_store_button, 24)
	_store_button.pressed.connect(func():
		if room.selected != "":
			GameState.store_item(room.selected)
			room.select("")
			_rebuild_tray())
	buttons.add_child(_store_button)
	var done := Button.new()
	done.text = "Listo"
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done.custom_minimum_size = Vector2(0, 64)
	Hud.style_primary(done, 28)
	done.pressed.connect(func(): _set_edit(false))
	buttons.add_child(done)


# ------------------------------------------------------------ habitaciones

func _on_room_pressed(i: int) -> void:
	if not Rooms.is_unlocked(i, GameState.pompon_level()):
		Audio.play("fail")
		if _tip_panel != null:
			_dismiss_tip()
		_show_tip({"id": "", "text": "%s se abre\nen el nivel %d" % [Rooms.room_name(i), Rooms.unlock_level(i)]})
		return
	if i == GameState.current_room:
		return
	GameState.set_room(i)
	Audio.play("pet")
	# el Pompon se viene con vos a la habitacion nueva
	_pet_pos = _world_center()
	_moving = false
	_wander_wait = 2.0
	room.scroll_to(room.max_scroll() * 0.5, false)
	room.select("")
	if _edit:
		_rebuild_tray()
	_sync_rooms()
	_show_room_toast(Rooms.room_name(i))
	_react("room_changed", 0.5)


## Cartelito con el nombre de la habitacion que se acaba de abrir.
func _show_room_toast(room_name: String) -> void:
	var toast := PanelContainer.new()
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.offset_top = size.y * 0.30
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 36, Color("ffb3d1"), 5, 10))
	var label := Label.new()
	label.text = room_name
	label.add_theme_font_size_override("font_size", 44)
	label.add_theme_color_override("font_color", Color("d6336c"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(label)
	add_child(toast)
	toast.modulate.a = 0.0
	var tw := toast.create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.1)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(toast.queue_free)


func _set_edit(on: bool) -> void:
	_edit = on
	room.edit_mode = on
	_edit_panel.visible = on
	pet.mouse_filter = Control.MOUSE_FILTER_IGNORE if on else Control.MOUSE_FILTER_STOP
	if on:
		_edit_before = GameState.placed_ids()
		_rebuild_tray()
	else:
		GameState.save_game()
		# lo recien puesto en esta habitacion: el Pompon va a verlo y dice algo (lo ultimo primero)
		var fresh: Array = _thought_ctx()["items"].filter(func(id): return not _edit_before.has(id))
		fresh.reverse()
		_discover = fresh.slice(0, 3)
		if not _discover.is_empty():
			_wander_wait = minf(_wander_wait, 0.4)


## Bandeja con los muebles comprados que todavia no estan en el cuarto.
func _rebuild_tray() -> void:
	for c in _tray.get_children():
		c.queue_free()
	var count := 0
	for id in GameState.owned:
		if Catalog.is_placeable(id) and not GameState.is_placed(id):
			count += 1
			var b := Button.new()
			Hud.style_soft(b, 20)
			b.custom_minimum_size = Vector2(100, 100)
			b.tooltip_text = Catalog.get_item(id)["name"]
			var icon := ItemIcon.new()
			icon.set_item(id, 84.0)
			icon.position = Vector2(8, 8)
			b.add_child(icon)
			b.pressed.connect(func():
				GameState.place_item(id, Vector2(-1.0, -1.0), (room.scroll + room.size.x * 0.5) / room.world_w())
				room.select(id)
				_rebuild_tray())
			_tray.add_child(b)
	if count == 0:
		var empty := Label.new()
		empty.text = "No te quedan muebles por colocar. ¡Compra más en la tienda!"
		empty.add_theme_font_size_override("font_size", 20)
		_tray.add_child(empty)


func _show_food_menu() -> void:
	if _food_panel != null:
		_food_panel.queue_free()
	var p := GameState.pompon
	_food_panel = PanelContainer.new()
	_food_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_food_panel.offset_left = 22
	_food_panel.offset_right = -22
	_food_panel.offset_top = 110
	_food_panel.offset_bottom = -22
	_style_modal(_food_panel)
	add_child(_food_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_food_panel.add_child(box)
	var head := Label.new()
	head.text = "¿Qué le damos a %s?" % (p.display_name() if p != null else "tu Pompon")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 38)
	head.add_theme_color_override("font_color", Color("d6336c"))
	box.add_child(head)
	var sub := Label.new()
	sub.text = "Lo nuevo le da desconfianza… ¡pero de a poco se anima!"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color("a0527a"))
	box.add_child(sub)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for food in PomponTastes.FOODS:
		grid.add_child(_food_card(food, p))
	var close := Button.new()
	close.text = "Cancelar"
	close.custom_minimum_size = Vector2(0, 70)
	Hud.style_soft(close, 26)
	close.pressed.connect(func():
		_food_panel.queue_free()
		_food_panel = null)
	box.add_child(close)


## Tarjeta de una comida: nombre, precio y como la ve el Pompon (nueva, duda o corazones).
func _food_card(food: Dictionary, p: Pompon) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 112)
	Hud.style_soft(b, 24)
	b.disabled = GameState.coins < food["price"]
	b.pressed.connect(_on_food.bind(food))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	b.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var tint: Color = [Color("e0b48f"), Color("ffa94d"), Color("ff7aa8")][food["tier"]]
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(56, 56)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.draw.connect(func():
		var c := badge.size * 0.5
		badge.draw_circle(c, 28.0, tint)
		Hud.draw_icon(badge, "apple", c, 36.0, Color.WHITE, tint.darkened(0.3)))
	row.add_child(badge)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 0)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	var name_label := Label.new()
	name_label.text = food["name"]
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Hud.INK)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(name_label)
	var price := Label.new()
	price.text = "gratis" if food["price"] == 0 else "%d monedas" % food["price"]
	price.add_theme_font_size_override("font_size", 18)
	price.add_theme_color_override("font_color", Color("a0527a"))
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(price)
	if p != null:
		if PomponTastes.is_new_food(p, food["id"]):
			var tag := Label.new()
			tag.text = "¡Nuevo!"
			tag.add_theme_font_size_override("font_size", 20)
			tag.add_theme_color_override("font_color", Color("d6336c"))
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			texts.add_child(tag)
		else:
			var hearts := PomponTastes.food_hearts(p, food["id"])
			if hearts == 0:
				var doubt := Label.new()
				doubt.text = "todavía duda"
				doubt.add_theme_font_size_override("font_size", 18)
				doubt.add_theme_color_override("font_color", Color("a0527a"))
				doubt.mouse_filter = Control.MOUSE_FILTER_IGNORE
				texts.add_child(doubt)
			else:
				texts.add_child(HeartsRow.new().setup(hearts, 20.0))
	return b


# ------------------------------------------------------------------- acciones

func _on_food(food: Dictionary) -> void:
	var p := GameState.pompon
	if p == null or GameState.coins < food["price"]:
		return
	if _play_state != "":   # deja lo que estaba haciendo para comer
		_end_play(false)
	GameState.coins -= food["price"]
	var now := int(Time.get_unix_time_from_system())
	var taste := {}
	if food.has("id"):  # el Pompon aprende sus gustos: lo nuevo da desconfianza, lo conocido gusta mas
		taste = PomponTastes.eat(p, food["id"], now)
	p.add_stat("alimentacion", food["alimentacion"] * float(taste.get("mult", 1.0)))
	p.add_stat("amor", (food["felicidad"] + float(taste.get("happy", 0.0))) * 0.5)   # comida rica o favorita: confia mas
	GameState.track("care")
	GameState._taste_check()
	GameState.save_game()
	_focus_pet()
	Audio.play("eat")
	pet.act("eat")
	_wander_wait = ACT_PAUSE
	if _food_panel != null:
		_food_panel.queue_free()
		_food_panel = null
	GameState.note_event("fed")
	var first := {}
	if food.has("id"):  # primera vez que la prueba (o, cada tanto, otra vez): queda en el diario
		first = PomponFirsts.experience(p, "food", food["id"], String(food["name"]).to_lower(), now, _mood_rng, _food_liking(p, food["id"]))
	if not first.is_empty():
		_log_first(first)
	elif not taste.is_empty() and str(taste["text"]) != "" and PomponTastes.times_eaten(p, food["id"]) > 1:
		if _can_think() and (taste["force"] or _since_last_entry() >= THOUGHT_GAP):
			_log_thought({"kind": taste["kind"], "text": taste["text"], "stat": taste["stat"], "key": "eat"})
	else:
		_react("fed", 0.8)
	_refresh()


func _on_action(action_name: String) -> void:
	var p := GameState.pompon
	if p == null:
		return
	var action: Dictionary = ACTIONS[action_name]
	if _play_state != "":   # deja lo que estaba haciendo para beber, bañarse o recibir mimos
		_end_play(false)
	for stat in action["stats"]:
		p.add_stat(stat, action["stats"][stat])
	GameState.track("care")
	GameState.save_game()
	_focus_pet()
	Audio.play(action["sfx"])
	if action["anim"] == "love":
		pet.celebrate(6)
	else:
		pet.act(action["anim"])
	_moving = false
	pet.walking = false
	_wander_wait = ACT_PAUSE
	var ev: String = {"Beber": "drank", "Bañar": "bathed", "Caricia": "petted"}[action_name]
	GameState.note_event(ev)
	if ev == "petted":
		PomponTastes.bump(p, "Timido", 0.6, int(Time.get_unix_time_from_system()))
		p.add_social(4.0, true)   # los mimos llenan la mitad de Social; la otra mitad es con otros Pompons
		GameState._taste_check()
	var kind: String = {"drank": "drink", "bathed": "bath", "petted": "pet"}[ev]
	var first := PomponFirsts.experience(p, kind, "", "", int(Time.get_unix_time_from_system()), _mood_rng)
	if not first.is_empty():
		_log_first(first)
	else:
		_react(ev, 0.35 if ev == "petted" else 0.7)
	_refresh()


## Si le gusta una comida: 1 si, 0 todavia no sabe, -1 no (para contar como le cayo).
func _food_liking(p: Pompon, id: String) -> int:
	var innate := int(PomponTastes.ensure(p)["innate_food"].get(id, 0))
	if PomponTastes.times_eaten(p, id) <= 1:
		return innate
	var hearts := PomponTastes.food_hearts(p, id)
	if hearts >= 3:
		return 1
	return -1 if innate < 0 and hearts < 2 else 0


## Una primera vez: al diario ya (si puede pensar) o en cuanto pueda; nunca se pierde.
func _log_first(entry: Dictionary) -> void:
	if _can_think():
		_log_thought(entry)
	else:
		GameState.pending_thoughts.append(entry)


func _on_pet_tapped() -> void:
	var p := GameState.pompon
	if p == null:
		return
	if _prehatch:  # esta por nacer: el toque lo ayuda a romper la cascara
		_tap_prehatch()
		return
	if _night and _night_state in ["sleep", "play"]:  # de noche en su camita: se despierta un poquito
		_night_tap()
		return
	if not p.hatched:  # el huevo no nace con toques: necesita su cuna
		Audio.play("pet")
		_speech.text = T.t("home.need_crib")
		_bubble.visible = true
		_speech_timer = 4.0
		return
	p.add_stat("amor", 1.0)
	Audio.play("pet")
	Audio.play(["voice_a", "voice_b", "voice_c"].pick_random(), randf_range(0.92, 1.15))
	_say(PomponSpeech.line(p, int(Time.get_unix_time_from_system())), 4.0)
	GameState.note_event("tapped")
	_react("petted", 0.12)


## Adoptar un Pompon: la bienvenida deja elegir especie y sexo, y la cigüeña trae el huevo.
func _on_hatch_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/welcome.tscn")


# ------------------------------------------------ elegir especie y poner nombre

const NAME_IDEAS := Pompon.NAME_IDEAS
const NAME_MAX := 12
const KID_NAMES_TIP := "kid_names"   # (partida vieja de un menor de 13: elegir nombres de la lista, una vez)
var _name_panel: PanelContainer
var _kid_layer: Control   # pregunta de edad / cartel de nombres / ProfileDialog de una partida vieja


func _needs_name() -> bool:
	var p := GameState.pompon
	return p != null and p.nickname == "" and p.stage_index(int(Time.get_unix_time_from_system())) > 0


## Cuando el huevo nace hay que ponerle nombre. `rename`: partida vieja de un menor de 13 que tiene que
## elegir un nombre de la lista. Menores de 13: sin teclado, se elige de una grilla (NamePicker).
func _show_name_dialog(rename := false) -> void:
	var p := GameState.pompon
	var kids := GameState.kids_mode()
	_name_panel = PanelContainer.new()
	_name_panel.set_anchors_preset(Control.PRESET_CENTER)
	_name_panel.offset_left = -310
	_name_panel.offset_right = 310
	_name_panel.offset_top = -590   # arriba, para que no lo tape el teclado del celular
	_name_panel.offset_bottom = -30
	if kids:   # sin teclado: centrado y del alto de la grilla
		_name_panel.offset_top = -300
		_name_panel.offset_bottom = 300
		_name_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_name_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_style_modal(_name_panel)
	add_child(_name_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_name_panel.add_child(box)
	var head := Label.new()
	head.text = T.t("home.rename_title") if rename else T.t("home.born_title")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 34)
	box.add_child(head)
	var preview := PomponView.new()
	preview.custom_minimum_size = Vector2(0, 200 if kids else 250)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.set_pompon(p, GameState.equipped)
	box.add_child(preview)
	if kids:
		_kid_name_grid(box, p)
		return
	var edit := LineEdit.new()
	edit.placeholder_text = T.t("home.name_placeholder")
	edit.max_length = NAME_MAX
	edit.text = NAME_IDEAS.pick_random()
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.custom_minimum_size = Vector2(0, 76)
	edit.add_theme_font_size_override("font_size", 34)
	edit.select_all_on_focus = true
	edit.add_theme_stylebox_override("normal", Hud.card(Color("fffdfb"), 38, Color("ffc2d9"), 4, 0))
	edit.add_theme_stylebox_override("focus", Hud.card(Color("fffdfb"), 38, Color("ff8fb8"), 5, 0))
	box.add_child(edit)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var random_button := Button.new()
	random_button.text = T.t("home.other_name")
	random_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	random_button.custom_minimum_size = Vector2(0, 76)
	Hud.style_soft(random_button, 28)
	random_button.pressed.connect(func(): edit.text = NAME_IDEAS.pick_random())
	row.add_child(random_button)
	var ok := Button.new()
	ok.text = T.t("common.ready")
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.custom_minimum_size = Vector2(0, 76)
	Hud.style_primary(ok, 34)
	var accept := func():
		var chosen_name := edit.text.strip_edges()
		if chosen_name == "":
			edit.placeholder_text = T.t("home.name_missing")
			return
		GameState.pompon.nickname = chosen_name
		GameState.save_game()
		Audio.play("success")
		pet.celebrate(8)
		_name_panel.queue_free()
		_name_panel = null
	ok.pressed.connect(accept)
	edit.text_submitted.connect(func(_t): accept.call())
	row.add_child(ok)


## Menores de 13: grilla de nombres para el Pompon y "¡Listo!" (sin teclado).
func _kid_name_grid(box: VBoxContainer, p: Pompon) -> void:
	var picker := NamePicker.new().setup(NAME_IDEAS, p.nickname)
	box.add_child(picker)
	var ok := Button.new()
	ok.text = T.t("common.ready")
	ok.custom_minimum_size = Vector2(0, 80)
	Hud.style_primary(ok, 34)
	ok.disabled = picker.chosen == ""
	picker.picked.connect(func(_n): ok.disabled = false)
	ok.pressed.connect(func():
		if picker.chosen == "":
			return
		GameState.rename_in_texts(GameState.pompon.nickname, picker.chosen)   # (si tenia un nombre viejo)
		GameState.pompon.nickname = picker.chosen
		GameState.save_game()
		Audio.play("success")
		pet.celebrate(8)
		_name_panel.queue_free()
		_name_panel = null)
	box.add_child(ok)


# ------------------------------------------------ edad y nombres de partidas viejas

## Partida de antes de preguntar la edad al empezar: se pregunta una vez al entrar a la casa.
func _needs_age() -> bool:
	return GameState.age_group == "" and GameState.has_profile()


## Menor de 13 con un nombre escrito a mano (de antes): una vez, un cartel corto para elegir de la lista.
func _needs_kid_names() -> bool:
	return GameState.kid_names_needed() and not GameState.tips_seen.has(KID_NAMES_TIP)


func _ask_age_once() -> void:
	_kid_layer = FriendSafety.ask_age(self, func(_g): _kid_layer = null)


func _show_kid_names_notice() -> void:
	GameState.tips_seen.append(KID_NAMES_TIP)
	GameState.save_game()
	var notice := BigNotice.new(640.0)
	_kid_layer = notice
	add_child(notice)
	notice.add(BigNotice.icon_strip([["lock", Color("a98bea")], ["heart", Color("ff7aa8")]]))
	notice.title(T.t("home.kid_names_title"), Color("7a56c4"))
	notice.text_line(T.t("home.kid_names_text"), 28)
	notice.button(T.t("home.kid_names_go"), func():
		notice.close()
		_kid_layer = null
		_kid_pick_player(), true, Color("5fc77f"))


## Primero el nombre del jugador (si no es de la lista), despues el del Pompon.
func _kid_pick_player() -> void:
	if GameState.is_kid_player_name(GameState.player_name):
		_kid_pick_pompon()
		return
	var old_name := GameState.player_name
	var dialog := ProfileDialog.new()
	_kid_layer = dialog
	add_child(dialog)
	dialog.setup(false)
	dialog.accepted.connect(func():
		GameState.rename_in_texts(old_name, GameState.player_name)
		GameState.save_game()
		dialog.queue_free()
		_kid_layer = null
		_kid_pick_pompon())


func _kid_pick_pompon() -> void:
	var p := GameState.pompon
	if p != null and p.nickname != "" and not GameState.is_kid_pompon_name(p.nickname):
		_show_name_dialog(true)


func _on_pompon_left(_message: String) -> void:
	pass  # la nota se muestra desde _check_news() (GameState.farewell)


# ------------------------------------------------------------------- estado

## Un boton late suavemente para indicar el siguiente paso (guia visual para ninos).
func _set_pulse(button: Button, want: bool) -> void:
	if button == null:
		return
	var tween: Tween = _pulses.get(button)
	if want and tween == null:
		button.pivot_offset = button.size * 0.5
		tween = create_tween().set_loops()
		tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.55).set_trans(Tween.TRANS_SINE)
		tween.tween_property(button, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
		_pulses[button] = tween
	elif not want and tween != null:
		tween.kill()
		_pulses.erase(button)
		button.scale = Vector2.ONE


## Primero "Trabajo" (hasta hacer el primer turno), despues "Tienda" cuando alcanza para la cuna.
func _update_pulses() -> void:
	var waiting := GameState.egg_waiting() and not _edit
	var affordable := waiting and not GameState.owns_crib() and GameState.coins >= _crib_price()
	_set_pulse(_shop_button, affordable)
	_set_pulse(_job_button, waiting and not affordable and GameState.jobs_done == 0)


func _refresh() -> void:
	_update_pulses()
	var p := GameState.pompon
	hatch_button.visible = p == null and not _edit
	$InfoPanel.visible = not _edit
	_edit_room_label.text = Rooms.room_name(GameState.current_room)
	for tb in _top_buttons:
		tb.visible = not _edit
	_coin_pill.visible = not _edit
	if _friends_dot != null:
		_friends_dot.visible = not GameState.friend_requests.is_empty()
	if _edit or _any_modal():
		_bubble.visible = false
	var born: bool = _is_born(p)
	_sex_badge.visible = p != null
	_level_badge.visible = born
	if born and _level_value != GameState.pompon_level():
		_level_value = GameState.pompon_level()
		_level_badge.queue_redraw()
	if p != null:
		_sex_kind = "female" if p.sex == "Hembra" else "male"
		if _avatar_sex != p.sex:
			_avatar_sex = p.sex
			_avatar_panel.add_theme_stylebox_override("panel", _avatar_style(p.sex))
		_sex_badge.queue_redraw()
	bars.visible = born and _expanded
	_mini_row.visible = born and not _expanded
	_toggle_button.visible = born
	_dock.visible = p != null and not _edit
	_dock.set_born(born)  # un huevo no come ni bebe: abajo solo queda la Tienda
	var rooms_sig := GameState.pompon_level() * 10 + GameState.current_room
	if rooms_sig != _rooms_sig:
		_rooms_sig = rooms_sig
		_sync_rooms()
	_coins_label.text = "%d" % GameState.coins
	var time_text := DayClock.time_text()
	if _clock_label.text != time_text:
		_clock_label.text = time_text
		_clock_icon.queue_redraw()
	var waiting_crib: bool = p != null and not _is_born(p) and not GameState.owns_crib()
	_crib_bar.visible = waiting_crib
	_crib_bar.value = float(mini(GameState.coins, _crib_price()))
	_crib_bar.max_value = float(_crib_price())
	_crib_bar.text = T.t("home.crib_bar", {"have": mini(GameState.coins, _crib_price()), "price": _crib_price()})
	var grow_now := int(Time.get_unix_time_from_system())
	var growing: bool = born and PomponGrowth.active(p, grow_now)
	_growth_bar.visible = growing
	_growth_hint.visible = growing
	if growing:
		var gq := PomponGrowth.quality(p, grow_now)
		_growth_bar.value = gq
		_growth_bar.tint = PomponGrowth.tier_color(PomponGrowth.pace(p, grow_now))
		_growth_bar.text = T.t("home.growth_bar", {"pct": int(gq)})
		_growth_bar.queue_redraw()
		var left := PomponGrowth.days_left(p, grow_now)
		var stage_i := p.stage_index(grow_now)
		_growth_hint.text = T.t("home.growth_hint", {"day": PomponGrowth.day_index(p, grow_now) + 1, "total": PomponGrowth.stage_days(stage_i),
			"stage": T.label(Pompon.STAGES[stage_i + 1]), "when": T.t("home.tomorrow") if left <= 1 else T.n("home.in_days", left)})

	room.set_state(GameState.equipped.get("wall", ""), GameState.equipped.get("floor", ""), GameState.placed, GameState.current_room)
	pet.set_pompon(p if p != null else _mystery_egg, _night_outfit() if _night else GameState.equipped)
	# la foto muestra al Pompon enterito dentro del circulo (cada etapa tiene otro tamaño)
	_avatar_view.head_zoom = PomponView.portrait_zoom(p, int(Time.get_unix_time_from_system())) if born else 0.0
	if born:
		_avatar_view.offset_left = 0.0
		_avatar_view.offset_top = 0.0
		_avatar_view.offset_right = 0.0
		_avatar_view.offset_bottom = 0.0
	else:  # el huevo se ve mas grande, asomando desde abajo
		_avatar_view.offset_left = -46.0
		_avatar_view.offset_top = -78.0
		_avatar_view.offset_right = 46.0
		_avatar_view.offset_bottom = 8.0
	_avatar_view.show_egg = p != null and not born   # por nacer: la foto sigue siendo el huevo
	_avatar_view.set_pompon(p if p != null else _mystery_egg, GameState.equipped)

	if p == null:
		title.text = T.t("home.no_pompon")
		details.text = T.t("home.no_pompon_hint")
		return
	if not _is_born(p):
		title.text = T.t("home.egg_of", {"species": Pompon.species_label(p.species).to_lower()})
		details.text = ""
		details.visible = false
		return
	var now := int(Time.get_unix_time_from_system())
	title.text = "%s  (%s)" % [p.display_name(), T.label(p.stage_name(now))]
	details.visible = true
	details.text = "%s · %s" % [Pompon.species_label(p.species), Pompon.personality_label(p.personality)]
	if p.nickname != "":
		details.text += " · " + p.id  # el ID (para amigos) se muestra cuando ya tiene nombre
	for s in _bar_nodes:
		_bar_nodes[s].value = p.stats[s]
	for s in _mini_nodes:
		_mini_nodes[s].value = p.stats[s]


# ------------------------------------------------- la noche (22 a 8 h, hora del jugador)
# El Pompon se pone el pijama y se queda en su camita: la cuna (bebe y niño), la cama amplia (mas grandes,
# si esta en esta habitacion) o una mantita en el piso. Casi siempre duerme ("zzz"); a ratos juega en la
# cama o se levanta a tomar agua o comer, y vuelve. A las 8 se despierta y sigue como siempre.

const NIGHT_TIP := "night1"
const NIGHT_LINES := ["Zzz… ¡buenas noches!", "Mmm… cinco minutitos más", "*bosteza* Te quiero mucho", "Zzz… shh, estoy soñando"]


## ¿Toca dormir ahora? (un Pompon ya nacido, de noche y sin estar decorando)
func _wants_night() -> bool:
	var p := GameState.pompon
	return _is_born(p) and p.stage_index(int(Time.get_unix_time_from_system())) > 0 and DayClock.night_now() and not _edit


func _update_night(delta: float) -> void:
	var night := _wants_night()
	if night != _night:
		_night = night
		if night:
			_enter_night()
		else:
			_leave_night()
	if _night:
		_wake_t = maxf(_wake_t - delta, 0.0)


func _enter_night() -> void:
	_night_state = "to_bed"
	_moving = false
	var spot := _night_spot()
	_night_pos = spot["pos"]
	_night_props = spot["props"]
	if not _night_seen:   # al abrir el juego de noche ya esta dormido en su camita
		_pet_pos = _night_pos
		_night_state = "sleep"
		_night_t = randf_range(25.0, 45.0)
		_slept()
	_night_seen = true
	room.center_on(_night_pos.x)
	_follow_pause = 1.0


func _leave_night() -> void:
	_night_state = ""
	pet.sleeping = false
	pet.sleep_props = ""
	_wander_wait = 2.0
	if GameState.pompon != null and GameState.pompon.hatched:   # se desperto con la mañana
		pet.celebrate(4)
		_say("¡Buen día! Dormí riquísimo", 5.0)


## Donde duerme: {"pos": pies en el mundo, "props": "bed" o "mat"}.
func _night_spot() -> Dictionary:
	var p := GameState.pompon
	var small := p.stage_index(int(Time.get_unix_time_from_system())) <= 2
	var beds := []
	for pl in GameState.placed:
		if int(pl.get("room", 0)) == GameState.current_room:
			if (small and pl["id"] == "furn_crib") or (not small and Catalog.is_bed(pl["id"])):
				beds.append(pl)
	beds.sort_custom(func(a, b): return Catalog.is_special(a["id"]) and not Catalog.is_special(b["id"]))   # la cama de nube primero
	if not beds.is_empty():
		var bed: Dictionary = beds[0]
		var c: Vector2 = room._item_center(bed)
		var h: float = ItemArt.size_of(bed["id"]).y
		# en la cuna queda adentro; en las camas (mas chicas que un Pompon grande) la mantita las tapa
		return {"pos": Vector2(c.x, c.y + h * (0.2 if bed["id"] == "furn_crib" else 0.42)), "props": "bed"}
	var bounds := _floor_bounds()   # sin su cama en esta habitacion: una mantita en el piso
	var x := clampf(room.scroll + size.x * 0.5, bounds.position.x, bounds.end.x)
	return {"pos": Vector2(x, bounds.position.y + bounds.size.y * 0.6), "props": "mat"}


## Camina hasta `target`; true al llegar.
func _night_walk(target: Vector2, delta: float) -> bool:
	pet.sleep_props = ""
	pet.sleeping = false
	var to := target - _pet_pos
	var step := WALK_SPEED * delta
	if to.length() <= step:
		_pet_pos = target
		pet.walking = false
		return true
	_pet_pos += to.normalized() * step
	pet.facing = 1.0 if to.x >= 0.0 else -1.0
	pet.walking = true
	return false


## Lo que hace de noche, cuadro a cuadro (en lugar de pasear).
func _night_wander(delta: float) -> void:
	_night_t -= delta
	match _night_state:
		"to_bed", "back":
			if _night_walk(_night_pos, delta):
				_night_state = "sleep"
				_night_t = randf_range(25.0, 45.0)
				pet.facing = 1.0
				_slept()
		"sleep":
			pet.sleep_props = _night_props
			pet.sleeping = _wake_t <= 0.0
			if _night_t <= 0.0:
				if randf() < 0.7:   # juega un ratito en la cama
					_night_state = "play"
					_night_t = 5.0
					pet.sleeping = false
					pet.celebrate(0)
				else:   # se levanta a tomar agua o comer
					var bounds := _floor_bounds()
					var x := clampf(_night_pos.x + randf_range(-260.0, 260.0), bounds.position.x, bounds.end.x)
					_night_trip = Vector2(x, bounds.position.y + bounds.size.y * 0.5)
					_night_state = "trip"
		"play":
			pet.sleep_props = _night_props
			pet.sleeping = false
			if fmod(_night_t, 1.2) < delta:
				pet.celebrate(0)
			if _night_t <= 0.0:
				_night_state = "sleep"
				_night_t = randf_range(25.0, 45.0)
		"trip":
			if _night_walk(_night_trip, delta):
				pet.act("drink" if randf() < 0.6 else "eat")
				_night_state = "snack"
				_night_t = 3.4
		"snack":
			pet.walking = false
			if _night_t <= 0.0:
				_night_state = "back"


## Album de recuerdos (desde el diario).
func _show_album() -> void:
	if _album_panel != null or GameState.pompon == null:
		return
	_album_panel = AlbumPanel.new().setup(GameState.pompon)
	_album_panel.closed.connect(func():
		_album_panel.queue_free()
		_album_panel = null)
	add_child(_album_panel)


## Cada tanto mira si gano una figurita nueva y la festeja con un aviso.
func _update_album(delta: float) -> void:
	_album_check -= delta
	if _album_check > 0.0:
		return
	_album_check = 2.0
	var p := GameState.pompon
	if not _is_born(p) or _edit:
		return
	for s in PomponAlbum.new_ones(p, int(Time.get_unix_time_from_system())):
		_sticker_toast(s)
		break   # de a una: las demas en la proxima vuelta


func _sticker_toast(s: Dictionary) -> void:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", Hud.card(Color("fffaf0"), 30, Color("f2c94c"), 4, 10))
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(52, 52)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint: Color = s["color"]
	var kind: String = s["icon"]
	icon.draw.connect(func():
		icon.draw_circle(icon.size * 0.5, 26.0, tint)
		Hud.draw_icon(icon, kind, icon.size * 0.5, 34.0, Color.WHITE, tint.darkened(0.25)))
	row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	var t1 := Label.new()
	t1.text = "¡Figurita nueva!"
	t1.add_theme_font_size_override("font_size", 20)
	t1.add_theme_color_override("font_color", Color("b87400"))
	texts.add_child(t1)
	var t2 := Label.new()
	t2.text = s["title"]
	t2.add_theme_font_size_override("font_size", 26)
	t2.add_theme_color_override("font_color", Hud.INK)
	texts.add_child(t2)
	add_child(chip)
	chip.position = Vector2((size.x - chip.get_combined_minimum_size().x) * 0.5, -120.0)
	Audio.play("ding")
	var tw := chip.create_tween()
	tw.tween_property(chip, "position:y", 330.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)   # sobre el cuarto, sin tapar la tarjeta
	tw.tween_interval(2.6)
	tw.tween_property(chip, "modulate:a", 0.0, 0.4)
	tw.tween_callback(chip.queue_free)


## Se acosto a dormir: la primera noche en su camita queda en el diario (y en el album).
func _slept() -> void:
	_log_first(PomponFirsts.experience(GameState.pompon, "sleep", "", "", int(Time.get_unix_time_from_system()), _mood_rng))


## Tocarlo de noche: se despierta un poquito y vuelve a dormir.
func _night_tap() -> void:
	_wake_t = 3.5
	pet.sleeping = false
	GameState.pompon.add_stat("amor", 1.0)
	Audio.play("pet", 0.9)
	_say(NIGHT_LINES[randi() % NIGHT_LINES.size()], 3.5)


## Lo que se ve en el cuadro de actividad de noche.
func _night_activity_text() -> String:
	var n := GameState.pompon.display_name()
	match _night_state:
		"play":
			return "%s juega en su camita" % n
		"trip", "snack":
			return "%s se levantó a tomar algo" % n
		"to_bed", "back":
			return "%s va a su camita" % n
	return "%s duerme" % n if pet.sleeping else "%s está en su camita" % n


## La ropa de dormir (de noche): pijama, sin gorro ni lentes.
func _night_outfit() -> Dictionary:
	var eq: Dictionary = GameState.equipped.duplicate()
	eq.erase("hat")
	eq.erase("glasses")
	eq["shirt"] = "shirt_pajama"
	return eq


## Cartel de la primera noche: a esta hora a los Pompons les gusta dormir.
func _show_night_notice() -> void:
	GameState.tips_seen.append(NIGHT_TIP)
	GameState.save_game()
	var notice := BigNotice.new()
	_night_notice = notice
	add_child(notice)
	notice.add(BigNotice.icon_strip([["moon", Color("7b8ce0")], ["house", Color("a98bea")], ["heart", Color("ff7aa8")]]))
	notice.title("¡Ya es de noche!", Color("5d6fd8"))
	notice.text_line("De 22 a 8 h a los Pompons les gusta dormir y quedarse en su camita.", 28)
	notice.text_line("Puedes seguir cuidándolo y darle mimos.", 24, Color("a0527a"))
	notice.button("¡Buenas noches!", func():
		notice.close()
		_night_notice = null, true, Color("7b8ce0"))
