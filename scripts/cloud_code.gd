class_name CloudCode
extends RefCounted
## Codigos de transferencia de partidas: 12 letras y numeros sin los que se confunden (I, O, 0, 1),
## que se muestran de a 4 (ABCD-EFGH-JKLM). Son 60 bits al azar: imposibles de adivinar.

const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LEN := 12
const FRIEND_LEN := 8      # codigos de amigo (los da el servidor)


## Deja solo letras y numeros validos, en mayusculas (para lo que escribe el jugador).
static func normalize(text: String) -> String:
	var out := ""
	for ch in text.to_upper():
		if ALPHABET.contains(ch):
			out += ch
	return out


## El codigo limpio si es valido, o "" si no.
static func clean_code(text: String) -> String:
	var c := normalize(text)
	return c if c.length() == CODE_LEN else ""


## Codigo de amigo (8 caracteres) limpio, o "" si no es valido.
static func clean_friend(text: String) -> String:
	var c := normalize(text)
	return c if c.length() == FRIEND_LEN else ""


## "ABCDEFGHJKLM" -> "ABCD-EFGH-JKLM"
static func format_code(code: String) -> String:
	var parts := []
	for i in range(0, code.length(), 4):
		parts.append(code.substr(i, 4))
	return "-".join(parts)


static func new_code() -> String:
	var bytes := Crypto.new().generate_random_bytes(CODE_LEN)
	var out := ""
	for b in bytes:
		out += ALPHABET[b % ALPHABET.length()]   # 256 es multiplo de 32: todas las letras igual de probables
	return out
