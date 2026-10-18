class_name Missions
extends RefCounted
## Misiones diarias y Pase Pompon (gratis en la fase beta).

const DAILY := [
	{"id": "care", "text": "Cuida a tu Pompon 5 veces", "goal": 5, "coins": 10, "xp": 10},
	{"id": "minigame", "text": "Juega 2 minijuegos", "goal": 2, "coins": 15, "xp": 15},
	{"id": "buy", "text": "Compra 1 ítem en la tienda", "goal": 1, "coins": 10, "xp": 10},
	{"id": "job", "text": "Da una clase de matemáticas", "goal": 1, "coins": 15, "xp": 15},
	{"id": "visit", "text": "Visita a un vecino", "goal": 1, "coins": 12, "xp": 12},
]

const PASS_XP_PER_TIER := 20
const PASS_TIERS := [
	{"coins": 10, "item": ""},
	{"coins": 15, "item": ""},
	{"coins": 0, "item": "hat_crown"},
	{"coins": 25, "item": ""},
	{"coins": 0, "item": "shirt_hoodie"},
]


static func today(unix_time: int) -> int:
	return unix_time / 86400


static func get_def(id: String) -> Dictionary:
	for m in DAILY:
		if m["id"] == id:
			return m
	return {}
