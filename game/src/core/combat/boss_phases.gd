class_name BossPhases
extends RefCounted
## Fases do chefe (spec COM-chefe, regras 2 a 4): cada fase tem um elemento; a vida passa por
## limites que trocam de fase, com uma transição invulnerável. Nenhum golpe pula um limite.
## Os números vêm do balanceamento, seção `chefe` (spec BAL-valores).

var phase := 1

var elements: Array = Balance.list("chefe", "elementos")
## Vida em que começa cada fase depois da primeira: [60, 30].
var switch_health: Array = Balance.list("chefe", "troca_vida")
var transition_time := Balance.number("chefe", "transicao_s")

var _transition_left := 0.0


func element() -> String:
	return str(elements[mini(phase, elements.size()) - 1]) if not elements.is_empty() else ""


func in_transition() -> bool:
	return _transition_left > 0.0


## Vida abaixo da qual a fase atual não desce, ou -1 na última fase.
func floor_health() -> int:
	return int(switch_health[phase - 1]) if phase - 1 < switch_health.size() else -1


## {"blocked", "damage", "effect"} de um golpe com o chefe em `health_now` (regras 3 e 4).
func resolve(attack: String, form: String, health_now: int) -> Dictionary:
	if in_transition():
		return {"blocked": true, "damage": 0, "effect": ElementTable.Effect.RESIST}
	var target := element()
	var damage := Damage.amount(attack, form, target)
	var limit := floor_health()
	if limit >= 0:
		damage = clampi(damage, 0, maxi(health_now - limit, 0))
	return {"blocked": false, "damage": damage, "effect": ElementTable.effect(attack, target)}


## Depois do dano: true se trocou de fase agora (começa a transição). Uma fase por vez.
func after_damage(health_now: int) -> bool:
	var limit := floor_health()
	if in_transition() or limit < 0 or health_now > limit:
		return false
	phase += 1
	_transition_left = transition_time
	return true


## Avança a transição; true no passo em que ela termina.
func tick(delta: float) -> bool:
	if not in_transition():
		return false
	_transition_left -= delta
	return not in_transition()
