extends Node
## Autoload "Audio": musica de fondo (con cambio suave entre pistas) y efectos de sonido.
## Todos los botones suenan solos; usa set_meta("silent", true) en uno para evitarlo.
## Algunos efectos tambien vibran un toque corto en el celular (se apagan junto con los sonidos).

const DIR := "res://assets/audio/"
const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_FILES := {"home": "music_home.ogg", "play": "music_play.ogg"}
const MUSIC_DB := -9.0
const SFX_DB := {"click": -16.0, "bath": -12.0, "eat": -10.0, "drink": -10.0, "stamp": -5.0, "ding": -10.0}
const DEFAULT_SFX_DB := -8.0
const POOL_SIZE := 8
## Milisegundos de vibracion por efecto (solo en el celular). Cortos y suaves: es para chicos.
const HAPTIC_MS := {"pet": 12, "coin": 20, "success": 35, "hatch": 70, "stamp": 30, "fail": 25}
const HAPTIC_GAP := 0.08   # no encadenar vibraciones (varias monedas seguidas = una sola)
const PLAY_SCENES := ["math_game", "simon_game", "pattern_game", "minigames", "job_game"]

var music_on := true
var sfx_on := true

var _music: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _streams := {}
var _track := ""
var _watch := 0.0
var _fade: Tween
var _last_haptic := -1.0


func _ready() -> void:
	_load_settings()
	_music = AudioStreamPlayer.new()
	_music.volume_db = -80.0
	add_child(_music)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	get_tree().node_added.connect(_on_node_added)


## La musica no debe sonar con la app en segundo plano.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if _music != null:
				_music.stream_paused = true
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if _music != null:
				_music.stream_paused = false


func _process(delta: float) -> void:
	_watch -= delta
	if _watch > 0.0:
		return
	_watch = 0.4
	var scene := get_tree().current_scene
	if scene == null:
		return
	var scene_name := scene.scene_file_path.get_file().get_basename()
	if scene_name == "intro":
		play_music("")
	elif scene_name in PLAY_SCENES:
		play_music("play")
	else:
		play_music("home")


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.pressed.is_connected(_on_button_pressed):
		node.pressed.connect(_on_button_pressed.bind(node))


func _on_button_pressed(button: BaseButton) -> void:
	if not button.has_meta("silent"):
		play("click")


func _stream(file: String) -> AudioStream:
	if not _streams.has(file):
		var s: AudioStream = load(DIR + file)
		if s is AudioStreamOggVorbis:
			s.loop = true
		_streams[file] = s
	return _streams[file]


func play(sfx_name: String, pitch := 1.0) -> void:
	if not sfx_on:
		return
	vibrate(HAPTIC_MS.get(sfx_name, 0))
	for p in _pool:
		if not p.playing:
			p.stream = _stream("sfx_%s.wav" % sfx_name)
			p.volume_db = SFX_DB.get(sfx_name, DEFAULT_SFX_DB)
			p.pitch_scale = pitch
			p.play()
			return


## Vibracion corta. En PC y en la web no hace nada.
func vibrate(ms: int) -> void:
	if ms <= 0 or not sfx_on or not OS.has_feature("mobile"):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _last_haptic >= 0.0 and now - _last_haptic < HAPTIC_GAP:
		return
	_last_haptic = now
	Input.vibrate_handheld(ms, 0.5)


func play_music(track: String) -> void:
	if track == _track:
		return
	_track = track
	_apply_music()


func _apply_music() -> void:
	if _fade != null:
		_fade.kill()
	if not _music.playing and (_track == "" or not music_on):
		return
	_fade = create_tween()
	if _music.playing:
		_fade.tween_property(_music, "volume_db", -60.0, 0.8)
		_fade.tween_callback(_music.stop)
	if _track == "" or not music_on:
		return
	_fade.tween_callback(func():
		_music.stream = _stream(MUSIC_FILES[_track])
		_music.volume_db = -60.0
		_music.play())
	_fade.tween_property(_music, "volume_db", MUSIC_DB, 1.5)


func set_music_on(value: bool) -> void:
	music_on = value
	_save_settings()
	_apply_music()


func set_sfx_on(value: bool) -> void:
	sfx_on = value
	_save_settings()


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_on = cfg.get_value("audio", "music", true)
		sfx_on = cfg.get_value("audio", "sfx", true)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("audio", "sfx", sfx_on)
	cfg.save(SETTINGS_PATH)
