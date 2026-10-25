class_name MagoState
extends RefCounted
## Vida e mana reais do mago (spec MUN-vida). O executor só simula; quem manda é este estado.

signal mana_changed(mana: float, mana_max: float)

const MANA_STEP := 0.1

var health := Health.new(5)
var mana: float = 0.0
var mana_max: float = 10.0


func set_mana(value: float) -> void:
	mana = clampf(snappedf(value, MANA_STEP), 0.0, mana_max)
	mana_changed.emit(mana, mana_max)


## O "mago" do protocolo do executor (spec EXE-protocolo).
func to_spell_mago() -> Dictionary:
	return {"vida": health.current, "mana": mana, "mana_max": mana_max}
