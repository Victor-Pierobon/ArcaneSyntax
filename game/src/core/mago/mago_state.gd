class_name MagoState
extends RefCounted
## Vida e mana reais do mago (spec MUN-vida). O executor só simula; quem manda é este estado.

signal mana_changed(mana: float, mana_max: float)

const MANA_STEP := 0.1
## Peças sujeitas a desbloqueio (spec EXE-desbloqueio).
const ALL_PIECES: Array[String] = [
	"lancar", "mover", "levitar", "meditar", "absorver_mana", "inscrever", "construir_bloco",
	"fogo", "gelo", "raio", "projetil", "escudo", "faisca",
]

## Vida, mana máxima e invencibilidade vêm do balanceamento, seção `mago` (spec BAL-valores).
var health := Health.new(Balance.integer("mago", "vida"))
var mana: float = 0.0
var mana_max: float = Balance.number("mago", "mana_max")
## Até a progressão existir (Sprint 12), tudo começa desbloqueado (GRI-slots, regra 11).
var unlocked_pieces := PackedStringArray(ALL_PIECES)


func _init() -> void:
	health.invulnerable_time = Balance.number("mago", "invencivel_s")


func set_mana(value: float) -> void:
	mana = clampf(snappedf(value, MANA_STEP), 0.0, mana_max)
	mana_changed.emit(mana, mana_max)


## O "mago" do protocolo do executor (spec EXE-protocolo).
func to_spell_mago() -> Dictionary:
	return {"vida": health.current, "mana": mana, "mana_max": mana_max}
