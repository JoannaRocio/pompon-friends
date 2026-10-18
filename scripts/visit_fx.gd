class_name VisitFx
extends Control
## Efectos de la visita, dibujados por codigo encima de los Pompons: corazones, notas, gotitas de
## verguenza, puntitos "...", olfateo, chispas, la pelota, la caja de regalo y monedas que caen.

signal coin_arrived   # una moneda llego al contador

const LIFE := {"heart": 1.3, "note": 1.4, "sweat": 1.1, "dots": 1.6, "sniff": 0.7, "spark": 0.8, "plus": 1.4}

var ball_visible := false
var ball_pos := Vector2.ZERO
var gift_visible := false
var gift_pos := Vector2.ZERO
var gift_open := 0.0          # 0 cerrada, 1 tapa arriba
var _parts: Array = []        # {kind, p, v, age, life, size, text}
var _coins: Array = []        # {p, v, age, from, target, landed}
var _floor_y := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Agrega `n` particulas de un tipo cerca de `pos`.
func burst(kind: String, pos: Vector2, n := 1, spread := 30.0, text := "") -> void:
	for i in n:
		var p := pos + Vector2(randf_range(-spread, spread), randf_range(-spread * 0.5, spread * 0.5))
		var v := Vector2(randf_range(-12.0, 12.0), -55.0)
		match kind:
			"sweat":
				v = Vector2(randf_range(-10.0, 10.0), 40.0)
			"sniff":
				v = Vector2(randf_range(-40.0, 40.0), randf_range(-30.0, 10.0))
			"dots", "plus":
				v = Vector2(0, -18.0)
			"spark":
				v = Vector2(randf_range(-60.0, 60.0), randf_range(-80.0, -20.0))
		_parts.append({"kind": kind, "p": p, "v": v, "age": -i * 0.12, "life": LIFE.get(kind, 1.0),
			"size": randf_range(0.85, 1.15), "text": text})


## Monedas que saltan desde `from`, rebotan en el piso y vuelan hasta `target`.
func drop_coins(from: Vector2, target: Vector2, floor_y: float, n := 5) -> void:
	_floor_y = floor_y
	for i in n:
		_coins.append({"p": from, "v": Vector2(randf_range(-170.0, 170.0), randf_range(-420.0, -260.0)),
			"age": -i * 0.08, "from": Vector2.ZERO, "target": target, "landed": false})


func busy() -> bool:
	return not _parts.is_empty() or not _coins.is_empty()


func _process(delta: float) -> void:
	for p in _parts:
		p["age"] += delta
		if p["age"] > 0.0:
			p["p"] += p["v"] * delta
	_parts = _parts.filter(func(p): return p["age"] < p["life"])
	for c in _coins:
		c["age"] += delta
		if c["age"] < 0.0:
			continue
		if c["age"] < 1.1:  # salta y rebota en el piso
			var v: Vector2 = c["v"] + Vector2(0, 900.0 * delta)
			var p: Vector2 = c["p"] + v * delta
			if p.y > _floor_y and v.y > 0.0:
				p.y = _floor_y
				v = Vector2(v.x * 0.6, -v.y * 0.45)
			c["v"] = v
			c["p"] = p
			c["from"] = p
		else:  # vuela al contador
			var k := clampf((c["age"] - 1.1) / 0.45, 0.0, 1.0)
			c["p"] = Vector2(c["from"]).lerp(c["target"], k * k)
			if k >= 1.0 and not c["landed"]:
				c["landed"] = true
				coin_arrived.emit()
	_coins = _coins.filter(func(c): return not c["landed"])
	queue_redraw()


func _draw() -> void:
	if ball_visible:
		draw_circle(ball_pos + Vector2(0, 4), 24.0, Color(0, 0, 0, 0.12))
		draw_circle(ball_pos, 24.0, Color("ff8fb8"))
		draw_arc(ball_pos, 24.0, 0.0, TAU, 24, Hud.INK, 3.0, true)
		draw_arc(ball_pos, 14.0, -0.6, 1.2, 10, Color.WHITE, 5.0, true)
		draw_line(ball_pos + Vector2(-24, 0), ball_pos + Vector2(24, 0), Color("ffe27a"), 5.0)
	if gift_visible:
		_draw_gift()
	for p in _parts:
		if p["age"] < 0.0:
			continue
		var a := clampf(1.0 - p["age"] / p["life"], 0.0, 1.0)
		var s: float = p["size"]
		var pos: Vector2 = p["p"]
		match p["kind"]:
			"heart":
				Hud.draw_icon(self, "heart", pos, 34.0 * s, Color(1.0, 0.45, 0.6, a))
			"note":
				Hud.draw_icon(self, "note", pos + Vector2(sin(p["age"] * 7.0) * 8.0, 0), 34.0 * s, Color(0.55, 0.4, 0.9, a))
			"sweat":
				Hud.draw_icon(self, "drop", pos, 26.0 * s, Color(0.55, 0.8, 1.0, a), Color(1, 1, 1, a * 0.8))
			"dots":
				_draw_dots(pos, a)
			"sniff":
				draw_circle(pos, 7.0 * s * (0.6 + p["age"]), Color(1, 1, 1, a * 0.8))
				draw_arc(pos, 7.0 * s * (0.6 + p["age"]), 0.0, TAU, 12, Color(0.6, 0.5, 0.55, a * 0.5), 2.0, true)
			"spark":
				Hud.draw_icon(self, "star", pos, 30.0 * s, Color(1.0, 0.85, 0.3, a))
			"plus":
				var font := get_theme_default_font()
				draw_string_outline(font, pos + Vector2(-60, 0), p["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, 34, 10, Color(1, 1, 1, a))
				draw_string(font, pos + Vector2(-60, 0), p["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, 34, Color(0.95, 0.35, 0.5, a))
	for c in _coins:
		if c["age"] >= 0.0:
			Hud.draw_icon(self, "coin", c["p"], 40.0, Color.WHITE)


func _draw_dots(pos: Vector2, a: float) -> void:
	var r := Rect2(pos - Vector2(38, 20), Vector2(76, 40))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.95 * a)
	sb.border_color = Color(Hud.INK, 0.35 * a)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(20)
	draw_style_box(sb, r)
	for i in 3:
		draw_circle(pos + Vector2(-16 + i * 16, 0), 4.5, Color(Hud.INK, a))


func _draw_gift() -> void:
	var c := gift_pos
	var body := Rect2(c + Vector2(-34, -20), Vector2(68, 50))
	draw_rect(Rect2(body.position + Vector2(0, 54), Vector2(68, 6)), Color(0, 0, 0, 0.1))
	draw_rect(body, Color("ffb938"))
	draw_rect(body, Hud.INK, false, 3.0)
	draw_rect(Rect2(c + Vector2(-7, -20), Vector2(14, 50)), Color("ff7aa8"))
	# la tapa sube y se inclina al abrir
	var lift := gift_open * 46.0
	var lid_c := c + Vector2(gift_open * 18.0, -28.0 - lift)
	draw_set_transform(lid_c, gift_open * 0.5)
	draw_rect(Rect2(Vector2(-40, -10), Vector2(80, 18)), Color("ffc95c"))
	draw_rect(Rect2(Vector2(-40, -10), Vector2(80, 18)), Hud.INK, false, 3.0)
	draw_rect(Rect2(Vector2(-7, -10), Vector2(14, 18)), Color("ff7aa8"))
	Hud.draw_icon(self, "heart", Vector2(-12, -18), 22.0, Color("ff7aa8"))
	Hud.draw_icon(self, "heart", Vector2(12, -18), 22.0, Color("ff7aa8"))
	draw_set_transform(Vector2.ZERO)
	if gift_open > 0.3:  # brillo de adentro
		draw_circle(c + Vector2(0, -22), 22.0 * gift_open, Color(1, 0.95, 0.6, 0.5 * gift_open))
