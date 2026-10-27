extends GdUnitTestSuite
## Spec: docs/specs/mundo/MUN-salas.md (regra 9, MUN-110)


func _map(text: String, solved := true) -> WalkMap:
	return WalkMap.new(RoomLayout.parse(text), solved)


func test_MUN_110_degrau_de_2_sim_de_3_nao() -> void:
	var two := _map("""##########
#........#
#........#
#........#
#....#####
#....#####
##########""")
	# Chão: pés na linha 5. Bloco de 2: pés na linha 3.
	assert_bool(two.reach(Vector2i(1, 5)).has(Vector2i(6, 3))).override_failure_message("degrau de 2").is_true()
	var three := _map("""##########
#........#
#........#
#....#####
#....#####
#....#####
##########""")
	assert_bool(three.reach(Vector2i(1, 5)).has(Vector2i(6, 2))).override_failure_message("degrau de 3").is_false()
	# Descer sempre alcança.
	assert_bool(three.reach(Vector2i(6, 2)).has(Vector2i(1, 5))).is_true()


func test_MUN_110_vao_de_4_sim_de_5_nao() -> void:
	var map := _map("""#####################
#...................#
#...................#
#...................#
###^^^^####^^^^^#####
#####################""")
	var reach := map.reach(Vector2i(1, 3))
	assert_bool(reach.has(Vector2i(7, 3))).override_failure_message("vão de 4").is_true()
	assert_bool(reach.has(Vector2i(16, 3))).override_failure_message("vão de 5").is_false()


func test_MUN_110_espinho_nao_e_chao_e_queda_nele_para() -> void:
	var map := _map("""############
#..........#
#..........#
#..........#
###^^^^^^###
############""")
	var reach := map.reach(Vector2i(1, 3))
	assert_bool(reach.has(Vector2i(5, 3))).is_false()
	assert_bool(reach.has(Vector2i(10, 3))).is_false()


func test_MUN_110_plataformas_novas() -> void:
	var map := _map("""######################
#....................#
#....................#
#..+.................#
#....................#
#....................#
#....................#
#..>>.......>>>.....+#
#....................#
#....................#
#......---...........#
#....................#
###..................#
######################""")
	# A que cai é chão.
	assert_bool(map.standable(Vector2i(7, 9))).is_true()
	# O caminho inteiro da horizontal é chão (de 12 a 20 na linha 7: pés na linha 6).
	assert_bool(map.standable(Vector2i(18, 6))).is_true()
	# As pontas da vertical são chão e ligadas.
	assert_bool(map.standable(Vector2i(3, 6))).is_true()
	assert_bool(map.standable(Vector2i(3, 2))).is_true()
	assert_bool(map.reach(Vector2i(3, 6)).has(Vector2i(3, 2))).is_true()
	assert_bool(map.reach(Vector2i(3, 2)).has(Vector2i(3, 6))).is_true()


func test_MUN_110_porta_fechada_e_ponte() -> void:
	var text := """##############
#.......|....#
#.......|....#
#.......|....#
###~~~~#######
##############"""
	var closed := _map(text, false)
	assert_bool(closed.reach(Vector2i(1, 3)).has(Vector2i(10, 3))).is_false()
	# Resolvido: a porta abre e a ponte está construída.
	var open := _map(text, true)
	assert_bool(open.reach(Vector2i(1, 3)).has(Vector2i(10, 3))).is_true()
	assert_bool(open.standable(Vector2i(4, 3))).is_true()


func test_MUN_110_parede_no_caminho_bloqueia_o_pulo() -> void:
	var map := _map("""##########
#...#....#
#...#....#
#...#....#
#...#....#
##########""")
	assert_bool(map.reach(Vector2i(2, 4)).has(Vector2i(6, 4))).is_false()


func test_MUN_110_cabeca_precisa_de_espaco() -> void:
	var map := _map("""########
####...#
#......#
########""")
	# Pés na linha 2, cabeça na 1: na coluna 1 a cabeça bate na pedra.
	assert_bool(map.standable(Vector2i(1, 2))).is_false()
	assert_bool(map.standable(Vector2i(5, 2))).is_true()
