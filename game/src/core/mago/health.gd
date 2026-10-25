class_name Health
extends RefCounted
## Vida do mago (spec MUN-vida).

signal changed(current: int, maximum: int)
signal died

enum Source { ATTACK, HAZARD }

var maximum: int
var current: int
## Invencibilidade depois de levar dano, em segundos.
var invulnerable_time: float = 1.0
## Ligado enquanto o mago esquiva: protege de ataques, não de espinhos (MUN-023).
var dodging: bool = false

var _invulnerable_left := 0.0


func _init(p_maximum: int = 5) -> void:
	maximum = p_maximum
	current = p_maximum


## Devolve true se o dano contou.
func damage(amount: int, source: Source = Source.ATTACK) -> bool:
	if is_dead() or _invulnerable_left > 0.0:
		return false
	if dodging and source == Source.ATTACK:
		return false
	current = maxi(current - amount, 0)
	_invulnerable_left = invulnerable_time
	changed.emit(current, maximum)
	if current == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	current = mini(current + amount, maximum)
	changed.emit(current, maximum)


func restore_full() -> void:
	current = maximum
	_invulnerable_left = 0.0
	changed.emit(current, maximum)


func tick(delta: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)


func is_dead() -> bool:
	return current == 0


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0
