extends MiniGameBase
## Minijuego "Hacer música": una grilla de 8 pasos con 5 notas (do, re, mi, sol, la: siempre suenan
## lindo juntas) y un tambor. Se tocan los cuadritos para prender notas y "Tocar" repite la cancion en
## ronda mientras tu Pompon baila. Las estrellas se ganan usando mas notas, mas alturas, el tambor y
## escuchandola entera. Entrena la Musica del Pompon. Los sonidos se arman por codigo (no hay archivos).

const STEPS := 8
const NOTES := [["la", 880.0, "a98bea"], ["sol", 783.99, "5bb8f5"], ["mi", 659.25, "5fc77f"],
	["re", 587.33, "ffb938"], ["do", 523.25, "ff7aa8"], ["tambor", 0.0, "8a7d90"]]
const STEP_SECONDS := 0.28
const CELL := 66.0

var grid: Array = []            # grid[fila][paso] = bool
var playing := false
var step_i := -1
var loops := 0                  # vueltas completas escuchadas
var _t := 0.0
var _cells: Array = []          # botones [fila][paso]
var _play_button: Button
var _sounds: Array = []         # AudioStreamWAV por fila
var _players: Array = []        # reproductores (varias notas a la vez)
var _next_player := 0
var _stars := {}                # logros ya ganados
var _notice: BigNotice


## Una nota (campanita suave) o el tambor, armada a mano.
static func tone(freq: float, drum := false, secs := 0.45) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * secs)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var t := float(i) / rate
		var v := 0.0
		if drum:
			v = sin(TAU * (90.0 - 40.0 * t) * t) * exp(-t * 14.0) * 0.9 + rng.randf_range(-1.0, 1.0) * exp(-t * 40.0) * 0.3
		else:
			var env := exp(-t * 5.5) * minf(1.0, t * 300.0)
			v = (sin(TAU * freq * t) * 0.55 + sin(TAU * freq * 2.0 * t) * 0.18 + sin(TAU * freq * 3.0 * t) * 0.06) * env
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


func _ready() -> void:
	game_id = "music"
	_build_chrome(Color("eef3ff"), 5, 2)
	content.offset_bottom = -300
	for r in NOTES.size():
		_sounds.append(tone(NOTES[r][1], NOTES[r][1] == 0.0))
		var row: Array = []
		row.resize(STEPS)
		row.fill(false)
		grid.append(row)
	for i in 6:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		_players.append(pl)

	content.add_child(_label("Toca los cuadritos y después ¡Tocar!", 30, Color("5b6fc4")))
	var board := PanelContainer.new()
	board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board.add_theme_stylebox_override("panel", Hud.card(Color(1, 1, 1, 0.95), 30, Color.WHITE, 3, 12))
	content.add_child(board)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	board.add_child(rows)
	for r in NOTES.size():
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		rows.add_child(line)
		var tag := Control.new()   # circulito de color con el nombre de la nota
		tag.custom_minimum_size = Vector2(56, CELL)
		var tint := Color(NOTES[r][2])
		var name_text: String = NOTES[r][0]
		tag.draw.connect(func():
			var c := tag.size * 0.5
			tag.draw_circle(c, 26.0, tint)
			var font := tag.get_theme_default_font()
			tag.draw_string(font, c + Vector2(-28, 7), name_text if name_text != "tambor" else "pum", HORIZONTAL_ALIGNMENT_CENTER, 56, 18, Color.WHITE))
		line.add_child(tag)
		var cells_row: Array = []
		for s in STEPS:
			var b := Button.new()
			b.custom_minimum_size = Vector2(CELL, CELL)
			b.focus_mode = Control.FOCUS_NONE
			b.set_meta("silent", true)
			b.pressed.connect(toggle.bind(r, s))
			line.add_child(b)
			cells_row.append(b)
		_cells.append(cells_row)
	_paint_cells()

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	content.add_child(buttons)
	_play_button = Button.new()
	_play_button.text = "Tocar"
	_play_button.custom_minimum_size = Vector2(190, 80)
	_play_button.focus_mode = Control.FOCUS_NONE
	Hud.style_primary(_play_button, 32, Color("5b6fc4"))
	_play_button.pressed.connect(func(): set_playing(not playing))
	buttons.add_child(_play_button)
	var clear := Button.new()
	clear.text = "Borrar"
	clear.custom_minimum_size = Vector2(150, 80)
	clear.focus_mode = Control.FOCUS_NONE
	Hud.style_soft(clear, 28)
	clear.pressed.connect(func():
		for row in grid:
			row.fill(false)
		_paint_cells())
	buttons.add_child(clear)
	var done := Button.new()
	done.text = "¡Listo!"
	done.custom_minimum_size = Vector2(170, 80)
	done.focus_mode = Control.FOCUS_NONE
	Hud.style_primary(done, 30, Color("5fc77f"))
	done.pressed.connect(_finish)
	buttons.add_child(done)


## Prende o apaga una nota (y suena, para escucharla).
func toggle(r: int, s: int) -> void:
	if _layer != null:
		return
	grid[r][s] = not grid[r][s]
	if grid[r][s]:
		_play_row(r)
	_paint_cells()
	_check_stars()


func _play_row(r: int) -> void:
	if not Audio.sfx_on:
		return
	var pl: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	pl.stream = _sounds[r]
	pl.volume_db = -4.0 if r < NOTES.size() - 1 else -2.0
	pl.play()


func _paint_cells() -> void:
	for r in _cells.size():
		var tint := Color(NOTES[r][2])
		for s in STEPS:
			var on: bool = grid[r][s]
			var sb := StyleBoxFlat.new()
			sb.bg_color = tint if on else tint.lerp(Color.WHITE, 0.82 if s % 4 != 0 else 0.74)
			sb.set_corner_radius_all(16)
			sb.border_color = Color("5b3a4a") if s == step_i and playing else (tint.darkened(0.2) if on else Color(0, 0, 0, 0))
			sb.set_border_width_all(5 if s == step_i and playing else (3 if on else 0))
			for st in ["normal", "hover", "pressed", "focus"]:
				_cells[r][s].add_theme_stylebox_override(st, sb)


func set_playing(on: bool) -> void:
	playing = on
	step_i = -1
	_t = 0.0
	_play_button.text = "Parar" if on else "Tocar"
	_paint_cells()


func _process(delta: float) -> void:
	if not playing:
		return
	_t -= delta
	if _t > 0.0:
		return
	_t += STEP_SECONDS
	step_i = (step_i + 1) % STEPS
	var any := false
	for r in NOTES.size():
		if grid[r][step_i]:
			_play_row(r)
			any = true
	if any and is_instance_valid(_pet):   # tu Pompon baila con la musica
		_pet.celebrate(0)
		_pet.lean = 0.08 if step_i % 2 == 0 else -0.08
	if step_i == STEPS - 1 and _any_note():
		loops += 1
		_check_stars()
	_paint_cells()


func notes_count() -> int:
	var n := 0
	for row in grid:
		n += row.count(true)
	return n


func _any_note() -> bool:
	return notes_count() > 0


## Estrellas: 4 notas, 10 notas, 3 alturas distintas, el tambor y escucharla entera dos veces.
func _check_stars() -> void:
	var pitches := 0
	for r in NOTES.size() - 1:
		if grid[r].has(true):
			pitches += 1
	var goals := {"few": notes_count() >= 4, "many": notes_count() >= 10, "pitches": pitches >= 3,
		"drum": grid[NOTES.size() - 1].has(true), "listen": loops >= 2}
	for key in goals:
		if goals[key] and not _stars.has(key):
			_stars[key] = true
			_mark(true)


func _finish() -> void:
	if _layer != null:
		return
	if notes_count() < 4:
		if _notice == null:
			_notice = BigNotice.new(600.0)
			add_child(_notice)
			_notice.closed.connect(func(): _notice = null)
			_notice.title("¡Agrega más notas!", Color("5b6fc4"))
			_notice.text_line("Toca algunos cuadritos para armar tu canción.", 28)
			_notice.button("¡Bien!", _notice.close)
		return
	set_playing(false)
	if is_instance_valid(_pet):
		_pet.lean = 0.0
	_show_result("¡Qué linda canción!", _stars.size(), 5)
