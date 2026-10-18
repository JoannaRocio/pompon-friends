extends SceneTree
## Herramienta de desarrollo: guarda una imagen con las 7 especies para revisar el arte.
## Uso: godot --path . --script tools/screenshot_species.gd -- <salida.png> [bare]
## "bare" las muestra sin ropa.

const SPECIES := ["Conejo", "Canino", "Dragon", "Felino", "Ave", "Raton", "Reptil"]
const COLORS := [
	[Color("a8d8f0"), Color("f4f9ff")], [Color("e8c08c"), Color("fff0d8")], [Color("9ad9a8"), Color("e8f8d8")],
	[Color("ffb3cc"), Color("fff0f5")], [Color("ffe27a"), Color("fff6cf")], [Color("c9c2d6"), Color("f2eef8")],
	[Color("8fd1b0"), Color("d8f3e0")],
]
const EYES := ["redondos", "ovalados", "brillantes", "tiernos", "redondos", "ovalados", "brillantes"]
const MOUTHS := ["sonrisa", "colmillitos", "sonrisa", "bigotes", "pico", "sonrisa", "colmillitos"]
const FACES := ["redonda", "ovalada", "ancha", "redonda", "ancha", "ovalada", "redonda"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://species.png"
	var bare := args.size() > 1 and args[1] == "bare"
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1400, 800)
	var bg := ColorRect.new()
	bg.color = Color("fff4e0")
	bg.size = Vector2(1400, 800)
	root.add_child(bg)
	var wear := [
		{"hat": "hat_beanie", "shirt": "shirt_sweater"}, {"glasses": "glasses_round", "shirt": "shirt_red"},
		{"shirt": "shirt_hoodie", "hat": "hat_cap"}, {"hat": "hat_bow", "shirt": "shirt_dress"},
		{"hat": "hat_cap", "glasses": "glasses_sun"}, {"hat": "hat_crown", "glasses": "glasses_star"},
		{"shirt": "shirt_green", "hat": "hat_bow"},
	]
	for i in 7:
		var v := PomponView.new()
		v.size = Vector2(350, 400)
		v.position = Vector2((i % 4) * 350.0, (i / 4) * 400.0)
		var p := PomponView.make_sample(SPECIES[i], COLORS[i][0], COLORS[i][1], EYES[i], MOUTHS[i], FACES[i])
		v.set_pompon(p, {} if bare else wear[i])
		bg.add_child(v)
	# huevo y bebe en el ultimo hueco
	var egg := PomponView.new()
	egg.size = Vector2(350, 400)
	egg.position = Vector2(3 * 350.0, 400.0)
	var ep := PomponView.make_sample("Felino", Color("ffb3cc"), Color("fff0f5"))
	ep.born_at = int(Time.get_unix_time_from_system())
	egg.set_pompon(ep)
	bg.add_child(egg)
	await create_timer(0.5).timeout
	var img := root.get_viewport().get_texture().get_image()
	print("guardado: ", out, " -> ", img.save_png(out), " ", img.get_size())
	quit()
