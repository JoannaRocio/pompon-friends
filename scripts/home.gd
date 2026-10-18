extends Control
## Casa: el cuarto, el Pompon (o su huevo), sus estadisticas y las acciones de cuidado.

const STAT_LABELS := {
	"alimentacion": "Comida", "hidratacion": "Agua", "aseo": "Aseo",
	"diversion": "Diversión", "comodidad": "Comodidad", "felicidad": "Felicidad",
	"amor": "Confianza", "amistad": "Social", "inteligencia": "Inteligencia",
}

# Acciones basicas: gratis y sin esperas.
const ACTIONS := {
	"Beber": {"stats": {"hidratacion": 40.0}, "sfx": "drink", "anim": "drink"},
	"Bañar": {"stats": {"aseo": 40.0}, "sfx": "bath", "anim": "bath"},
	"Caricia": {"stats": {"amor": 5.0, "felicidad": 3.0}, "sfx": "pet", "anim": "love"},
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
var _practice_timer := 100.0
var _practice_text := ""
var _practice_left := 0.0
var _thought_timer := 90.0
var _stat_check := 0.0
var _offline_checked := false
var _pill_left := 0.0
var _pet_pos := Vector2.ZERO       # donde pisa el Pompon en la habitacion (x en px del mundo, y pies)
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
	_mystery_egg = PomponView.make_sample("Felino", Color("f5d0a9"), Color("fff6e8"))
	_mystery_egg.born_at = int(Time.get_unix_time_from_system())
	_mystery_egg.hatched = false  # huevo
	GameState.pompon_left.connect(_on_pompon_left)
	hatch_button.text = "Adoptar Pompon"
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
	_place_tip()
	_update_mood(delta)
	_update_activity(delta)
	_update_thoughts(delta)
	_update_tastes(delta)
	_update_practice(delta)
	_update_growth(delta)
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
	_follow_pause = maxf(_follow_pause - delta, 0.0)
	if not grown or busy:
		pet.walking = false
		_moving = false
		if not grown or _prehatch:
			_pet_pos = _world_center()  # el huevo se queda en el centro
	elif _moving:
		var to := _wander_target - _pet_pos
		var step := WALK_SPEED * delta
		if to.length() <= step:
			_pet_pos = _wander_target
			_moving = false
			pet.walking = false
			_wander_wait = randf_range(2.0, 5.5)
		else:
			_pet_pos += to.normalized() * step
			var step_news := PomponSkills.add_walk_xp(p, step / PomponSkills.WALK_PIXELS_PER_XP)   # explorar entrena el fisico
			if not step_news.is_empty():
				GameState.pending_thoughts.append(step_news)
			pet.facing = 1.0 if to.x >= 0.0 else -1.0
			pet.walking = true
	else:
		_wander_wait -= delta
		if _wander_wait <= 0.0:
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


## Lleva la camara hasta el Pompon si esta fuera de la pantalla (por ejemplo al darle de comer).
func _focus_pet() -> void:
	var sx := _pet_pos.x - room.scroll
	if sx < size.x * 0.2 or sx > size.x * 0.8:
		room.center_on(_pet_pos.x)
		_follow_pause = 1.0


func _place_pet(bounds: Rect2) -> void:
	var depth := inverse_lerp(bounds.position.y, bounds.end.y, _pet_pos.y)
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
	_show_tip({"id": "", "text": "¡Algo se mueve!\nTócalo para ayudarlo a salir."})
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
	toc.text = "¡toc!" if tapped else "toc toc"
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
	return _gift_panel != null or _note_panel != null or _name_panel != null \
		or _food_panel != null or _hatch_layer != null or _journal_panel != null or _profile_panel != null


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


# Guias para la primera vez: de una en una y solo una vez. Primero la Tienda (el baul de
# Decorar esta vacio hasta que compres algo), y recien despues "Decorar".
const TIPS := [
	{"id": "egg1", "when": "egg", "text": "¡Tu huevo llegó!
Necesita una cuna para nacer.", "critical": true},
	{"id": "job1", "when": "egg", "text": "Una cuna cuesta {price} monedas.
¡Gánalas en Trabajo!", "critical": true},
	{"id": "shopcrib", "when": "crib_affordable", "text": "¡Ya alcanza!
Compra la cuna en la Tienda.", "critical": true},
	{"id": "growth", "when": "born", "text": "¡{name} está creciendo! Cuídalo estos {days} días: así aprende a hablar y confía en ti.", "critical": true},
	{"id": "care", "when": "born", "text": "Cuida a tu Pompon con los botones de abajo."},
	{"id": "pet", "when": "born", "text": "¡Tócalo para darle cariño!"},
	{"id": "decor", "when": "furniture", "text": "¡Muebles nuevos!
Toca Decorar para ponerlos."},
	{"id": "coins", "when": "born", "text": "¿Faltan monedas?
Ve a Trabajo."},
	{"id": "friends", "when": "born", "text": "Visita a tus Vecinos para hacer amigos."},
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
	label.text = str(tip["text"]).replace("\r", "").replace("{coins}", str(GameState.coins)).replace("{furniture}", furniture_name).replace("{price}", str(_crib_price())).replace("{name}", GameState.pompon.display_name()).replace("{days}", str(PomponGrowth.days_left(GameState.pompon, int(Time.get_unix_time_from_system()))))
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
	label.text = "¡Regalo del día!\n+%d monedas" % amount
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color("d6336c"))
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(label)
	var ok := Button.new()
	ok.text = "¡Gracias!"
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
	ok.text = "Adoptar otro Pompon"
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
	later.text = "Más tarde"
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
		bar.text = STAT_LABELS[stat]
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
	for s in ["alimentacion", "hidratacion", "aseo", "diversion"]:
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
	_coin_pill.offset_left = -176
	_coin_pill.offset_right = -16
	_coin_pill.offset_top = 22
	_coin_pill.offset_bottom = 82
	_coin_pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_coin_pill.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.93), 30, Color.WHITE, 3, 6))
	add_child(_coin_pill)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 10)
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_coin_pill.add_child(coin_row)
	var coin_icon := Control.new()
	coin_icon.custom_minimum_size = Vector2(44, 44)
	coin_icon.draw.connect(func(): Hud.draw_icon(coin_icon, "coin", coin_icon.size * 0.5, 44.0, Color.WHITE))
	coin_row.add_child(coin_icon)
	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 32)
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
	var t := Time.get_time_dict_from_system()
	return {"now": int(Time.get_unix_time_from_system()), "hour": float(t["hour"]) + float(t["minute"]) / 60.0,
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


## De vez en cuando practica con un objeto de su cuarto que entrena una habilidad (piano, rueda, escritorio...).
func _update_practice(delta: float) -> void:
	_practice_left = maxf(_practice_left - delta, 0.0)
	var p := GameState.pompon
	if not _is_born(p) or _edit or _any_modal() or pet.walking:
		return
	_practice_timer -= delta
	if _practice_timer > 0.0:
		return
	_practice_timer = randf_range(90.0, 150.0)
	var items: Array = PomponSkills.trainers(_thought_ctx()["items"])
	if items.is_empty():
		return
	var id: String = items[_mood_rng.randi() % items.size()]
	var news := PomponSkills.add_xp(p, PomponSkills.item_skill(id), PomponSkills.PRACTICE_XP)
	if not news.is_empty():
		GameState.pending_thoughts.append(news)
	_practice_text = "%s %s" % [p.display_name(), PomponSkills.practice_text(id)]
	_practice_left = 14.0
	_log_first(PomponFirsts.experience(p, "item", id, PomponThoughts._poss(id), int(Time.get_unix_time_from_system()), _mood_rng))


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
	if _practice_left > 0.0 and not pet.walking:  # practicando con un objeto de su cuarto
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
		_rebuild_tray()
	else:
		GameState.save_game()


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
	GameState.coins -= food["price"]
	var now := int(Time.get_unix_time_from_system())
	var taste := {}
	if food.has("id"):  # el Pompon aprende sus gustos: lo nuevo da desconfianza, lo conocido gusta mas
		taste = PomponTastes.eat(p, food["id"], now)
	p.add_stat("alimentacion", food["alimentacion"] * float(taste.get("mult", 1.0)))
	p.add_stat("felicidad", food["felicidad"] + float(taste.get("happy", 0.0)))
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
	if not p.hatched:  # el huevo no nace con toques: necesita su cuna
		Audio.play("pet")
		_speech.text = "¡Necesito una cuna para nacer!"
		_bubble.visible = true
		_speech_timer = 4.0
		return
	p.add_stat("amor", 1.0)
	p.add_stat("felicidad", 1.0)
	Audio.play("pet")
	Audio.play(["voice_a", "voice_b", "voice_c"].pick_random(), randf_range(0.92, 1.15))
	_say(PomponSpeech.line(p, int(Time.get_unix_time_from_system())), 4.0)
	GameState.note_event("tapped")
	_react("petted", 0.12)


## Adoptar un Pompon: la bienvenida deja elegir especie y sexo, y la cigüeña trae el huevo.
func _on_hatch_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/welcome.tscn")


# ------------------------------------------------ elegir especie y poner nombre

const NAME_IDEAS := ["Pompi", "Mochi", "Copito", "Bombón", "Canela", "Tofu", "Mimi", "Coco", "Kiwi", "Pelusa",
	"Lila", "Duki", "Chipa", "Muffin", "Pepita", "Ñoqui", "Nacho", "Dulce", "Bolita", "Galleta"]
const NAME_MAX := 12
var _name_panel: PanelContainer


func _needs_name() -> bool:
	var p := GameState.pompon
	return p != null and p.nickname == "" and p.stage_index(int(Time.get_unix_time_from_system())) > 0


## Cuando el huevo nace hay que ponerle nombre.
func _show_name_dialog() -> void:
	var p := GameState.pompon
	_name_panel = PanelContainer.new()
	_name_panel.set_anchors_preset(Control.PRESET_CENTER)
	_name_panel.offset_left = -310
	_name_panel.offset_right = 310
	_name_panel.offset_top = -590   # arriba, para que no lo tape el teclado del celular
	_name_panel.offset_bottom = -30
	_style_modal(_name_panel)
	add_child(_name_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_name_panel.add_child(box)
	var head := Label.new()
	head.text = "¡Tu Pompon nació!\n¿Cómo se va a llamar?"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 34)
	box.add_child(head)
	var preview := PomponView.new()
	preview.custom_minimum_size = Vector2(0, 250)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.set_pompon(p, GameState.equipped)
	box.add_child(preview)
	var edit := LineEdit.new()
	edit.placeholder_text = "Escribe un nombre"
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
	random_button.text = "Otro nombre"
	random_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	random_button.custom_minimum_size = Vector2(0, 76)
	Hud.style_soft(random_button, 28)
	random_button.pressed.connect(func(): edit.text = NAME_IDEAS.pick_random())
	row.add_child(random_button)
	var ok := Button.new()
	ok.text = "¡Listo!"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.custom_minimum_size = Vector2(0, 76)
	Hud.style_primary(ok, 34)
	var accept := func():
		var chosen_name := edit.text.strip_edges()
		if chosen_name == "":
			edit.placeholder_text = "¡Falta el nombre!"
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
	var waiting_crib: bool = p != null and not _is_born(p) and not GameState.owns_crib()
	_crib_bar.visible = waiting_crib
	_crib_bar.value = float(mini(GameState.coins, _crib_price()))
	_crib_bar.max_value = float(_crib_price())
	_crib_bar.text = "Cuna  %d / %d" % [mini(GameState.coins, _crib_price()), _crib_price()]
	var grow_now := int(Time.get_unix_time_from_system())
	var growing: bool = born and PomponGrowth.active(p, grow_now)
	_growth_bar.visible = growing
	_growth_hint.visible = growing
	if growing:
		var gq := PomponGrowth.quality(p, grow_now)
		_growth_bar.value = gq
		_growth_bar.tint = PomponGrowth.tier_color(PomponGrowth.pace(p, grow_now))
		_growth_bar.text = "Crecimiento  %d%%" % int(gq)
		_growth_bar.queue_redraw()
		var left := PomponGrowth.days_left(p, grow_now)
		var stage_i := p.stage_index(grow_now)
		_growth_hint.text = "Día %d de %d · Será %s %s" % [PomponGrowth.day_index(p, grow_now) + 1, PomponGrowth.stage_days(stage_i), Pompon.STAGES[stage_i + 1], "mañana" if left <= 1 else "en %d días" % left]

	room.set_state(GameState.equipped.get("wall", ""), GameState.equipped.get("floor", ""), GameState.placed, GameState.current_room)
	pet.set_pompon(p if p != null else _mystery_egg, GameState.equipped)
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
		title.text = "No tienes un Pompon"
		details.text = "Toca el botón para elegir a tu Pompon."
		return
	if not _is_born(p):
		title.text = "Tu huevo de %s" % Pompon.species_label(p.species).to_lower()
		details.text = ""
		details.visible = false
		return
	var now := int(Time.get_unix_time_from_system())
	title.text = "%s  (%s)" % [p.display_name(), p.stage_name(now)]
	details.visible = true
	details.text = "%s · %s" % [Pompon.species_label(p.species), Pompon.personality_label(p.personality)]
	if p.nickname != "":
		details.text += " · " + p.id  # el ID (para amigos) se muestra cuando ya tiene nombre
	if not Catalog.has_required_furniture(p.species, GameState.placed_ids()):
		details.text += "\nNecesita: %s (en la tienda)" % Catalog.required_furniture(p.species)["name"]
	for s in _bar_nodes:
		_bar_nodes[s].value = p.stats[s]
	for s in _mini_nodes:
		_mini_nodes[s].value = p.stats[s]
