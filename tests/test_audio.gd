extends SceneTree


func _initialize() -> void:
	await process_frame
	var a := root.get_node("Audio")
	var names := ["click", "coin", "success", "fail", "hatch", "eat", "drink", "bath", "pet",
		"voice_a", "voice_b", "voice_c", "simon0", "simon1", "simon2", "simon3"]
	var ok := true
	for n in names:
		var s = load("res://assets/audio/sfx_%s.wav" % n)
		if s == null or s.get_length() <= 0.0:
			ok = false
			print("FALTA/VACIO: ", n)
	print("16 efectos cargan: ", ok)
	for t in ["music_home", "music_play"]:
		var m = load("res://assets/audio/%s.ogg" % t)
		print(t, " duracion=", snappedf(m.get_length(), 0.1), "s")
	for n in names:
		a.play(n)
	print("play() sin errores; music_on=", a.music_on, " sfx_on=", a.sfx_on)
	a.play_music("home")
	await create_timer(2.5).timeout
	print("musica sonando: ", a._music.playing, " volumen=", snappedf(a._music.volume_db, 0.1), " loop=", a._music.stream.loop)
	a.play_music("play")
	await create_timer(3.5).timeout
	print("cambio a pista play: ", a._music.stream.resource_path.get_file(), " sonando=", a._music.playing)
	a.set_music_on(false)
	await create_timer(1.2).timeout
	print("musica apagada: sonando=", a._music.playing)
	a.set_music_on(true)
	var theme_ok: bool = root.theme != null and root.theme.has_stylebox("normal", "Button")
	print("tema cozy aplicado: ", theme_ok)
	var b := Button.new()
	root.add_child(b)
	await process_frame
	print("boton nuevo conectado al click: ", b.pressed.get_connections().size() > 0)
	quit()
