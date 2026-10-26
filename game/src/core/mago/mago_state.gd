class_name MagoState
extends RefCounted
## Vida, mana, XP e nível reais do mago (specs MUN-vida, PRO-xp, PRO-niveis). O executor só simula;
## quem manda é este estado.

signal mana_changed(mana: float, mana_max: float)
signal xp_changed(xp: int, level: int)
signal leveled_up(level: int)

const MANA_STEP := 0.1
## Peças sujeitas a desbloqueio (spec EXE-desbloqueio).
const ALL_PIECES: Array[String] = [
	"lancar", "mover", "levitar", "meditar", "absorver_mana", "inscrever", "construir_bloco",
	"fogo", "gelo", "raio", "projetil", "escudo", "faisca",
]

## Vida e invencibilidade vêm do balanceamento, seção `mago`; a mana máxima, do nível (spec BAL-valores).
var health := Health.new(Balance.integer("mago", "vida"))
var mana: float = 0.0
var xp := 0
var level := 1
var mana_max: float = Progression.mana_max_for(1)
## Até os upgrades da torre existirem, tudo começa desbloqueado (GRI-slots, regra 11).
var unlocked_pieces := PackedStringArray(ALL_PIECES)


func _init() -> void:
	health.invulnerable_time = Balance.number("mago", "invencivel_s")


func set_mana(value: float) -> void:
	mana = clampf(snappedf(value, MANA_STEP), 0.0, mana_max)
	mana_changed.emit(mana, mana_max)


## Soma XP e sobe os níveis alcançados; cada nível novo aumenta e enche a mana (PRO-niveis, regra 4).
func gain_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	var reached := Progression.level_for(xp)
	while level < reached:
		level += 1
		mana_max = Progression.mana_max_for(level)
		set_mana(mana_max)
		leveled_up.emit(level)
	xp_changed.emit(xp, level)


## Volta ao progresso de um save, sem avisar subida de nível: o nível e a mana máxima vêm da XP
## (spec SAV-progresso, regra 3).
func restore_progress(p_xp: int, p_mana: float) -> void:
	xp = maxi(p_xp, 0)
	level = Progression.level_for(xp)
	mana_max = Progression.mana_max_for(level)
	set_mana(p_mana)
	xp_changed.emit(xp, level)


## O "mago" do protocolo do executor (spec EXE-protocolo).
func to_spell_mago() -> Dictionary:
	return {"vida": health.current, "mana": mana, "mana_max": mana_max}
