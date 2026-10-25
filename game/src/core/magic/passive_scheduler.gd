class_name PassiveScheduler
extends RefCounted
## Quando o slot passivo roda e quando ele se desliga (spec MAG-passivo).

enum Outcome { OK, MANA_OUT_FIRST, MANA_OUT_REPEAT, DISABLED, TRANSIENT }

const INTERVAL := 1.0
## Erros que não desligam o passivo (regras 5 e 6).
const MANA_ERROR := "ManaEsgotada"
const TRANSIENT_ERRORS := ["ExecutorIndisponivel"]

var _elapsed := 0.0
var _busy := false
var _disabled := false
var _mana_streak := false


## Avança o relógio; devolve true quando é hora de executar o passivo.
func tick(delta: float) -> bool:
	if _disabled or _busy:
		return false
	_elapsed += delta
	if _elapsed < INTERVAL:
		return false
	_elapsed = 0.0
	return true


func mark_started() -> void:
	_busy = true


func mark_finished(result: SpellResult) -> Outcome:
	_busy = false
	if result.error == null:
		_mana_streak = false
		return Outcome.OK
	if result.error.type == MANA_ERROR:
		var first := not _mana_streak
		_mana_streak = true
		return Outcome.MANA_OUT_FIRST if first else Outcome.MANA_OUT_REPEAT
	if result.error.type in TRANSIENT_ERRORS:
		return Outcome.TRANSIENT
	_disabled = true
	return Outcome.DISABLED


func is_disabled() -> bool:
	return _disabled


func is_busy() -> bool:
	return _busy


## Religa (código editado ou passivo equipado de novo).
func reset() -> void:
	_disabled = false
	_elapsed = 0.0
	_mana_streak = false
