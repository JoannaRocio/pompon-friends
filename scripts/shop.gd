extends Control
## Tienda diaria: 10 items que rotan cada 24 horas. Lo nuevo se desbloquea a medida que tu Pompon
## sube de nivel (un nivel por dia de vida; las etapas empiezan en los niveles 1, 8, 22 y 52).

const FILTERS := [
	{"key": "all", "label": "Todo", "cats": []},
	{"key": "wear", "label": "Ropa", "cats": ["hat", "glasses", "shirt"]},
	{"key": "furn", "label": "Muebles", "cats": ["furniture", "deco"]},
	{"key": "room", "label": "Cuarto", "cats": ["wall", "floor"]},
	{"key": "bowls", "label": "Tazones", "cats": ["bowl_food", "bowl_water"]},
	{"key": "special", "label": "Especial", "cats": []},   # caros y con brillo: siempre a la vista
]

var _coins_label: Label
var _timer_label: Label
var _list: VBoxContainer           # contenido que se desplaza
var _grid: GridContainer           # las tarjetas de hoy
var _locked_grid: GridContainer    # lo que falta desbloquear
var _locked_title: Label
var _more_label: Label            # Especial: "y 18 más adelante…" (no una pared de candados)
const SPECIAL_NEXT := 3           # cuantos especiales con candado se ven (los proximos a desbloquear)
var _level_badge: Control
var _level_title: Label
var _level_bar: StatBar
var _filter := "all"
var _locked := false      # primera compra: solo se puede comprar la cuna
var _crib_button: Button
var _arrow: GuideArrow


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("fff1de")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 20
	root.offset_right = -20
	root.offset_top = 20
	root.offset_bottom = -20
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	# arriba: volver, titulo y monedas
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	top.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/town.tscn" if Town.from_town else "res://scenes/home.tscn")))
	var title := Label.new()
	title.text = T.s("Tienda")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("7a56c4"))
	top.add_child(title)
	var coin_card := PanelContainer.new()
	coin_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 6))
	top.add_child(coin_card)
	var coin_row := HBoxContainer.new()
	coin_row.add_theme_constant_override("separation", 6)
	coin_row.add_child(Hud.coin_icon(34.0))
	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 30)
	_coins_label.add_theme_color_override("font_color", Color("b87400"))
	coin_row.add_child(_coins_label)
	coin_card.add_child(coin_row)

	# nivel del Pompon: lo que se desbloquea depende de el
	root.add_child(_level_card())

	# filtros
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	root.add_child(filters)
	var group := ButtonGroup.new()
	for f in FILTERS:
		var b := Button.new()
		b.text = T.s(f["label"])
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = f["key"] == _filter
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 62)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_stylebox_override("normal", Hud.pill(Color("fff1f6"), Color("ffc2d9"), 31, 3))
		b.add_theme_stylebox_override("hover", Hud.pill(Color("ffe4ee"), Color("ffb3d1"), 31, 3))
		b.add_theme_stylebox_override("pressed", Hud.pill(Color("ff8fb8"), Color.WHITE, 31, 0))
		b.add_theme_stylebox_override("hover_pressed", Hud.pill(Color("ff8fb8"), Color.WHITE, 31, 0))
		for state in ["font_color", "font_hover_color"]:
			b.add_theme_color_override(state, Hud.INK)
		for state in ["font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(state, Color.WHITE)
		var key: String = f["key"]
		b.pressed.connect(func():
			_filter = key
			_rebuild())
		filters.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 16)
	scroll.add_child(_list)
	_grid = _new_grid()
	_list.add_child(_grid)
	_locked_title = Label.new()
	_locked_title.text = T.s("Se desbloquea al subir de nivel")
	_locked_title.add_theme_font_size_override("font_size", 30)
	_locked_title.add_theme_color_override("font_color", Color("a0527a"))
	_locked_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(_locked_title)
	_locked_grid = _new_grid()
	_list.add_child(_locked_grid)
	_more_label = Label.new()
	_more_label.add_theme_font_size_override("font_size", 26)
	_more_label.add_theme_color_override("font_color", Color("a0527a"))
	_more_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_more_label.visible = false
	_list.add_child(_more_label)

	_arrow = GuideArrow.new()
	_arrow.ring = true   # arriba del boton de la cuna esta "¡Para que nazca!": un anillo no lo tapa
	add_child(_arrow)
	_rebuild()


func _new_grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 3
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	return g


## Tarjeta del nivel: numero en una estrella, etapa y cuanto falta para la proxima etapa.
func _level_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 36, Color.WHITE, 3, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	_level_badge = Control.new()
	_level_badge.custom_minimum_size = Vector2(92, 92)
	_level_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_level_badge.draw.connect(_draw_level_badge)
	row.add_child(_level_badge)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	_level_title = Label.new()
	_level_title.add_theme_font_size_override("font_size", 34)
	_level_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_level_title)
	# cuanto falta para la tienda nueva: relojito y la hora (sin "Nueva tienda en")
	var clock := Control.new()
	clock.custom_minimum_size = Vector2(30, 30)
	clock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clock.draw.connect(func(): Hud.draw_icon(clock, "clock", clock.size * 0.5, 30.0, Color("a0527a")))
	head.add_child(clock)
	_timer_label = Label.new()
	_timer_label.add_theme_font_size_override("font_size", 24)
	_timer_label.add_theme_color_override("font_color", Color("a0527a"))
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_timer_label)
	_level_bar = StatBar.new().setup("", "star", Color("ffcf3f"))
	_level_bar.custom_minimum_size = Vector2(0, 44)
	_level_bar.font_size = 19
	col.add_child(_level_bar)
	return card


func _draw_level_badge() -> void:
	var c := _level_badge.size * 0.5
	var pts := PackedVector2Array()
	for i in 20:
		var a := -PI / 2.0 + PI * i / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * (46.0 if i % 2 == 0 else 34.0))
	_level_badge.draw_colored_polygon(pts, Color("ffcf3f"))
	pts.append(pts[0])
	_level_badge.draw_polyline(pts, Color("b87400"), 4.0, true)
	var font := _level_badge.get_theme_default_font()
	var level := GameState.pompon_level()
	_level_badge.draw_string(font, c + Vector2(-46, 13), str(level), HORIZONTAL_ALIGNMENT_CENTER, 92, 38 if level < 100 else 28, Color("7a4a00"))


func _process(_delta: float) -> void:
	var left := Catalog.seconds_until_refresh(int(Time.get_unix_time_from_system()))
	_timer_label.text = "%d:%02d" % [left / 3600, (left % 3600) / 60]


func _update_level_card() -> void:
	var now := int(Time.get_unix_time_from_system())
	var p := GameState.pompon
	var level := GameState.pompon_level()
	_level_badge.queue_redraw()
	if p == null or not p.hatched:
		_level_title.text = T.label("Huevo")
		_level_bar.max_value = 1.0
		_level_bar.value = 0.0
		_level_bar.text = T.s("¡Compra la cuna!")
		return
	_level_title.text = T.label(p.stage_name(now))   # (el numero de nivel ya esta en la estrella)
	var next_level := p.next_stage_level(now)
	if next_level < 0:
		_level_bar.max_value = 1.0
		_level_bar.value = 1.0
		_level_bar.text = T.s("¡Ya creció del todo!")
		return
	var start: int = Pompon.STAGE_START_LEVEL[p.stage_index(now)]
	_level_bar.max_value = float(next_level - start)
	_level_bar.value = float(level - start)
	var days := next_level - level
	_level_bar.text = T.s("{stage} en {n} {d}", {"stage": T.label(Pompon.stage_name_for_level(next_level)), "n": days, "d": T.t("tut.day") if days == 1 else T.t("tut.days")})


func _rebuild() -> void:
	_coins_label.text = str(GameState.coins)
	_update_level_card()
	_locked = GameState.egg_waiting() and not GameState.owns_crib()
	_crib_button = null
	for g in [_grid, _locked_grid]:
		for c in g.get_children():
			c.queue_free()
	var species: String = GameState.pompon.species if GameState.has_pompon() else ""
	var level := GameState.pompon_level()
	# mientras el huevo espera su cuna, la cuna siempre va primera en la lista
	var must: Array = [GameState.CRIB_ID] if _locked else []
	_more_label.visible = false
	if _filter == "special":  # los especiales no rotan: los que ya se pueden comprar, del mas barato al mas caro
		var waiting: Array = []
		for item in Catalog.specials():
			if Catalog.is_unlocked(item["id"], level):
				_grid.add_child(_make_card(item))
			else:
				waiting.append(item)
		# con candado, solo los proximos 3 (motiva mas que 21 candados seguidos) y cuantos quedan
		waiting.sort_custom(func(a, b): return Catalog.unlock_level(a["id"]) < Catalog.unlock_level(b["id"]))
		for item in waiting.slice(0, SPECIAL_NEXT):
			_locked_grid.add_child(_make_locked_card(item))
		_locked_title.visible = not waiting.is_empty()
		_locked_grid.visible = _locked_title.visible
		var more := waiting.size() - SPECIAL_NEXT
		if more > 0:
			_more_label.text = T.s("Y %d más adelante…") % more
			_more_label.visible = true
		_arrow.set_target(null)
		return
	var cats := _filter_cats()
	for item in Catalog.daily_shop(int(Time.get_unix_time_from_system()), species, GameState.owned, must, level):
		if cats.is_empty() or item["category"] in cats:   # la cuna es un mueble: sale en Todo y en Muebles
			_grid.add_child(_make_card(item))
	# lo que todavia no se puede comprar
	var locked_items: Array = Catalog.locked_items(level, 40).filter(func(i): return cats.is_empty() or i["category"] in cats).slice(0, 6)
	_locked_title.visible = not locked_items.is_empty() and not _locked
	_locked_grid.visible = _locked_title.visible
	for item in locked_items:
		_locked_grid.add_child(_make_locked_card(item))
	# la flecha señala la cuna (solo la primera vez y si ya alcanzan las monedas)
	_arrow.set_target(_crib_button if _crib_button != null and not _crib_button.disabled else null)


func _filter_cats() -> Array:
	for f in FILTERS:
		if f["key"] == _filter:
			return f["cats"]
	return []


## Con la cuna comprada el huevo nace: se muestra un mensaje y se vuelve a casa a verlo.
func _celebrate_crib() -> void:
	_rebuild()
	_arrow.set_target(null)
	_timer_label.text = T.s("¡Cuna lista!")
	set_process(false)
	await get_tree().create_timer(1.8).timeout
	get_tree().change_scene_to_file("res://scenes/home.tscn")


## Una tarjeta de la tienda: dibujo grande, nombre, para quien es y el boton de precio.
func _make_card(item: Dictionary) -> Control:
	var owned := GameState.owned.has(item["id"])
	var needed := false
	var p := GameState.pompon
	if item.has("species") and p != null and p.species == item["species"]:
		needed = true
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.96), 28, Color("ff8fb8") if needed else Color.WHITE, 5 if needed else 3, 6))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var holder := CenterContainer.new()
	box.add_child(holder)
	var icon := ItemIcon.new()
	icon.set_item(item["id"], 112.0)
	holder.add_child(icon)

	var name_label := Label.new()
	name_label.text = Catalog.item_name(item["id"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(0, 54)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_constant_override("line_spacing", -4)
	box.add_child(name_label)

	# menos texto: sin la etiqueta de categoria (las solapas ya separan Ropa, Muebles...). Solo la cuna
	# que espera el huevo lleva su cartelito.
	if item["id"] == GameState.CRIB_ID and GameState.egg_waiting():
		var tag := HBoxContainer.new()
		tag.alignment = BoxContainer.ALIGNMENT_CENTER
		tag.custom_minimum_size = Vector2(0, 30)
		box.add_child(tag)
		tag.add_child(Hud.chip(T.s("¡Para que nazca!"), Color("ffe6ef"), Color("d6336c"), 16))

	var buy := Button.new()
	buy.custom_minimum_size = Vector2(0, 60)
	buy.focus_mode = Control.FOCUS_NONE
	card.set_meta("buy", buy)
	card.set_meta("id", item["id"])
	var price_row := HBoxContainer.new()
	price_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.add_theme_constant_override("separation", 8)
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buy.add_child(price_row)
	var price_label := Label.new()
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_label.add_theme_font_size_override("font_size", 26)
	if owned:
		Hud.style_soft(buy, 22)
		buy.disabled = true
		var done := Control.new()
		done.custom_minimum_size = Vector2(28, 28)
		done.mouse_filter = Control.MOUSE_FILTER_IGNORE
		done.draw.connect(func(): Hud.draw_icon(done, "check", done.size * 0.5, 28.0, Color("2f9e6e")))
		price_row.add_child(done)
		price_label.text = T.s("Tuyo")
		price_label.add_theme_color_override("font_color", Color("2f9e6e"))
	else:
		var affordable: bool = GameState.coins >= item["price"]
		Hud.style_primary(buy, 26, Color("5fc77f"))
		buy.disabled = not affordable
		price_row.add_child(Hud.coin_icon(28.0))
		price_label.text = str(item["price"])
		if affordable:
			price_label.add_theme_color_override("font_color", Color.WHITE)
			price_label.add_theme_color_override("font_outline_color", Color("2f7a4d"))
			price_label.add_theme_constant_override("outline_size", 8)
		else:  # no alcanza: precio en gris y cuanto falta (no parece un boton para tocar)
			buy.add_theme_stylebox_override("disabled", Hud.pill(Color("f3e8ee"), Color("e6d3dc"), 36, 0))
			price_label.add_theme_color_override("font_color", Hud.MUTED)   # apagado pero se lee
			var missing := Label.new()
			missing.text = T.s("Te faltan %d") % (int(item["price"]) - GameState.coins)
			missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			missing.add_theme_font_size_override("font_size", 20)
			missing.add_theme_color_override("font_color", Color("e0295f"))
			missing.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.set_meta("missing", missing)
		buy.pressed.connect(func():
			if GameState.buy(item["id"]):
				if item["id"] == GameState.CRIB_ID and GameState.pompon != null:
					_celebrate_crib()
				else:
					var cat: String = item["category"]
					if cat in ["wall", "floor"] and GameState.equipped.get(cat, "") != item["id"]:
						GameState.equip(item["id"])   # la pared o el piso nuevo se ve enseguida en esta habitacion
					_rebuild()
					_bought_toast(item["id"]))
	price_row.add_child(price_label)
	box.add_child(buy)
	if card.has_meta("missing") and (not _locked or item["id"] == GameState.CRIB_ID):
		box.add_child(card.get_meta("missing"))   # (con la tienda bloqueada por la cuna, solo en la cuna)

	if _locked:  # la primera vez solo se puede comprar la cuna: lo demas espera
		if item["id"] == GameState.CRIB_ID:
			_crib_button = buy
			buy.pivot_offset = Vector2(96, 30)
			var pulse := buy.create_tween().set_loops()
			pulse.tween_property(buy, "scale", Vector2(1.06, 1.06), 0.6).set_trans(Tween.TRANS_SINE)
			pulse.tween_property(buy, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
		else:
			buy.disabled = true
			card.modulate = Color(1, 1, 1, 0.7)   # (apagada pero se lee: es lo que vas a poder comprar despues)
			price_label.add_theme_color_override("font_color", Hud.MUTED)   # (el blanco no se ve sobre el boton apagado)
			price_label.add_theme_constant_override("outline_size", 0)
	return card


## Cartelito despues de comprar: donde quedo lo que se compro (o donde se usa).
func _bought_toast(id: String) -> void:
	var cat: String = Catalog.get_item(id).get("category", "")
	var place := Rooms.place_name(GameState.current_room)
	var text := ""
	if Catalog.is_placeable(id):
		text = T.s("¡Ya está {place}!", {"place": place}) + "\n" + T.s("Muévelo con Decorar")
	elif cat in ["wall", "floor"]:
		text = T.s("¡Ya se ve {place}!", {"place": place})
	elif cat in Catalog.WEARABLE:
		text = T.s("Póntelo en el Vestidor")
	if text == "":
		return
	var toast := PanelContainer.new()
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast.offset_bottom = -40
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_stylebox_override("panel", Hud.card(Color("fffafc"), 30, Color("ffb3d1"), 5, 14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_child(row)
	var icon := ItemIcon.new()
	icon.set_item(id, 72.0)
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("a0527a"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	add_child(toast)
	toast.modulate.a = 0.0
	var tw := toast.create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.2)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(toast.queue_free)


## Tarjeta con candado: se desbloquea cuando el Pompon llega a ese nivel.
func _make_locked_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Hud.card(Color(0.96, 0.93, 0.95, 0.9), 28, Color("e6d3dc"), 3, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)
	var holder := CenterContainer.new()
	box.add_child(holder)
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(110, 110)
	holder.add_child(stack)
	var icon := ItemIcon.new()
	icon.set_item(item["id"], 110.0)
	icon.modulate = Color(0.35, 0.3, 0.4, 0.55)
	stack.add_child(icon)
	var lock := Control.new()
	lock.set_anchors_preset(Control.PRESET_FULL_RECT)
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.draw.connect(func():
		var c := Vector2(55, 55)
		lock.draw_circle(c, 28.0, Color.WHITE)
		lock.draw_circle(c, 24.0, Color("a98bea"))
		Hud.draw_icon(lock, "lock", c, 34.0, Color.WHITE, Color("a98bea").darkened(0.3)))
	stack.add_child(lock)
	var lvl: int = Catalog.unlock_level(item["id"])
	var name_label := Label.new()
	name_label.text = Catalog.item_name(item["id"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(0, 54)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.add_theme_constant_override("line_spacing", -4)
	name_label.add_theme_color_override("font_color", Hud.MUTED)
	box.add_child(name_label)
	var tag := HBoxContainer.new()
	tag.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(tag)
	tag.add_child(Hud.chip(T.s("Nivel %d") % lvl, Color("ece6f7"), Color("6b4ba6"), 18))
	var stage := Label.new()
	stage.text = T.label(Pompon.stage_name_for_level(lvl))
	stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_theme_font_size_override("font_size", 20)
	stage.add_theme_color_override("font_color", Hud.MUTED)
	box.add_child(stage)
	return card
