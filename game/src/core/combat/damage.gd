class_name Damage
extends RefCounted
## Dano de um golpe contra um elemento (spec COM-dano, regra 1). Os números vêm do
## balanceamento, seção `dano` (spec BAL-valores).

## Formas com dano próprio; forma desconhecida conta como projétil.
const FORMS := ["projetil", "faisca"]


static func amount(attack: String, form: String, target_element: String) -> int:
	if attack == "cajado":
		return Balance.integer("dano", "cajado")
	var base := Balance.number("dano", form if form in FORMS else "projetil")
	return int(floor(base * ElementTable.multiplier(ElementTable.effect(attack, target_element))))
