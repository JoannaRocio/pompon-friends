extends SceneTree
## Genetica, etapas de vida (el huevo espera la cuna) y abandono a los 30 dias.


func _initialize() -> void:
	var now := int(Time.get_unix_time_from_system())
	var p := Pompon.generate()
	print("generado: ", p.id, " ", p.species, " ", p.sex, " ", p.personality)
	print("recien creado: etapa=", p.stage_name(now), " | huevo=", not p.hatched)
	p.born_at = now - 90 * 86400
	print("un huevo no crece solo (90 dias despues): ", p.stage_name(now))
	p.hatch(now)
	print("al nacer: etapa=", p.stage_name(now))
	print("etapa +10min: ", p.stage_name(now + 600))
	print("etapa +8d: ", p.stage_name(now + 8 * 86400))
	print("etapa +40d: ", p.stage_name(now + 40 * 86400))
	print("etapa +100d: ", p.stage_name(now + 100 * 86400))
	var left := p.advance(3600.0 * 10)
	print("tras 10h: comida=", snappedf(p.stats["alimentacion"], 0.1), " inteligencia=", p.stats["inteligencia"], " se_va=", left)
	left = p.advance(30.0 * 86400.0)
	print("tras 30 dias mas: se_va=", left)
	quit()
