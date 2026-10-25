extends GdUnitTestSuite
## Spec: docs/specs/grimorio/GRI-erros.md (GRI-050) e GRI-slots.md (GRI-042)


func test_GRI_050_chave_da_frase_por_tipo() -> void:
	var table := {
		"SyntaxError": "ERRO_SINTAXE", "IndentationError": "ERRO_SINTAXE", "NameError": "ERRO_NOME",
		"TypeError": "ERRO_PECA", "ValueError": "ERRO_PECA", "AttributeError": "ERRO_PECA",
		"ZeroDivisionError": "ERRO_DIVISAO", "ManaEsgotada": "ERRO_MANA", "FeiticoProibido": "ERRO_PROIBIDO",
		"PecaBloqueada": "ERRO_BLOQUEADA", "KeyError": "ERRO_OUTRO",
	}
	for type: String in table:
		assert_str(SpellReport.phrase_key(type, true)).override_failure_message(type).is_equal(table[type])
		assert_str(SpellReport.phrase_key(type, false)).is_equal(table[type] + "_SL")
	for type in ["TempoEsgotado", "LimiteExcedido", "ExecutorIndisponivel", "RespostaInvalida"]:
		assert_str(SpellReport.phrase_key(type, true)).is_equal(SpellReport.phrase_key(type, false))


func test_GRI_050_descricao_com_linha() -> void:
	var text := SpellReport.describe_error(SpellError.make("SyntaxError", "expected ':'", 2, 9))
	assert_str(text).contains(tr("ERRO_SINTAXE") % 2)
	assert_str(text).contains("SyntaxError: expected ':'")


func test_GRI_050_descricao_sem_linha() -> void:
	var text := SpellReport.describe_error(SpellError.make("TempoEsgotado", "o feitiço passou do limite de 1000 ms"))
	assert_str(text).contains(tr("ERRO_TEMPO"))
	assert_str(text).contains("TempoEsgotado: o feitiço passou do limite de 1000 ms")


func test_texto_das_acoes() -> void:
	var fire := {"tipo": "lancar", "elemento": "fogo", "forma": "projetil", "alvo": "a1"}
	assert_str(SpellReport.action_text(fire)).is_equal("lancar fogo projetil → a1")
	var shield := {"tipo": "lancar", "elemento": "raio", "forma": "escudo", "alvo": null}
	assert_str(SpellReport.action_text(shield)).is_equal("lancar raio escudo")
	assert_str(SpellReport.action_text({"tipo": "mover", "passos": -2.0})).is_equal("mover -2")
	assert_str(SpellReport.action_text({"tipo": "levitar", "altura": 1.5})).is_equal("levitar 1.5")
	assert_str(SpellReport.action_text({"tipo": "meditar"})).is_equal("meditar")


func test_GRI_042_linhas_do_registro() -> void:
	var ok := SpellResult.from_dict({"ok": true, "custo_mana": 3.1, "mago": {"vida": 5, "mana": 1.9, "mana_max": 10},
		"acoes": [{"tipo": "lancar", "linha": 1, "elemento": "fogo", "forma": "projetil", "alvo": "a1"}],
		"saidas": [{"linha": 1, "texto": "oi"}]})
	var text := "\n".join(SpellReport.cast_lines(1, "Bola de fogo", ok))
	assert_str(text).contains("[1] Bola de fogo").contains("lancar fogo projetil → a1").contains("3.1").contains("oi")
	var failed := SpellResult.from_dict({"ok": false, "custo_mana": 0, "acoes": [], "saidas": [],
		"erro": {"tipo": "ManaEsgotada", "mensagem": "a mana acabou", "linha": 2, "coluna": null}})
	var failed_text := "\n".join(SpellReport.cast_lines(2, "Raio", failed))
	assert_str(failed_text).contains("[2] Raio").contains(tr("ERRO_MANA") % 2)
