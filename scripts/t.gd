class_name T
extends RefCounted
## Textos en varios idiomas (español e inglés). Los textos viven en locale/textos.csv (columnas
## keys,es,en), que Godot importa como traducciones (ver docs/idiomas.md).
##
## - T.t("menu.play")                         -> "¡Jugar!" / "Play!"
## - T.t("tip.growth", {"name": "Mochi"})     -> reemplaza {name} en el texto
## - T.g("menu.reset_sure", "f")              -> variante por genero ("menu.reset_sure.f", ".m", ".n";
##                                               si no existe, la clave sin genero)
## - T.label("Comer")                         -> boton cuyo texto en español es tambien su id
##                                               (ActionButton.caption, solapas): busca "ui.Comer"
## El idioma se elige en el menu (GameState.language); vacio = el del celular.

const LANGS := ["es", "en"]
const LANG_NAMES := {"es": "Español", "en": "English"}


## Texto de una clave, con {marcadores} reemplazados.
static func t(key: String, params := {}) -> String:
	var s := String(TranslationServer.translate(key))
	if not params.is_empty():
		s = s.format(params)
	return s


## Igual que t(), con variante por genero ("f", "m" o "n").
static func g(key: String, gender: String, params := {}) -> String:
	var gk := key + "." + gender
	if gender != "" and String(TranslationServer.translate(gk)) != gk:
		return t(gk, params)
	return t(key, params)


## "1 día" / "3 días": usa "clave.one" o "clave.many" con {n}.
static func n(key: String, count: int, params := {}) -> String:
	var p := params.duplicate()
	p["n"] = count
	return t(key + (".one" if count == 1 else ".many"), p)


## Etiqueta de un boton cuyo texto en español es tambien su identificador. Si no esta en el CSV, queda igual.
static func label(spanish: String) -> String:
	var k := "ui." + spanish
	var s := String(TranslationServer.translate(k))
	return spanish if s == k else s


## Idioma en uso ("es" o "en").
static func lang() -> String:
	return TranslationServer.get_locale().left(2)


## El idioma del celular: español si esta en español; si no, inglés. (POMPON_LANG lo fija en las pruebas.)
static func device_lang() -> String:
	var forced := OS.get_environment("POMPON_LANG")
	if forced in LANGS:
		return forced
	return "es" if OS.get_locale_language() == "es" else "en"


## Aplica un idioma ("" = el del celular).
static func apply(language: String) -> void:
	TranslationServer.set_locale(language if language in LANGS else device_lang())
