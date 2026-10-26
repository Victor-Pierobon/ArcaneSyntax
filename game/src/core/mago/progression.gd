class_name Progression
extends RefCounted
## Curva de níveis e XP dos puzzles (specs PRO-xp e PRO-niveis). Os números vêm do
## balanceamento, seções `xp` e `niveis` (spec BAL-valores).


static func max_level() -> int:
	return maxi(Balance.list("niveis", "xp").size(), 1)


## Maior nível cujo limiar de XP acumulada a `xp` alcança.
static func level_for(xp: int) -> int:
	var thresholds := Balance.list("niveis", "xp")
	var level := 1
	for i in thresholds.size():
		if xp >= int(thresholds[i]):
			level = i + 1
	return level


static func mana_max_for(level: int) -> float:
	var values := Balance.list("niveis", "mana_max")
	if values.is_empty():
		return 0.0
	return float(values[clampi(level, 1, values.size()) - 1])


## XP acumulada para o nível seguinte; -1 no último nível.
static func next_threshold(level: int) -> int:
	var thresholds := Balance.list("niveis", "xp")
	return int(thresholds[level]) if level < thresholds.size() else -1


## Bônus por solução econômica: por estrela acima de uma (PRO-xp, regra 3).
static func economy_bonus(stars: int) -> int:
	return maxi(stars - 1, 0) * Balance.integer("xp", "bonus_estrela")


static func puzzle_xp(stars: int) -> int:
	return Balance.integer("xp", "puzzle") + economy_bonus(stars)
