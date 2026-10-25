class_name ElementTable
extends RefCounted
## Efetividade de um ataque contra o elemento do alvo (spec MAG-elementos).

enum Effect { NORMAL, WEAK, RESIST }

## Ataque → elemento contra o qual ele é forte.
const STRONG_AGAINST := {"fogo": "planta", "gelo": "fogo", "raio": "gelo"}
## Elementos que resistem a si mesmos.
const SPELL_ELEMENTS := ["fogo", "gelo", "raio"]

const MULTIPLIERS := {Effect.NORMAL: 1.0, Effect.WEAK: 2.0, Effect.RESIST: 0.5}
const LABEL_KEYS := {Effect.NORMAL: "ALVO_ACERTOU", Effect.WEAK: "ALVO_FRACO", Effect.RESIST: "ALVO_RESISTIU"}


static func effect(attack: String, target: String) -> Effect:
	if STRONG_AGAINST.get(attack, "") == target:
		return Effect.WEAK
	if attack == target and attack in SPELL_ELEMENTS:
		return Effect.RESIST
	return Effect.NORMAL


static func multiplier(value: Effect) -> float:
	return MULTIPLIERS[value]
