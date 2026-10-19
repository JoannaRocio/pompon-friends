class_name Speech
extends RefCounted
## Voz del telefono para escuchar el ingles (texto a voz del sistema). Si el telefono no tiene una
## voz en ingles, o los sonidos estan apagados, no se dice nada y el juego sigue igual (la
## pronunciacion tambien se ve escrita).

static var _voice := "?"   # "?" = todavia no se busco


static func voice() -> String:
	if _voice == "?":
		_voice = ""
		if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
			var voices := DisplayServer.tts_get_voices_for_language("en")
			if not voices.is_empty():
				_voice = voices[0]
	return _voice


static func available() -> bool:
	return voice() != ""


## Dice `text` en ingles (corta lo que se estaba diciendo).
static func say(text: String) -> void:
	if not available() or not Audio.sfx_on:
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voice(), 70, 1.0, 0.9)
