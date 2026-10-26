class_name Damage
extends RefCounted
## Dano de um golpe contra um elemento (spec COM-dano, regra 1).

## Dano base por forma; forma desconhecida conta como projétil.
const BASE := {"projetil": 3, "faisca": 1}
const STAFF_DAMAGE := 1


static func amount(attack: String, form: String, target_element: String) -> int:
	if attack == "cajado":
		return STAFF_DAMAGE
	var base: int = BASE.get(form, BASE["projetil"])
	return int(floor(base * ElementTable.multiplier(ElementTable.effect(attack, target_element))))
