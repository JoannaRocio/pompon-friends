class_name AmbientFx
extends Control
## Motitas de luz que flotan despacio por el cuarto: lo hace sentir vivo y acogedor.

var _motes: Array = []
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in 16:
		_motes.append({
			"x": rng.randf(), "y": rng.randf(), "r": rng.randf_range(3.0, 8.0), "speed": rng.randf_range(0.010, 0.026),
			"phase": rng.randf() * TAU, "sway": rng.randf_range(10.0, 26.0),
		})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for m in _motes:
		var y: float = fposmod(float(m["y"]) - _t * float(m["speed"]), 1.0)
		var x: float = float(m["x"]) * size.x + sin(_t * 0.7 + float(m["phase"])) * float(m["sway"])
		var fade := sin(y * PI)
		var twinkle := 0.6 + 0.4 * sin(_t * 1.6 + float(m["phase"]))
		var p := Vector2(x, y * size.y * 0.78 + 80.0)
		draw_circle(p, float(m["r"]) * 2.2, Color(1.0, 0.95, 0.75, 0.07 * fade * twinkle))
		draw_circle(p, float(m["r"]), Color(1.0, 0.97, 0.85, 0.35 * fade * twinkle))
