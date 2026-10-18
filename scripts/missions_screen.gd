extends Control
## Misiones de hoy y Pase Pompon (gratis en beta). Cada mision es una tarjeta con su icono, una barra
## de avance y un boton: "Ir" lleva a donde se hace, el premio se toca para cobrarlo y la tilde indica
## que ya se cobro. El pase es un camino de premios que se abre con la XP de las misiones.

const BG := Color("e8f6ff")
const GOLD := Color("ffb938")
const GREEN := Color("5fc77f")
# icono, color y pantalla a la que lleva el boton "Ir" de cada mision
const LOOK := {
	"care": ["heart", Color("ff7aa8"), "home"],
	"minigame": ["game", Color("a98bea"), "minigames"],
	"buy": ["bag", Color("ffa94d"), "shop"],
	"job": ["case", Color("5bb8f5"), "job_board"],
	"visit": ["people", Color("5fc77f"), "neighbors"],
}
const NODE := 96.0   # diametro de cada premio del pase

var _coins_label: Label
var _timer_label: Label
var _missions_box: VBoxContainer
var _xp_bar: StatBar
var _track: Control
var _nodes: HBoxContainer


func _ready() -> void:
	var bg := Control.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.draw.connect(func():
		bg.draw_rect(Rect2(Vector2.ZERO, bg.size), BG)
		for s in [[Vector2(0.92, 0.05), 170.0, Color("fff1c9")], [Vector2(0.0, 0.4), 180.0, Color("ffe0ec")],
				[Vector2(1.0, 0.75), 200.0, Color("dcd0ff")], [Vector2(0.1, 1.0), 190.0, Color("d6f5e6")]]:
			bg.draw_circle(Vector2(s[0]) * bg.size, float(s[1]), Color(s[2], 0.6)))
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
	top.add_child(Hud.back_button(func(): _go("home")))
	var title := Label.new()
	title.text = "Misiones"
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

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	# misiones de hoy
	var head := HBoxContainer.new()
	list.add_child(head)
	head.add_child(_section_title("Hoy", "sun"))
	_timer_label = Label.new()
	_timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.add_theme_font_size_override("font_size", 20)
	_timer_label.add_theme_color_override("font_color", Color(Hud.INK, 0.6))
	head.add_child(_timer_label)
	_missions_box = VBoxContainer.new()
	_missions_box.add_theme_constant_override("separation", 12)
	list.add_child(_missions_box)

	# pase
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	list.add_child(spacer)
	list.add_child(_make_pass())

	_rebuild()


func _process(_delta: float) -> void:
	var left := 86400 - int(Time.get_unix_time_from_system()) % 86400
	_timer_label.text = "Nuevas en %02d:%02d:%02d" % [left / 3600, (left % 3600) / 60, left % 60]
	if GameState.missions_day != Missions.today(int(Time.get_unix_time_from_system())):
		_rebuild()  # cambio el dia con la pantalla abierta


func _go(scene_name: String) -> void:
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % scene_name)


## Titulo de seccion con un iconito en un circulo.
func _section_title(text: String, kind: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(46, 46)
	icon.draw.connect(func():
		var c := icon.size * 0.5
		icon.draw_circle(c, 23.0, GOLD)
		if kind == "sun":
			icon.draw_circle(c, 9.0, Color.WHITE)
			for i in 8:
				var a := TAU * i / 8.0
				icon.draw_line(c + Vector2(cos(a), sin(a)) * 13.0, c + Vector2(cos(a), sin(a)) * 18.0, Color.WHITE, 3.0, true)
		else:
			Hud.draw_icon(icon, kind, c, 32.0, Color.WHITE, GOLD))
	row.add_child(icon)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 36)
	l.add_theme_color_override("font_color", Color("7a56c4"))
	row.add_child(l)
	return row


# ------------------------------------------------------------------ misiones

func _rebuild() -> void:
	GameState._refresh_missions()
	_coins_label.text = str(GameState.coins)
	for c in _missions_box.get_children():
		c.queue_free()
	for m in Missions.DAILY:
		_missions_box.add_child(_mission_card(m))
	_update_pass()


func _mission_card(m: Dictionary) -> Control:
	var id: String = m["id"]
	var look: Array = LOOK.get(id, ["star", GOLD, "home"])
	var claimed: bool = GameState.missions_claimed.has(id)
	var done: bool = GameState.mission_done(id)
	var progress := mini(int(GameState.mission_progress.get(id, 0)), int(m["goal"]))

	var card := PanelContainer.new()
	var border := GREEN if done and not claimed else Color.WHITE
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.96), 32, border, 5 if done and not claimed else 3, 8))
	if claimed:
		card.modulate = Color(1, 1, 1, 0.6)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var icon := Control.new()
	icon.custom_minimum_size = Vector2(76, 76)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tint: Color = look[1]
	var kind: String = look[0]
	icon.draw.connect(func():
		var c := icon.size * 0.5
		icon.draw_circle(c, 38.0, tint)
		Hud.draw_icon(icon, kind, c, 46.0, Color.WHITE, tint))
	row.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)
	var text := Label.new()
	text.text = m["text"]
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(300, 0)
	text.add_theme_font_size_override("font_size", 24)
	text.add_theme_color_override("font_color", Hud.INK)
	col.add_child(text)
	var bar := StatBar.new().setup("", "check" if done else kind, GREEN if done else tint)
	bar.custom_minimum_size = Vector2(0, 38)
	bar.font_size = 19
	bar.max_value = float(m["goal"])
	bar.value = float(progress)
	bar.text = "%d / %d" % [progress, m["goal"]]
	col.add_child(bar)

	row.add_child(_mission_button(m, claimed, done, look[2]))
	return card


## Boton de la derecha: "Ir" (en curso), el premio para cobrar (lista) o una tilde (cobrada).
func _mission_button(m: Dictionary, claimed: bool, done: bool, target: String) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(124, 84)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 0)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(inner)
	if claimed:
		Hud.style_soft(b, 24)
		b.disabled = true
		var check := Control.new()
		check.custom_minimum_size = Vector2(0, 50)
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		check.draw.connect(func(): Hud.draw_icon(check, "check", check.size * 0.5, 46.0, Color("2f9e6e")))
		inner.add_child(check)
	elif done:
		Hud.style_primary(b, 28, GREEN)
		inner.add_child(_reward_row("+%d" % m["coins"], 30, Color.WHITE, Color("2f7a4d")))
		var xp := _small("+%d XP" % m["xp"], 17, Color.WHITE)
		xp.add_theme_color_override("font_outline_color", Color("2f7a4d"))
		xp.add_theme_constant_override("outline_size", 6)
		inner.add_child(xp)
		b.pivot_offset = b.custom_minimum_size * 0.5
		var pulse := b.create_tween().set_loops()
		pulse.tween_property(b, "scale", Vector2(1.06, 1.06), 0.55).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(b, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
		var id: String = m["id"]
		b.pressed.connect(func():
			if GameState.claim_mission(id):
				_float_reward(b, "+%d" % m["coins"])
				_rebuild())
	else:
		Hud.style_soft(b, 24)
		var go := Label.new()
		go.text = "Ir"
		go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		go.add_theme_font_size_override("font_size", 28)
		go.add_theme_color_override("font_color", Hud.INK)
		go.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(go)
		inner.add_child(_reward_row("+%d" % m["coins"], 19, Color("b87400"), Color(0, 0, 0, 0), 22.0))
		b.pressed.connect(func(): _go(target))
	return b


## Moneda + numero, centrados.
func _reward_row(text: String, font_size: int, color: Color, outline: Color, coin := 30.0) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if coin > 0.0:
		row.add_child(Hud.coin_icon(coin))
	var l := _small(text, font_size, color)
	if outline.a > 0.0:
		l.add_theme_color_override("font_outline_color", outline)
		l.add_theme_constant_override("outline_size", 8)
	row.add_child(l)
	return row


func _small(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## "+10" con moneda que sube y se desvanece desde el boton que se toco.
func _float_reward(from: Control, text: String, coin := true) -> void:
	var r := _reward_row(text, 38, Color("ffd34d"), Color("b87400"), 40.0 if coin else 0.0)
	r.top_level = true
	add_child(r)
	r.global_position = from.global_position + Vector2(from.size.x * 0.5 - 50.0, -10.0)
	var tw := r.create_tween().set_parallel()
	tw.tween_property(r, "global_position:y", r.global_position.y - 110.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.chain().tween_callback(r.queue_free)


# ------------------------------------------------------------------ pase

func _make_pass() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.96), 36, Color.WHITE, 3, 10))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	var t := _section_title("Pase Pompon", "star")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var free := Hud.chip("Gratis", Color("e3f7ea"), Color("2f9e6e"), 20)
	free.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(free)

	_xp_bar = StatBar.new().setup("", "star", GOLD)
	_xp_bar.custom_minimum_size = Vector2(0, 42)
	_xp_bar.font_size = 19
	_xp_bar.warn_low = false
	box.add_child(_xp_bar)

	# camino de premios: una linea que se llena y los premios encima
	_track = Control.new()
	_track.custom_minimum_size = Vector2(0, NODE + 50.0)
	_track.draw.connect(_draw_track)
	box.add_child(_track)
	_nodes = HBoxContainer.new()
	_nodes.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nodes.alignment = BoxContainer.ALIGNMENT_CENTER
	_nodes.add_theme_constant_override("separation", 0)
	_track.add_child(_nodes)
	_track.resized.connect(_track.queue_redraw)
	return card


func _update_pass() -> void:
	var total: int = Missions.PASS_TIERS.size() * Missions.PASS_XP_PER_TIER
	_xp_bar.max_value = float(total)
	_xp_bar.value = float(mini(GameState.pass_xp, total))
	_xp_bar.text = "%d / %d XP" % [mini(GameState.pass_xp, total), total]
	for c in _nodes.get_children():
		c.queue_free()
	for i in Missions.PASS_TIERS.size():
		_nodes.add_child(_tier_node(i))
	_track.queue_redraw()


func _draw_track() -> void:
	var n := Missions.PASS_TIERS.size()
	var slot := _track.size.x / n
	var y := NODE * 0.5
	var a := Vector2(slot * 0.5, y)
	var b := Vector2(_track.size.x - slot * 0.5, y)
	_track.draw_line(a, b, Color("eadff2"), 14.0, true)
	# se llena hasta el ultimo premio abierto y un poco hacia el siguiente
	var k := clampf(float(GameState.pass_xp) / Missions.PASS_XP_PER_TIER - 1.0, 0.0, n - 1.0)
	if k > 0.0:
		_track.draw_line(a, a.lerp(b, k / (n - 1.0)), GOLD, 14.0, true)


func _tier_node(i: int) -> Control:
	var tier: Dictionary = Missions.PASS_TIERS[i]
	var claimed: bool = GameState.pass_claimed.has(i)
	var open: bool = GameState.pass_tier_unlocked(i) and not claimed
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 6)

	var holder := CenterContainer.new()
	col.add_child(holder)
	var b := Button.new()
	b.custom_minimum_size = Vector2(NODE, NODE)
	b.focus_mode = Control.FOCUS_NONE
	var fill := Color("fff3d1") if open else (Color("e3f7ea") if claimed else Color("f3eef6"))
	var edge := GOLD if open else (GREEN if claimed else Color("ddd0e6"))
	var sb := Hud.card(fill, int(NODE * 0.5), edge, 5, 6 if open else 2)
	for state in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(state, sb)
	b.disabled = not open
	holder.add_child(b)

	# el premio dentro del circulo
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(center)
	if tier["item"] != "":
		var icon := ItemIcon.new()
		icon.set_item(tier["item"], 66.0)
		center.add_child(icon)
	else:
		center.add_child(Hud.coin_icon(54.0))
	if not open and not claimed:
		b.modulate = Color(1, 1, 1, 0.55)

	# insignia: candado (bloqueado) o tilde (cobrado)
	if claimed or not open:
		var badge := Control.new()
		badge.custom_minimum_size = Vector2(36, 36)
		badge.size = Vector2(36, 36)
		badge.position = Vector2(NODE - 34, -4)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tint := GREEN if claimed else Color("a98bea")
		badge.draw.connect(func():
			badge.draw_circle(Vector2(18, 18), 18.0, Color.WHITE)
			badge.draw_circle(Vector2(18, 18), 15.0, tint)
			Hud.draw_icon(badge, "check" if claimed else "lock", Vector2(18, 18), 22.0, Color.WHITE, tint))
		b.add_child(badge)
	if open:
		b.pivot_offset = Vector2(NODE, NODE) * 0.5
		var pulse := b.create_tween().set_loops()
		pulse.tween_property(b, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(b, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
		b.pressed.connect(func():
			if GameState.claim_pass_tier(i):
				if tier["item"] == "":
					_float_reward(b, "+%d" % tier["coins"])
				else:
					_float_reward(b, "¡Nuevo!", false)
				_rebuild())

	var label := _small("+%d" % tier["coins"] if tier["item"] == "" else Catalog.get_item(tier["item"]).get("name", ""), 18, Hud.INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(100, 0)
	col.add_child(label)
	return col
