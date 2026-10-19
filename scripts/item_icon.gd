class_name ItemIcon
extends Control
## Miniatura de un item del catalogo: ropa puesta en un Pompon, muebles dibujados,
## y muestras de pared o piso. La usan la tienda, el vestidor y la bandeja de decorar.

const ICON_SIZE := 88.0

var item_id := ""
var _view: PomponView


func set_item(id: String, px := ICON_SIZE) -> void:
	item_id = id
	custom_minimum_size = Vector2(px, px)
	size = Vector2(px, px)
	clip_contents = true
	if _view != null:
		_view.queue_free()
		_view = null
	var cat: String = Catalog.get_item(id).get("category", "")
	if cat in Catalog.WEARABLE:
		_view = PomponView.new()
		_view.animated = false
		_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_view.set_anchors_preset(Control.PRESET_FULL_RECT)
		_view.item_only_id = id  # solo la prenda, sin el Pompon
		_view.set_pompon(PomponView.make_sample("Felino", Color("ffb3cc"), Color("fff0f5")), {})
		add_child(_view)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("fff8ea")
	sb.border_color = Color("e3c9a6")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	if item_id == "":
		return
	var cat: String = Catalog.get_item(item_id).get("category", "")
	var inner := Rect2(8, 8, size.x - 16, size.y - 16)
	match cat:
		"wall":
			ItemArt.draw_wall(self, inner, item_id, 0.2)
			draw_rect(inner, ItemArt.OUTLINE, false, 2.0)
		"floor":
			ItemArt.draw_floor(self, inner, item_id, 0.2)
			draw_rect(inner, ItemArt.OUTLINE, false, 2.0)
		"bowl_food", "bowl_water":
			var s2 := minf(inner.size.x / 160.0, inner.size.y / 100.0)
			draw_set_transform_matrix(Transform2D(0.0, Vector2(s2, s2), 0.0, size * 0.5 + Vector2(0, -13.0 * s2)))
			BowlArt.draw_bowl(self, item_id, cat == "bowl_food", 0.2, 0.0)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"furniture", "deco":
			var item_size := ItemArt.size_of(item_id)
			var s := minf(inner.size.x / item_size.x, inner.size.y / item_size.y)
			draw_set_transform_matrix(Transform2D(0.0, Vector2(s, s), 0.0, size * 0.5))
			ItemArt.draw_item(self, item_id, Vector2.ZERO)
			draw_set_transform_matrix(Transform2D.IDENTITY)
	if Catalog.is_special(item_id):  # especial: brillitos (quietos en la miniatura)
		ItemArt.draw_shine(self, Rect2(Vector2(6, 6), size - Vector2(12, 12)), 0.35)
