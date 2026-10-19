class_name Town
extends Control
## El pueblo: se sale por la puerta de la casa. Una calle que se desliza de costado con la casa de tu
## Pompon, la tienda, el cine, el supermercado, el museo y la casa de cada vecino (los del barrio y
## tus amigos de verdad). Tocar un edificio entra: tu casa, la tienda, el cine y las casas de los vecinos
## ya se pueden visitar; el supermercado y el museo abren pronto.

const INK := Color("5b3a4a")
const GAP := 26.0
const SIDE := 60.0          # margen al principio y al final de la calle
const PET_SIZE := 260.0
const GROUND_Y := 0.66      # donde apoyan los edificios (fraccion del alto de la pantalla)

static var from_town := false     # se entro a la tienda o a una visita desde el pueblo (al volver, vuelve aca)
static var last_scroll := -1.0    # donde se habia quedado mirando

var _scroll: ScrollContainer
var _street: Control
var _pet: PomponView
var _last_x := 0.0
var _walk_t := 0.0
var _toast: Control
var _notice: BigNotice
var buildings: Array = []   # [{"node", "kind", "entry"}]


func _ready() -> void:
	from_town = false
	var sky := ColorRect.new()
	sky.color = Color("cdeeff")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	_street = Control.new()
	_street.draw.connect(_draw_street)
	_scroll.add_child(_street)

	_pet = PomponView.new()
	_pet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pet.size = Vector2(PET_SIZE, PET_SIZE)
	add_child(_pet)
	if GameState.pompon != null and GameState.pompon.hatched:
		_pet.set_pompon(GameState.pompon, GameState.equipped)
	else:
		_pet.visible = false

	_build_top()
	_build()
	Friends.changed.connect(_build)
	resized.connect(_layout)
	_layout.call_deferred()


func _build_top() -> void:
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_right = -16
	top.offset_top = 16
	top.add_theme_constant_override("separation", 12)
	add_child(top)
	top.add_child(Hud.back_button(func(): get_tree().change_scene_to_file("res://scenes/home.tscn")))
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.94), 30, Color.WHITE, 3, 8))
	top.add_child(chip)
	var title := Label.new()
	title.text = "Pueblo Pompon"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("d6336c"))
	chip.add_child(title)


## Los edificios de la calle: primero tu casa, despues el centro y al final la calle de los vecinos.
func _build() -> void:
	for b in buildings:   # se sacan enseguida (si no, se superponen un cuadro con los nuevos)
		_street.remove_child(b["node"])
		b["node"].queue_free()
	buildings = []
	var p := GameState.pompon
	var home_name := "Mi casa" if p == null or p.nickname == "" else "Casa de %s" % p.display_name()
	_add("home", home_name, p.color_primary if p != null else Color("ffb3cc"), {})
	_add("shop", "Tienda", Color("ff7aa8"), {})
	_add("cinema", "Cine", Color("7b5ea7"), {})
	_add("market", "Supermercado", Color("5fc77f"), {}, true)
	_add("museum", "Museo", Color("c9a86a"), {}, true)
	for entry in Neighbors.all():
		var data := Neighbors.build(entry)
		var pom: Pompon = data["pompon"]
		var b := _add("house", "Casa de %s" % entry["name"], pom.color_primary, entry)
		b.friend = entry.get("real", false)
		var view := PomponView.new()   # el vecino espera en la puerta
		view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		view.size = Vector2(150, 150)
		view.set_pompon(pom, data["equipped"])
		b.add_child(view)
		b.set_meta("pet", view)
	_layout.call_deferred()


func _add(kind: String, sign_text: String, color: Color, entry: Dictionary, locked := false) -> TownBuilding:
	var b := TownBuilding.new().setup(kind, sign_text, color, locked)
	b.pressed.connect(_enter.bind(kind, entry, b))
	_street.add_child(b)
	buildings.append({"node": b, "kind": kind, "entry": entry})
	return b


func _layout() -> void:
	if size.y <= 0.0:
		return
	var ground := size.y * GROUND_Y
	var x := SIDE
	for b in buildings:   # uno al lado del otro, todos apoyados en la vereda
		var node: TownBuilding = b["node"]
		var bh := ground / TownBuilding.GROUND
		node.position = Vector2(x, ground - bh)
		node.size = Vector2(node.custom_minimum_size.x, bh)
		if node.has_meta("pet"):
			var v: PomponView = node.get_meta("pet")
			v.position = Vector2(node.size.x * 0.5 + 60.0, node.size.y * TownBuilding.GROUND - 150.0)
		x += node.size.x + GAP
	_street.custom_minimum_size = Vector2(maxf(x - GAP + SIDE, size.x), size.y)
	_street.queue_redraw()
	_pet.position = Vector2((size.x - PET_SIZE) * 0.5, ground + 70.0 - PET_SIZE)
	if last_scroll >= 0.0:
		_scroll.scroll_horizontal = int(last_scroll)
	_last_x = _scroll.scroll_horizontal


## Tu Pompon camina por la vereda mientras se desliza la calle.
func _process(delta: float) -> void:
	var x := float(_scroll.scroll_horizontal)
	if absf(x - _last_x) > 0.5:
		_pet.facing = 1.0 if x > _last_x else -1.0
		_walk_t = 0.25
	_walk_t = maxf(_walk_t - delta, 0.0)
	_pet.walking = _walk_t > 0.0
	_last_x = x
	last_scroll = x


func _draw_street() -> void:
	var w := _street.size.x
	var h := _street.size.y
	var ground := h * GROUND_Y
	# colinas y nubes
	for i in int(w / 260.0) + 2:
		var cx := i * 260.0 + 80.0
		_street.draw_circle(Vector2(cx, ground + 40.0), 190.0, Color("b8e6c4"))
	for i in int(w / 420.0) + 1:
		var c := Vector2(i * 420.0 + 150.0, h * 0.2 + (i % 2) * 50.0)
		for k in 3:
			_street.draw_circle(c + Vector2(k * 34.0 - 34.0, -12.0 if k == 1 else 0.0), 30.0, Color(1, 1, 1, 0.9))
	# pasto, vereda y calle
	_street.draw_rect(Rect2(0, ground, w, h - ground), Color("9fdc8e"))
	_street.draw_rect(Rect2(0, ground, w, 90.0), Color("f1e3cf"))
	_street.draw_line(Vector2(0, ground), Vector2(w, ground), INK, 4.0)
	_street.draw_line(Vector2(0, ground + 90.0), Vector2(w, ground + 90.0), Color(INK, 0.4), 3.0)
	var road := ground + 140.0
	_street.draw_rect(Rect2(0, road, w, 150.0), Color("8f8a99"))
	for i in int(w / 120.0) + 1:
		_street.draw_rect(Rect2(i * 120.0 + 20.0, road + 68.0, 60.0, 12.0), Color("fff3b0"))
	# arbolitos entre los edificios
	for b in buildings:
		var node: Control = b["node"]
		var tx := node.position.x - GAP * 0.5
		if tx > SIDE:
			_street.draw_rect(Rect2(tx - 5.0, ground - 40.0, 10.0, 40.0), Color("b07a52"))
			_street.draw_circle(Vector2(tx, ground - 52.0), 22.0, Color("5fc77f"))


## Tocar un edificio.
func _enter(kind: String, entry: Dictionary, node: TownBuilding) -> void:
	if _notice != null:
		return
	match kind:
		"home":
			get_tree().change_scene_to_file("res://scenes/home.tscn")
		"shop":
			from_town = true
			get_tree().change_scene_to_file("res://scenes/shop.tscn")
		"cinema":
			get_tree().change_scene_to_file("res://scenes/cinema.tscn")
		"house":
			if entry.get("real", false):
				_friend_menu(entry)
			else:
				_visit(entry)
		_:
			Audio.play("fail")
			_show_toast("¡El %s abre muy pronto!" % node.title if kind != "market" else "¡El supermercado abre muy pronto!")


func _visit(entry: Dictionary) -> void:
	if GameState.pompon == null or not GameState.pompon.hatched:
		_show_toast("Primero tiene que nacer tu Pompon.")
		return
	Neighbors.current = entry["id"]
	from_town = true
	get_tree().change_scene_to_file("res://scenes/visit.tscn")


## Casa de un amigo de verdad: visitarlo o dejar de ser amigos.
func _friend_menu(entry: Dictionary) -> void:
	_notice = BigNotice.new(600.0)
	add_child(_notice)
	_notice.closed.connect(func(): _notice = null)
	_notice.title("Casa de %s" % entry["name"], Color("d6336c"))
	_notice.button("Visitar", func():
		_notice.close()
		_visit(entry), true, Color("5fc77f"))
	_notice.button("Más opciones", func():
		_notice.close()
		FriendSafety.friend_options(self, entry), false)
	_notice.button("Cerrar", _notice.close, false)


func _ask_remove(entry: Dictionary) -> void:
	_notice = BigNotice.new(600.0)
	add_child(_notice)
	_notice.closed.connect(func(): _notice = null)
	_notice.title("¿Dejar de ser amigos?", Color("d6336c"))
	_notice.text_line("%s ya no va a aparecer en tu pueblo." % entry["name"], 28)
	var code: String = entry["code"]
	_notice.button("No, seguir siendo amigos", _notice.close, true, Color("5fc77f"))
	_notice.button("Dejar de ser amigos", func():
		_notice.close()
		Friends.remove(code), false)


func _show_toast(text: String) -> void:
	if _toast != null and is_instance_valid(_toast):
		_toast.queue_free()
	var chip := Hud.chip(text, Color("fff3d1"), Color("8a6d00"), 28)
	chip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	chip.offset_top = 130
	chip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(chip)
	_toast = chip
	var tw := chip.create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(chip, "modulate:a", 0.0, 0.5)
	tw.tween_callback(chip.queue_free)
