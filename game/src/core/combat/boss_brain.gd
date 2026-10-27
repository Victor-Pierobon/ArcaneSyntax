class_name BossBrain
extends RefCounted
## O que o chefe faz a cada passo (spec COM-chefe, regras 4 e 7 a 13): espera o início e repete,
## sem sorteio, mover → aviso → ataque → descanso, com a lista de ataques da fase. Também guarda
## as fases (BossPhases) e as marcas dos pilares. O nó só desenha e aplica os eventos de `tick`:
## {"tipo": "mover", "ataque", "destino"}, {"tipo": "aviso", "ataque"}, {"tipo": "leque", "direcoes"},
## {"tipo": "marca", "id", "posicao"}, {"tipo": "pilar", "id"}, {"tipo": "pilar_fim", "id"},
## {"tipo": "investida", "destino"} e {"tipo": "cancelar"} (a troca de fase cancelou o ataque).

enum State { START, MOVE, WARN, ATTACK, REST, TRANSITION }

## Folga nas contas de tempo: a soma de passos de 1/60 s não fecha exata.
const EPSILON := 1e-6

var phases := BossPhases.new()
var state := State.START
var position: Vector2
## O ataque em andamento (ou o próximo, enquanto o chefe vai ao ponto dele).
var attack := ""
## Marcas de pilar no chão: {"id", "posicao", "tempo", "subiu"}.
var marks: Array[Dictionary] = []
## Centro do mago → ponto do chão sob ele (o nó usa `RoomLayout.floor_below`).
var floor_finder: Callable = func(center: Vector2) -> Vector2: return center

var points: Array[Vector2] = []
var charge_points: Array[Vector2] = []

var _timer := Balance.number("chefe", "inicio_s")
var _destination := Vector2.ZERO
var _next_point := 0
var _next_attack := 0
var _marks_left := 0
var _mark_id := 0
var _events: Array[Dictionary] = []


func _init(start: Vector2, p_points: Array[Vector2], p_charge_points: Array[Vector2]) -> void:
	position = start
	points = p_points
	charge_points = p_charge_points


## {"blocked", "damage", "effect"} de um golpe (BossPhases).
func resolve(attack_element: String, form: String, health_now: int) -> Dictionary:
	return phases.resolve(attack_element, form, health_now)


## Depois do dano: true se trocou de fase. A troca cancela o ataque (regra 4).
func after_damage(health_now: int) -> bool:
	if not phases.after_damage(health_now):
		return false
	marks.clear()
	state = State.TRANSITION
	_events.append({"tipo": "cancelar"})
	return true


func charging() -> bool:
	return state == State.ATTACK and attack == "investida"


## Para onde o chefe está indo (o ponto do ataque ou o fim da investida).
func destination() -> Vector2:
	return _destination


## Avança `delta` segundos com o centro do mago em `player`; devolve os eventos do passo.
func tick(delta: float, player: Vector2) -> Array[Dictionary]:
	match state:
		State.START, State.REST:
			_timer -= delta
			if _timer <= EPSILON:
				_begin_next(player)
		State.TRANSITION:
			if phases.tick(delta):
				_next_attack = 0
				_begin_next(player)
		State.MOVE:
			if _fly(delta, Balance.number("chefe", "velocidade")):
				_arrive(player)
		State.WARN:
			_timer -= delta
			if _timer <= EPSILON:
				_strike(player)
		State.ATTACK:
			if attack == "investida":
				if _fly(delta, Balance.number("chefe", "investida_velocidade")):
					_rest()
			else:
				_tick_pillars(delta, player)
	var events := _events
	_events = []
	return events


## Direções do leque: uma na mira e as outras a cada `spread_degrees` para os dois lados (regra 11).
static func fan(aim: Vector2, count: int, spread_degrees: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	var center := aim.normalized() if aim != Vector2.ZERO else Vector2.RIGHT
	for i in count:
		directions.append(center.rotated(deg_to_rad(spread_degrees * (i - (count - 1) / 2.0))))
	return directions


## A posição da fase atual numa lista por fase do balanceamento, ou null.
func _for_phase(key: String) -> Variant:
	var values := Balance.list("chefe", key)
	return values[phases.phase - 1] if phases.phase - 1 < values.size() else null


func _phase_number(key: String) -> float:
	var value: Variant = _for_phase(key)
	return float(value) if value is float or value is int else 0.0


func _begin_next(player: Vector2) -> void:
	var value: Variant = _for_phase("ataques")
	var attacks: Array = value if value is Array else []
	attack = str(attacks[_next_attack % attacks.size()]) if not attacks.is_empty() else "leque"
	_next_attack += 1
	if attack == "investida":
		_destination = _farthest_charge_point(player)
	elif not points.is_empty():
		_destination = points[_next_point % points.size()]
		_next_point += 1
	else:
		_destination = position
	state = State.MOVE
	_events.append({"tipo": "mover", "ataque": attack, "destino": _destination})


func _farthest_charge_point(player: Vector2) -> Vector2:
	var best := position
	var best_distance := -1.0
	for point in charge_points:
		var distance := absf(point.x - player.x)
		if distance > best_distance:
			best = point
			best_distance = distance
	return best


## Anda até `_destination`; true ao chegar.
func _fly(delta: float, speed: float) -> bool:
	var step := speed * delta
	if position.distance_to(_destination) <= step + EPSILON:
		position = _destination
		return true
	position = position.move_toward(_destination, step)
	return false


func _arrive(player: Vector2) -> void:
	if attack == "pilares":
		# As marcas são o aviso dos pilares (regra 12).
		state = State.ATTACK
		_marks_left = int(_phase_number("pilar_marcas"))
		_timer = 0.0
		_tick_pillars(0.0, player)
		return
	state = State.WARN
	_timer = Balance.number("chefe", "investida_aviso_s" if attack == "investida" else "leque_aviso_s")
	_events.append({"tipo": "aviso", "ataque": attack})


func _strike(player: Vector2) -> void:
	if attack == "investida":
		_destination = _other_charge_point()
		state = State.ATTACK
		_events.append({"tipo": "investida", "destino": _destination})
		return
	var count := int(_phase_number("leque_orbes"))
	_events.append({"tipo": "leque",
			"direcoes": fan(player - position, count, Balance.number("chefe", "leque_abertura_graus"))})
	_rest()


func _other_charge_point() -> Vector2:
	for point in charge_points:
		if point != position:
			return point
	return position


func _tick_pillars(delta: float, player: Vector2) -> void:
	var warning := Balance.number("chefe", "pilar_aviso_s")
	var active := Balance.number("chefe", "pilar_ativo_s")
	for mark in marks.duplicate():
		mark["tempo"] += delta
		if not mark["subiu"] and mark["tempo"] >= warning - EPSILON:
			mark["subiu"] = true
			_events.append({"tipo": "pilar", "id": mark["id"]})
		if mark["tempo"] >= warning + active - EPSILON:
			marks.erase(mark)
			_events.append({"tipo": "pilar_fim", "id": mark["id"]})
	_timer -= delta
	if _marks_left > 0 and _timer <= EPSILON:
		_marks_left -= 1
		_timer += Balance.number("chefe", "pilar_intervalo_s")
		_mark_id += 1
		var mark := {"id": _mark_id, "posicao": floor_finder.call(player), "tempo": 0.0, "subiu": false}
		marks.append(mark)
		_events.append({"tipo": "marca", "id": _mark_id, "posicao": mark["posicao"]})
	if _marks_left == 0 and marks.is_empty():
		_rest()


func _rest() -> void:
	state = State.REST
	_timer = _phase_number("descanso_s")
