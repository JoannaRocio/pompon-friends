class_name HeartsRow
extends Control
## Fila de corazoncitos (llenos y vacios): cuanto le gusta algo al Pompon.

var value := 0
var max_value := 5
var heart := 26.0


func setup(v: int, heart_size := 26.0, max_hearts := 5) -> HeartsRow:
	value = v
	max_value = max_hearts
	heart = heart_size
	custom_minimum_size = Vector2(heart * max_value + 2.0 * (max_value - 1), heart)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return self


func _draw() -> void:
	for i in max_value:
		var c := Vector2(heart * 0.5 + i * (heart + 2.0), heart * 0.5)
		Hud.draw_icon(self, "heart", c, heart * 0.95, Color("ff6b8b") if i < value else Color("eadfe6"))
