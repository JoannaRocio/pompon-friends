extends SceneTree
## Herramienta de desarrollo: genera el icono chiquito de las notificaciones de Android (silueta blanca
## de la cabeza de un Pompon sobre fondo transparente, como pide Android) en los cinco tamaños, donde
## lo busca el plugin de notificaciones: res://assets/NotificationSchedulerPlugin/android/drawable-*/
## Uso: godot --headless --path . --script tools/make_notification_icon.gd

const SIZES := {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}
const NAME := "ic_default_notification"


## ¿El punto (en una caja de 0 a 1) cae dentro de la silueta? Cara redonda con dos orejitas.
static func inside(p: Vector2) -> bool:
	if p.distance_to(Vector2(0.5, 0.58)) <= 0.36:
		return true
	for ear in [[Vector2(0.16, 0.42), Vector2(0.2, 0.08), Vector2(0.44, 0.27)], [Vector2(0.84, 0.42), Vector2(0.8, 0.08), Vector2(0.56, 0.27)]]:
		if Geometry2D.point_is_inside_triangle(p, ear[0], ear[1], ear[2]):
			return true
	return false


## Los ojitos quedan transparentes (asi se reconoce la carita).
static func hole(p: Vector2) -> bool:
	return p.distance_to(Vector2(0.37, 0.56)) <= 0.055 or p.distance_to(Vector2(0.63, 0.56)) <= 0.055


func _initialize() -> void:
	for density in SIZES:
		var n: int = SIZES[density]
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var sub := 4   # suavizado: 4 x 4 muestras por pixel
		for y in n:
			for x in n:
				var hits := 0
				for sy in sub:
					for sx in sub:
						var p := Vector2((x + (sx + 0.5) / sub) / n, (y + (sy + 0.5) / sub) / n)
						if inside(p) and not hole(p):
							hits += 1
				img.set_pixel(x, y, Color(1, 1, 1, float(hits) / (sub * sub)))
		var dir := "res://assets/NotificationSchedulerPlugin/android/drawable-%s" % density
		DirAccess.make_dir_recursive_absolute(dir)
		print(density, " ", n, "px: ", img.save_png("%s/%s.png" % [dir, NAME]))
	quit()
