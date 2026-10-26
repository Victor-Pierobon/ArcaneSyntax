class_name ElementTable
extends RefCounted
## Efetividade de um ataque contra o elemento do alvo (spec MAG-elementos).

enum Effect { NORMAL, WEAK, RESIST }

## Ataque → elemento contra o qual ele é forte.
const STRONG_AGAINST := {"fogo": "planta", "gelo": "fogo", "raio": "gelo"}
## Elementos que resistem a si mesmos.
const SPELL_ELEMENTS := ["fogo", "gelo", "raio"]

## Chave do multiplicador na seção `dano` do balanceamento (spec BAL-valores).
const MULTIPLIER_KEYS := {Effect.NORMAL: "normal", Effect.WEAK: "fraco", Effect.RESIST: "resiste"}
const LABEL_KEYS := {Effect.NORMAL: "ALVO_ACERTOU", Effect.WEAK: "ALVO_FRACO", Effect.RESIST: "ALVO_RESISTIU"}


static func effect(attack: String, target: String) -> Effect:
	if STRONG_AGAINST.get(attack, "") == target:
		return Effect.WEAK
	if attack == target and attack in SPELL_ELEMENTS:
		return Effect.RESIST
	return Effect.NORMAL


static func multiplier(value: Effect) -> float:
	return Balance.number("dano", MULTIPLIER_KEYS[value])
