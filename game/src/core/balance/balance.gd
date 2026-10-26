class_name Balance
extends RefCounted
## Os números de jogo num lugar só (spec BAL-valores): content/balanceamento.json.
## Carrega o arquivo na primeira consulta e guarda; os testes trocam de arquivo com `use_file`.

const DEFAULT_PATH := "res://content/balanceamento.json"
## Toda chave que o jogo lê, por seção (regra 5). As de LIST_KEYS são listas; o resto, número.
const KEYS := {
	"mago": ["vida", "invencivel_s"],
	"executor": [
		"ganho_meditar", "ganho_absorver", "custo_instrucao", "custo_inscricao", "custo_lancar", "custo_mover",
		"custo_levitar", "custo_meditar", "custo_absorver", "custo_inscrever", "custo_bloco", "custo_faisca",
		"limite_tempo_ms",
	],
	"dano": ["projetil", "faisca", "cajado", "contato", "fraco", "normal", "resiste"],
	"elemental": [
		"vida", "patrulha_tiles", "velocidade_patrulha", "velocidade_perseguicao", "perseguir_x_tiles",
		"perseguir_y_tiles",
	],
	"enxame": ["vida", "orbita_raio_tiles", "orbita_periodo_s", "mergulho_tiles", "velocidade", "recarga_mordida_s"],
	"guardiao": ["vida", "escudo_s", "brecha_s", "pisca_s"],
	"chefe": [
		"vida", "elementos", "troca_vida", "transicao_s", "ataque_fase1_s", "ataque_fase2_s",
		"ataque_alcance_tiles", "orbe_velocidade", "orbe_alcance_tiles", "orbe_dano",
	],
	"xp": ["elemental", "enxame", "guardiao", "chefe", "puzzle", "bonus_estrela"],
	"niveis": ["xp", "mana_max"],
}
## Chave → o que a lista tem.
const LIST_KEYS := {"chefe.elementos": "elementos", "niveis.xp": "números", "niveis.mana_max": "números"}
const BODY_ELEMENTS := ["fogo", "gelo", "raio", "planta", "pedra"]

static var _path := DEFAULT_PATH
static var _data: Dictionary = {}
static var _loaded := false
static var _errors: Array[String] = []


## Passa a ler outro arquivo (testes).
static func use_file(path: String) -> void:
	_path = path
	_load()


## Volta ao arquivo do jogo.
static func reset() -> void:
	use_file(DEFAULT_PATH)


## Problemas do arquivo carregado (vazio se está tudo certo).
static func errors() -> Array[String]:
	_ensure_loaded()
	return _errors


static func number(section: String, key: String) -> float:
	var value: Variant = _value(section, key)
	return float(value) if value is float or value is int else 0.0


static func integer(section: String, key: String) -> int:
	return int(number(section, key))


static func list(section: String, key: String) -> Array:
	var value: Variant = _value(section, key)
	return value if value is Array else []


## A seção `executor`, que vai como `regras` em toda requisição (regra 3).
static func rules() -> Dictionary:
	_ensure_loaded()
	var section: Variant = _data.get("executor", {})
	return (section as Dictionary).duplicate() if section is Dictionary else {}


## Erros de um conteúdo já lido do JSON, com o caminho de cada chave (regra 5).
static func validate(data: Variant) -> Array[String]:
	var found: Array[String] = []
	if not data is Dictionary:
		found.append("balanceamento: o arquivo precisa ser um objeto JSON")
		return found
	for section: String in KEYS:
		var values: Variant = data.get(section)
		for key: String in KEYS[section]:
			var path := "%s.%s" % [section, key]
			if not values is Dictionary or not (values as Dictionary).has(key):
				found.append("balanceamento: falta \"%s\"" % path)
				continue
			var value: Variant = values[key]
			if LIST_KEYS.has(path):
				if not _is_list_of(value, LIST_KEYS[path]):
					found.append("balanceamento: \"%s\" não é lista de %s" % [path, LIST_KEYS[path]])
			elif not (value is float or value is int):
				found.append("balanceamento: \"%s\" não é número" % path)
	# Uma posição por nível nas duas listas (PRO-niveis, regra 2).
	var levels: Variant = data.get("niveis")
	if levels is Dictionary and levels.get("xp") is Array and levels.get("mana_max") is Array \
			and (levels["xp"] as Array).size() != (levels["mana_max"] as Array).size():
		found.append("balanceamento: \"niveis.xp\" e \"niveis.mana_max\" precisam ter o mesmo tamanho")
	return found


static func _is_list_of(value: Variant, kind: String) -> bool:
	if not value is Array or (value as Array).is_empty():
		return false
	for item: Variant in value:
		if kind == "elementos" and not (item is String and item in BODY_ELEMENTS):
			return false
		if kind == "números" and not (item is float or item is int):
			return false
	return true


static func _value(section: String, key: String) -> Variant:
	_ensure_loaded()
	var values: Variant = _data.get(section)
	if values is Dictionary and (values as Dictionary).has(key):
		return values[key]
	return null


static func _ensure_loaded() -> void:
	if not _loaded:
		_load()


static func _load() -> void:
	_loaded = true
	_data = {}
	_errors = []
	var text := FileAccess.get_file_as_string(_path)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if parsed == null:
		_errors.append("balanceamento: não deu para ler %s" % _path)
	else:
		_errors = validate(parsed)
		if parsed is Dictionary:
			_data = parsed
	for error in _errors:
		push_warning(error)
