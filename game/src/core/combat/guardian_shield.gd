class_name GuardianShield
extends RefCounted
## Escudo do guardião (spec COM-guardiao, regras 2 a 4): troca de elemento num ciclo, com uma
## brecha sem escudo entre um e outro. Com escudo, só passa o elemento que vence o escudo.

const CYCLE := ["fogo", "planta", "gelo"]
const BODY_ELEMENT := "pedra"

var time := 0.0
## Do balanceamento, seção `guardiao` (spec BAL-valores).
var shield_time := Balance.number("guardiao", "escudo_s")
var gap_time := Balance.number("guardiao", "brecha_s")
var blink_time := Balance.number("guardiao", "pisca_s")


func tick(delta: float) -> void:
	time += delta


## Elemento do escudo agora; vazio na brecha.
func current() -> String:
	var period := shield_time + gap_time
	if fmod(time, period) >= shield_time:
		return ""
	return CYCLE[int(time / period) % CYCLE.size()]


func is_blinking() -> bool:
	var within := fmod(time, shield_time + gap_time)
	return within >= shield_time - blink_time and within < shield_time


## {"blocked", "damage", "effect"} de um golpe agora.
func resolve(attack: String, form: String) -> Dictionary:
	var shield := current()
	if shield.is_empty():
		var effect := ElementTable.effect(attack, BODY_ELEMENT)
		return {"blocked": false, "damage": Damage.amount(attack, form, BODY_ELEMENT), "effect": effect}
	if ElementTable.effect(attack, shield) != ElementTable.Effect.WEAK:
		return {"blocked": true, "damage": 0, "effect": ElementTable.Effect.RESIST}
	return {"blocked": false, "damage": Damage.amount(attack, form, shield), "effect": ElementTable.Effect.WEAK}
