class_name SpellReport
extends RefCounted
## Transforma resultados do executor em texto para o jogador (specs GRI-erros e GRI-slots).

## Tipo de erro → chave base em textos.csv. Chaves com "_SL" são a versão sem número de linha.
const PHRASES := {
	"SyntaxError": "ERRO_SINTAXE",
	"IndentationError": "ERRO_SINTAXE",
	"NameError": "ERRO_NOME",
	"TypeError": "ERRO_PECA",
	"ValueError": "ERRO_PECA",
	"AttributeError": "ERRO_PECA",
	"ZeroDivisionError": "ERRO_DIVISAO",
	"ManaEsgotada": "ERRO_MANA",
	"FeiticoProibido": "ERRO_PROIBIDO",
	"PecaBloqueada": "ERRO_BLOQUEADA",
}
## Erros que nunca têm linha: uma frase só.
const PHRASES_WITHOUT_LINE := {
	"TempoEsgotado": "ERRO_TEMPO",
	"LimiteExcedido": "ERRO_LIMITE",
	"ExecutorIndisponivel": "ERRO_EXECUTOR",
	"RespostaInvalida": "ERRO_EXECUTOR",
}
const MAX_ACTIONS_IN_LINE := 4


static func phrase_key(type: String, has_line: bool) -> String:
	if PHRASES_WITHOUT_LINE.has(type):
		return PHRASES_WITHOUT_LINE[type]
	var key: String = PHRASES.get(type, "ERRO_OUTRO")
	return key if has_line else key + "_SL"


## Frase no mundo + linha com o erro real do Python (GRI-050).
static func describe_error(error: SpellError) -> String:
	var has_line := error.line != SpellError.NO_POSITION
	var key := phrase_key(error.type, has_line)
	var phrase := TranslationServer.translate(key)
	if has_line and not PHRASES_WITHOUT_LINE.has(error.type):
		phrase = phrase % error.line
	var detail := "%s: %s" % [error.type, error.message]
	if has_line:
		detail = TranslationServer.translate("ERRO_DETALHE_LINHA") % [detail, error.line]
	return "%s\n%s" % [phrase, detail]


static func action_text(action: Dictionary) -> String:
	match action.get("tipo", ""):
		"lancar":
			var text := "lancar %s %s" % [action.get("elemento", "?"), action.get("forma", "?")]
			if action.get("alvo") != null:
				text += " → %s" % action["alvo"]
			return text
		"mover":
			return "mover %s" % _number(action.get("passos", 0))
		"levitar":
			return "levitar %s" % _number(action.get("altura", 0))
		var other:
			return str(other)


## Linhas do registro de conjuração para um slot (GRI-042).
static func cast_lines(slot_number: int, spell_name: String, result: SpellResult) -> PackedStringArray:
	var head := "[%d] %s" % [slot_number, spell_name]
	var lines := PackedStringArray()
	for output in result.outputs:
		lines.append("%s · %s %s" % [head, TranslationServer.translate("REGISTRO_VISAO"), output["texto"]])
	var actions := PackedStringArray()
	for action in result.actions.slice(0, MAX_ACTIONS_IN_LINE):
		actions.append(action_text(action))
	if result.actions.size() > MAX_ACTIONS_IN_LINE:
		actions.append("… (+%d)" % (result.actions.size() - MAX_ACTIONS_IN_LINE))
	var cost := TranslationServer.translate("REGISTRO_CUSTO") % _number(result.cost)
	if result.error:
		var description := describe_error(result.error).split("\n")
		lines.append("%s · %s" % [head, description[0]])
		lines.append("    %s" % description[1])
	elif actions.is_empty():
		lines.append("%s · %s · %s" % [head, TranslationServer.translate("REGISTRO_SEM_ACOES"), cost])
	else:
		lines.append("%s · %s · %s" % [head, ", ".join(actions), cost])
	return lines


## Resultado completo para o painel do grimório (GRI-051).
static func full_text(result: SpellResult) -> String:
	var parts := PackedStringArray()
	if result.error:
		parts.append(describe_error(result.error))
	for output in result.outputs:
		parts.append("%s %s" % [TranslationServer.translate("REGISTRO_VISAO"), output["texto"]])
	for action in result.actions.slice(0, 12):
		parts.append("· linha %d: %s" % [action["linha"], action_text(action)])
	if result.actions.size() > 12:
		parts.append("· … (+%d)" % (result.actions.size() - 12))
	parts.append(TranslationServer.translate("REGISTRO_CUSTO") % _number(result.cost))
	return "\n".join(parts)


static func _number(value: Variant) -> String:
	var number := float(value)
	return str(int(number)) if is_equal_approx(number, roundf(number)) else str(snappedf(number, 0.1))
