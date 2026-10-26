extends GdUnitTestSuite
## Spec: docs/specs/combate/COM-elemental.md (regras 3 e 4, COM-020 a COM-023)

const DT := 1.0 / 60.0
## Pés no topo da linha 5 (y = 80). O chão de pedra vai da coluna 0 à 12; à direita, o vazio.
const FEET_Y := 80.0
const LEDGE := "####################\n#..................#\n#..................#\n#..................#\n#..................#\n#############.......\n"
const HALF_WIDTH := 7.0


func _free(_direction: int) -> bool:
	return true


## Simula `seconds` e devolve [menor x, maior x]. `layout` null: chão infinito.
func _simulate(brain: ElementalBrain, start: Vector2, mago: Variant, seconds: float, layout: RoomLayout = null) -> Array:
	var pos := start
	var lowest := pos.x
	var highest := pos.x
	for i in int(seconds / DT):
		var here := pos
		var ahead := _free if layout == null else func(direction: int) -> bool:
			return ElementalBrain.can_walk(layout, here, direction, HALF_WIDTH)
		pos.x += brain.velocity_x(pos, mago, ahead) * DT
		lowest = minf(lowest, pos.x)
		highest = maxf(highest, pos.x)
	return [lowest, highest]


func test_COM_020_patrulha_vai_e_volta() -> void:
	var brain := ElementalBrain.new(200.0)
	var span := _simulate(brain, Vector2(200, FEET_Y), null, 20.0)
	assert_float(span[0]).is_equal_approx(200.0 - 48.0, 1.0)
	assert_float(span[1]).is_equal_approx(200.0 + 48.0, 1.0)


func test_COM_020_velocidade_de_patrulha() -> void:
	var brain := ElementalBrain.new(200.0)
	assert_float(absf(brain.velocity_x(Vector2(200, FEET_Y), null, _free))).is_equal(30.0)


func test_COM_021_persegue_o_mago_na_mesma_altura() -> void:
	var brain := ElementalBrain.new(200.0)
	var velocity := brain.velocity_x(Vector2(200, FEET_Y), Vector2(200 - 80, FEET_Y), _free)
	assert_float(velocity).is_equal(-45.0)
	assert_bool(brain.chasing).is_true()


func test_COM_021_mago_alto_demais_nao_e_perseguido() -> void:
	var brain := ElementalBrain.new(200.0)
	var velocity := brain.velocity_x(Vector2(200, FEET_Y), Vector2(200 - 80, FEET_Y - 48), _free)
	assert_float(absf(velocity)).is_equal(30.0)
	assert_bool(brain.chasing).is_false()


func test_COM_022_nao_atravessa_parede_nem_cai() -> void:
	var layout := RoomLayout.parse(LEDGE)
	# Encostado na parede da esquerda (coluna 0).
	assert_bool(ElementalBrain.can_walk(layout, Vector2(16 + 7, FEET_Y), -1, HALF_WIDTH)).is_false()
	assert_bool(ElementalBrain.can_walk(layout, Vector2(16 + 7, FEET_Y), 1, HALF_WIDTH)).is_true()
	# No meio da coluna 12, a última com chão: à direita é o vazio.
	assert_bool(ElementalBrain.can_walk(layout, Vector2(12 * 16 + 8, FEET_Y), 1, HALF_WIDTH)).is_false()


func test_COM_022_patrulha_vira_na_beirada() -> void:
	var layout := RoomLayout.parse(LEDGE)
	var brain := ElementalBrain.new(12 * 16 - 4.0)
	var span := _simulate(brain, Vector2(12 * 16 - 4.0, FEET_Y), null, 10.0, layout)
	assert_float(span[1]).is_less_equal(12 * 16 + 9.0)
	# Virou e foi até o outro lado da patrulha.
	assert_float(span[0]).is_equal_approx(12 * 16 - 4.0 - 48.0, 1.0)


func test_COM_022_perseguindo_para_na_beirada() -> void:
	var brain := ElementalBrain.new(150.0)
	var velocity := brain.velocity_x(Vector2(200, FEET_Y), Vector2(260, FEET_Y), func(_d: int) -> bool: return false)
	assert_float(velocity).is_equal(0.0)
	assert_bool(brain.chasing).is_true()


func test_COM_023_perde_o_mago() -> void:
	var brain := ElementalBrain.new(200.0)
	brain.velocity_x(Vector2(200, FEET_Y), Vector2(260, FEET_Y), _free)
	assert_bool(brain.chasing).is_true()
	var velocity := brain.velocity_x(Vector2(200, FEET_Y), Vector2(200 + 6 * 16 + 1, FEET_Y), _free)
	assert_bool(brain.chasing).is_false()
	assert_float(absf(velocity)).is_equal(30.0)
