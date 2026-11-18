class_name StatBar
extends Control
## Barra redondeada de una necesidad (comida, agua...) con su iconito. `value` va de 0 a 100.
## Si baja de 25 se pone roja y late un poquito para avisar. Con `text` muestra una etiqueta dentro.

var stat := ""
var kind := ""
var tint := Color("ffa94d")
var value := 100.0:
	set(v):
		value = v
		queue_redraw()
var max_value := 100.0
var text := ""
var font_size := 18
var warn_low := true   # en rojo y latiendo si baja de 25 (apagarlo en barras que no son necesidades)
var _t := 0.0


func setup(stat_name: String, icon_kind := "", color := Color.TRANSPARENT) -> StatBar:
	stat = stat_name
	kind = icon_kind if icon_kind != "" else Hud.STAT_ICONS.get(stat_name, "star")
	tint = color if color.a > 0.0 else Hud.STAT_COLORS.get(stat_name, Color("ffa94d"))
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if warn_low and value < 25.0 and max_value >= 100.0:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var h := size.y
	var r := h * 0.5
	var low := warn_low and value < 25.0 and max_value >= 100.0
	var col := Color("f2566f") if low else tint
	var x0 := r  # el circulo del icono ocupa el principio
	var track := Rect2(Vector2(x0, h * 0.18), Vector2(size.x - x0, h * 0.64))
	_pill(track, Color(0.93, 0.88, 0.9, 0.9), Color("e3d0d8"))
	var frac := clampf(value / maxf(max_value, 1.0), 0.0, 1.0)
	if frac > 0.0:
		var fw := maxf(track.size.y, (track.size.x - 4.0) * frac)
		_pill(Rect2(track.position + Vector2(2, 2), Vector2(minf(fw, track.size.x - 4.0), track.size.y - 4.0)), col, col.darkened(0.15))
	var pulse := 1.0 + (0.06 * sin(_t * 8.0) if low else 0.0)
	draw_circle(Vector2(r, r), r * pulse, Color.WHITE)
	draw_circle(Vector2(r, r), (r - 3.0) * pulse, col)
	Hud.draw_icon(self, kind, Vector2(r, r), h * 0.62, Color.WHITE, col.darkened(0.3))
	if text != "":
		var font := get_theme_default_font()
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := Vector2(size.x - tw - 14.0, h * 0.5 + font_size * 0.35)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(1, 1, 1, 0.85))   # se lee igual sobre la parte llena
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Hud.INK)


func _pill(rc: Rect2, fill: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(rc.size.y * 0.5))
	draw_style_box(sb, rc)
