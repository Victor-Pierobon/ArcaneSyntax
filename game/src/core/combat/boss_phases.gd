class_name BossPhases
extends RefCounted
## Fases do chefe (spec COM-chefe, regras 2 a 4 e 6): cada fase tem um elemento; na metade da vida
## troca de fase, com uma transição invulnerável. Também conta o tempo até o próximo orbe.
## Os números vêm do balanceamento, seção `chefe` (spec BAL-valores).

var phase := 1
## Segundos até o próximo orbe; só corre com o mago perto e fora da transição.
var attack_left: float

var elements: Array = Balance.list("chefe", "elementos")
var switch_health := Balance.integer("chefe", "troca_vida")
var transition_time := Balance.number("chefe", "transicao_s")

var _transition_left := 0.0
var _was_near := false


func _init() -> void:
	attack_left = attack_interval()


func element() -> String:
	return str(elements[mini(phase, elements.size()) - 1]) if not elements.is_empty() else ""


func in_transition() -> bool:
	return _transition_left > 0.0


func attack_interval() -> float:
	return Balance.number("chefe", "ataque_fase%d_s" % phase)


## {"blocked", "damage", "effect"} de um golpe com o chefe em `health_now` (regras 3 e 4).
func resolve(attack: String, form: String, health_now: int) -> Dictionary:
	if in_transition():
		return {"blocked": true, "damage": 0, "effect": ElementTable.Effect.RESIST}
	var target := element()
	var damage := Damage.amount(attack, form, target)
	if phase == 1:
		damage = clampi(damage, 0, maxi(health_now - switch_health, 0))
	return {"blocked": false, "damage": damage, "effect": ElementTable.effect(attack, target)}


## Depois do dano: true se trocou de fase agora (começa a transição).
func after_damage(health_now: int) -> bool:
	if phase != 1 or health_now > switch_health:
		return false
	phase = 2
	_transition_left = transition_time
	return true


## Avança o relógio; true quando sai um orbe neste passo (regra 6).
func tick(delta: float, player_near: bool) -> bool:
	if in_transition():
		_transition_left -= delta
		if not in_transition():
			attack_left = attack_interval()
		return false
	if not player_near:
		_was_near = false
		return false
	if not _was_near:
		# O primeiro orbe sai um intervalo depois de o mago chegar perto.
		_was_near = true
		attack_left = attack_interval()
	attack_left -= delta
	if attack_left > 0.0:
		return false
	attack_left += attack_interval()
	return true
