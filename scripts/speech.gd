class_name Speech
extends RefCounted
## Voz del telefono para escuchar el ingles (texto a voz del sistema). Si el telefono no tiene una
## voz en ingles, o los sonidos estan apagados, no se dice nada y el juego sigue igual (la
## pronunciacion tambien se ve escrita).

static var _voices := {}   # idioma ("en", "es") -> voz del telefono ("" = no tiene)


static func voice(lang := "en") -> String:
	if not _voices.has(lang):
		_voices[lang] = ""
		if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
			var voices := DisplayServer.tts_get_voices_for_language(lang)
			if not voices.is_empty():
				_voices[lang] = voices[0]
	return _voices[lang]


static func available(lang := "en") -> bool:
	return voice(lang) != ""


## Dice `text` en ese idioma (corta lo que se estaba diciendo). Ingles en la clase de Inglés, español en
## la clase de Español.
static func say(text: String, lang := "en") -> void:
	if not available(lang) or not Audio.sfx_on:
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voice(lang), 70, 1.0, 0.9)
