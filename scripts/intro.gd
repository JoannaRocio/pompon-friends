extends Control
## Intro de Jojo Games a pantalla completa: el logo aparece con un salto, brilla y se despide
## con destellos. Se puede saltar tocando la pantalla. Es una animacion del motor (no un video),
## asi se ve nitida y llena cualquier pantalla vertical.

const NEXT_SCENE := "res://scenes/menu.tscn"
const LOGO := preload("res://assets/jojo_logo.png")
const SOUND := preload("res://assets/audio/jojo_logo.ogg")
const BG := Color("fffaf2")
const PALETTE := [Color("9376d4"), Color("cdd620"), Color("f05a35"), Color("ffb3c8")]
const LOGO_W := 620.0
const SHINE_SHADER := """
shader_type canvas_item;
uniform float shine = -1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = abs((UV.x + UV.y * 0.35) - shine);
	float band = smoothstep(0.1, 0.0, d);
	c.rgb = mix(c.rgb, vec3(1.0), band * 0.7 * c.a);
	COLOR = c;
}
"""

var _done := false
var _t := 0.0
var _logo: TextureRect
var _fx: Control
var _fade: ColorRect
var _mat: ShaderMaterial
var _sparks: Array = []
var _dots: Array = []


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.draw.connect(_draw_fx)
	add_child(_fx)

	var h := LOGO_W * float(LOGO.get_height()) / float(LOGO.get_width())
	_logo = TextureRect.new()
	_logo.texture = LOGO
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_SCALE
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_logo.set_anchors_preset(Control.PRESET_CENTER)
	_logo.offset_left = -LOGO_W * 0.5
	_logo.offset_right = LOGO_W * 0.5
	_logo.offset_top = -h * 0.5 - 40.0
	_logo.offset_bottom = h * 0.5 - 40.0
	_logo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_logo.grow_vertical = Control.GROW_DIRECTION_BOTH
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = SHINE_SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("shine", -1.0)
	_logo.material = _mat
	_logo.scale = Vector2.ZERO
	add_child(_logo)

	_fade = ColorRect.new()
	_fade.color = Color(BG, 0.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 14:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.9, 1.25)
		_sparks.append({
			"pos": Vector2(cos(a) * 360.0 * r, sin(a) * 175.0 * r - 40.0),
			"start": 0.75 + i * 0.11, "life": rng.randf_range(0.7, 1.0),
			"size": rng.randf_range(14.0, 30.0), "color": PALETTE[i % PALETTE.size()],
		})
	for i in 16:
		_dots.append({
			"pos": Vector2(rng.randf() * 720.0, rng.randf() * 1280.0), "r": rng.randf_range(10.0, 34.0),
			"speed": rng.randf_range(8.0, 22.0), "phase": rng.randf() * TAU, "color": PALETTE[i % PALETTE.size()],
		})

	if Audio.sfx_on:
		var player := AudioStreamPlayer.new()
		player.stream = SOUND
		add_child(player)
		player.play()
	_play.call_deferred()


func _play() -> void:
	_logo.pivot_offset = _logo.size * 0.5
	_logo.rotation = deg_to_rad(-8.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_logo, "scale", Vector2.ONE, 0.7).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_logo, "rotation", 0.0, 0.8).set_delay(0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var shine := create_tween()
	shine.tween_interval(1.0)
	shine.tween_method(func(v: float): _mat.set_shader_parameter("shine", v), -0.25, 1.5, 0.75)
	var out := create_tween()
	out.tween_interval(2.75)
	out.tween_property(_fade, "color:a", 1.0, 0.45)
	out.finished.connect(_go_next)


func _process(delta: float) -> void:
	_t += delta
	if _t > 0.9 and not _done:
		var breathe := 1.0 + 0.012 * sin((_t - 0.9) * 3.0)
		_logo.scale = Vector2(breathe, breathe)
	_fx.queue_redraw()


func _draw_fx() -> void:
	var center := Vector2(360.0, 640.0)
	for d in _dots:
		var y: float = fposmod(float(d["pos"].y) - _t * float(d["speed"]), 1380.0) - 50.0
		var x: float = float(d["pos"].x) + sin(_t * 0.8 + float(d["phase"])) * 14.0
		var c: Color = d["color"]
		_fx.draw_circle(Vector2(x, y), float(d["r"]), Color(c, 0.16))
	for s in _sparks:
		var k := (_t - float(s["start"])) / float(s["life"])
		if k < 0.0 or k > 1.0:
			continue
		var pulse := sin(k * PI)
		var r: float = float(s["size"]) * pulse
		if r < 2.0:
			continue
		var p: Vector2 = center + Vector2(s["pos"])
		var col: Color = s["color"]
		var pts := PackedVector2Array()
		for i in 8:
			var a := -PI / 2.0 + TAU * i / 8.0 + k * 0.8
			pts.append(p + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.3))
		_fx.draw_colored_polygon(pts, col)
		_fx.draw_polyline(pts + PackedVector2Array([pts[0]]), Color("2a2024", 0.85), 2.5, true)


func _input(event: InputEvent) -> void:
	# Permite saltar la intro tocando la pantalla.
	if event is InputEventScreenTouch and event.pressed:
		_go_next()
	elif event is InputEventMouseButton and event.pressed:
		_go_next()


func _go_next() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file(NEXT_SCENE)
