class_name GuardianShield
extends RefCounted
## Escudo do guardião (spec COM-guardiao, regras 2 a 4): troca de elemento num ciclo, com uma
## brecha sem escudo entre um e outro. Com escudo, só passa o elemento que vence o escudo.

const CYCLE := ["fogo", "planta", "gelo"]
const SHIELD_TIME := 4.0
const GAP_TIME := 1.0
const BLINK_TIME := 1.0
const BODY_ELEMENT := "pedra"

var time := 0.0


func tick(delta: float) -> void:
	time += delta


## Elemento do escudo agora; vazio na brecha.
func current() -> String:
	var period := SHIELD_TIME + GAP_TIME
	if fmod(time, period) >= SHIELD_TIME:
		return ""
	return CYCLE[int(time / period) % CYCLE.size()]


func is_blinking() -> bool:
	var within := fmod(time, SHIELD_TIME + GAP_TIME)
	return within >= SHIELD_TIME - BLINK_TIME and within < SHIELD_TIME


## {"blocked", "damage", "effect"} de um golpe agora.
func resolve(attack: String, form: String) -> Dictionary:
	var shield := current()
	if shield.is_empty():
		var effect := ElementTable.effect(attack, BODY_ELEMENT)
		return {"blocked": false, "damage": Damage.amount(attack, form, BODY_ELEMENT), "effect": effect}
	if ElementTable.effect(attack, shield) != ElementTable.Effect.WEAK:
		return {"blocked": true, "damage": 0, "effect": ElementTable.Effect.RESIST}
	return {"blocked": false, "damage": Damage.amount(attack, form, shield), "effect": ElementTable.Effect.WEAK}
