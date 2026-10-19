class_name PlayFx
extends Control
## Dibujito que sube flotando y se desvanece mientras el Pompon juega con un objeto: notas
## musicales (piano), brillitos (cuadros, libros), corazones, burbujas (peces) o "z" (cama).

const COLORS := {"note": Color("a98bea"), "sparkle": Color("ffcf3f"), "heart": Color("ff7aa8"), "bubble": Color("7cc8ff"), "zzz": Color("7b8ce0")}

var kind := "sparkle"
var tint := Color.WHITE


## Lanza uno en `pos` (coordenadas de `parent`).
static func spawn(parent: Control, fx_kind: String, pos: Vector2) -> void:
	if fx_kind == "" or not COLORS.has(fx_kind):
		return
	var fx := PlayFx.new()
	fx.kind = fx_kind
	fx.tint = COLORS[fx_kind]
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.size = Vector2(44, 44)
	fx.position = pos - fx.size * 0.5
	fx.rotation = randf_range(-0.25, 0.25)
	fx.pivot_offset = fx.size * 0.5
	fx.scale = Vector2(0.4, 0.4)
	parent.add_child(fx)
	var drift := Vector2(randf_range(-50.0, 50.0), randf_range(-120.0, -90.0))
	var tw := fx.create_tween().set_parallel()
	tw.tween_property(fx, "position", fx.position + drift, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(fx, "modulate:a", 0.0, 0.6).set_delay(1.0)
	tw.chain().tween_callback(fx.queue_free)


func _draw() -> void:
	var c := size * 0.5
	var out := Color("5b3a4a")
	match kind:
		"note":  # corchea
			draw_circle(c + Vector2(-6, 10), 8.0, tint)
			draw_arc(c + Vector2(-6, 10), 8.0, 0.0, TAU, 16, out, 2.5, true)
			draw_line(c + Vector2(1.5, 10), c + Vector2(1.5, -16), out, 3.0, true)
			draw_line(c + Vector2(1.5, -16), c + Vector2(13, -8), out, 3.0, true)
		"sparkle":  # estrella de cuatro puntas
			var pts := PackedVector2Array()
			for i in 8:
				var a := -PI / 2.0 + PI * i / 4.0
				pts.append(c + Vector2(cos(a), sin(a)) * (18.0 if i % 2 == 0 else 6.0))
			draw_colored_polygon(pts, tint)
		"heart":
			Hud.draw_icon(self, "heart", c, 34.0, tint, Color(0, 0, 0, 0))
		"bubble":
			draw_arc(c, 12.0, 0.0, TAU, 20, tint, 3.0, true)
			draw_circle(c + Vector2(-4, -4), 3.0, Color(1, 1, 1, 0.9))
		"zzz":
			var font := get_theme_default_font()
			draw_string(font, c + Vector2(-12, 12), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, tint)
