class_name T
extends RefCounted
## Textos en varios idiomas (español e inglés). Los textos viven en locale/textos.csv (columnas
## keys,es,en), que Godot importa como traducciones (ver docs/idiomas.md).
##
## - T.t("menu.play")                         -> "¡Jugar!" / "Play!"
## - T.t("tip.growth", {"name": "Mochi"})     -> reemplaza {name} en el texto
## - T.g("menu.reset_sure", "f")              -> variante por genero ("menu.reset_sure.f", ".m", ".n";
##                                               si no existe, la clave sin genero)
## - T.s("Tienda")                          -> el español es la clave ("s:Tienda"); lo mas simple
## - T.data("item", id, nombre)               -> nombres de datos por id (objetos, comidas, paises...)
## - T.label("Comer")                         -> boton cuyo texto en español es tambien su id
##                                               (ActionButton.caption, solapas): busca "ui.Comer"
## El idioma se elige en el menu (GameState.language); vacio = el del celular.

const LANGS := ["es", "en"]
static var _applied := false   # (si algo pide un texto antes de que GameState cargue la partida, se usa el del celular)
const LANG_NAMES := {"es": "Español", "en": "English"}


## Texto de una clave, con {marcadores} reemplazados.
static func t(key: String, params := {}) -> String:
	_ensure()
	var s := String(TranslationServer.translate(key))
	if not params.is_empty():
		s = s.format(params)
	return s


## Igual que t(), con variante por genero ("f", "m" o "n").
static func g(key: String, gender: String, params := {}) -> String:
	_ensure()
	var gk := key + "." + gender
	if gender != "" and String(TranslationServer.translate(gk)) != gk:
		return t(gk, params)
	return t(key, params)


## "1 día" / "3 días": usa "clave.one" o "clave.many" con {n}.
static func n(key: String, count: int, params := {}) -> String:
	var p := params.duplicate()
	p["n"] = count
	return t(key + (".one" if count == 1 else ".many"), p)


## Texto con el español como clave ("s:" + texto): T.s("Tienda") -> "Shop". Si no esta en el CSV, queda en
## español. Con `params`, reemplaza {marcadores}. Es la forma mas simple para textos nuevos.
static func s(spanish: String, params := {}) -> String:
	_ensure()
	var k := "s:" + spanish
	var out := String(TranslationServer.translate(k))
	if out == k:
		out = spanish
	return out.format(params) if not params.is_empty() else out


## Nombre de un dato por su id ("item.hat_bow", "food.pizza"...); si no esta, `fallback`.
static func data(prefix: String, id: String, fallback: String) -> String:
	_ensure()
	var k := prefix + "." + id
	var out := String(TranslationServer.translate(k))
	return fallback if out == k else out


## Etiqueta de un boton cuyo texto en español es tambien su identificador. Si no esta en el CSV, queda igual.
static func label(spanish: String) -> String:
	_ensure()
	var k := "ui." + spanish
	var out := String(TranslationServer.translate(k))
	return spanish if out == k else out


## Pronombres en inglés del Pompon para las frases ({he}, {He}, {his}, {His}, {him}, {himself}):
## "Hembra" -> she/her, "Macho" -> he/his. (En español no se usan: el genero va con {a}.)
static func pron(sex: String) -> Dictionary:
	if sex == "Hembra":
		return {"he": "she", "He": "She", "his": "her", "His": "Her", "him": "her", "himself": "herself"}
	return {"he": "he", "He": "He", "his": "his", "His": "His", "him": "him", "himself": "himself"}


## Completa {he}, {his}... de un texto en inglés con el sexo del Pompon (si no hay marcadores, igual).
static func with_pron(text: String, sex: String) -> String:
	return text.format(pron(sex)) if text.contains("{") else text


## Idioma en uso ("es" o "en").
static func lang() -> String:
	_ensure()
	return TranslationServer.get_locale().left(2)


## El idioma del celular: español si esta en español; si no, inglés. (POMPON_LANG lo fija en las pruebas.)
static func device_lang() -> String:
	var forced := OS.get_environment("POMPON_LANG")
	if forced in LANGS:
		return forced
	return "es" if OS.get_locale_language() == "es" else "en"


## Aplica un idioma ("" = el del celular).
static func apply(language: String) -> void:
	_applied = true
	TranslationServer.set_locale(language if language in LANGS else device_lang())


static func _ensure() -> void:
	if not _applied:
		apply("")
