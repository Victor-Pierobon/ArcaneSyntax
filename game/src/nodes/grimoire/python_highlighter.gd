class_name PythonHighlighter
extends RefCounted
## Realce de Python para o editor do grimório (spec GRI-grimorio, regra 7).

const KEYWORDS := [
	"False", "None", "True", "and", "as", "assert", "async", "await", "break", "case", "class",
	"continue", "def", "del", "elif", "else", "except", "finally", "for", "from", "global", "if",
	"import", "in", "is", "lambda", "match", "nonlocal", "not", "or", "pass", "raise", "return",
	"try", "while", "with", "yield",
]
const BUILTINS := [
	"abs", "all", "any", "bool", "dict", "enumerate", "float", "int", "isinstance", "len", "list",
	"max", "min", "print", "range", "reversed", "round", "set", "sorted", "str", "sum", "tuple", "zip",
]
## Vocabulário do jogo (spec EXE-pecas): peças, elementos, formas e sentidos.
const GAME_WORDS := [
	"lancar", "mover", "levitar", "meditar", "absorver_mana", "inscrever", "construir_bloco",
	"fogo", "gelo", "raio", "projetil", "escudo",
	"mana", "mana_max", "vida_atual", "alvo", "ler_runa",
]

const COLOR_TEXT := Color("d8d4e8")
const COLOR_KEYWORD := Color("c792ea")
const COLOR_BUILTIN := Color("82aaff")
const COLOR_GAME := Color("ffcb6b")
const COLOR_STRING := Color("c3e88d")
const COLOR_COMMENT := Color("7a7690")
const COLOR_NUMBER := Color("f78c6c")
const COLOR_SYMBOL := Color("89ddff")


static func build() -> CodeHighlighter:
	var highlighter := CodeHighlighter.new()
	highlighter.number_color = COLOR_NUMBER
	highlighter.symbol_color = COLOR_SYMBOL
	highlighter.function_color = COLOR_TEXT
	highlighter.member_variable_color = COLOR_TEXT
	for word in KEYWORDS:
		highlighter.add_keyword_color(word, COLOR_KEYWORD)
	for word in BUILTINS:
		highlighter.add_keyword_color(word, COLOR_BUILTIN)
	for word in GAME_WORDS:
		highlighter.add_keyword_color(word, COLOR_GAME)
	highlighter.add_color_region("#", "", COLOR_COMMENT, true)
	highlighter.add_color_region("\"", "\"", COLOR_STRING)
	highlighter.add_color_region("'", "'", COLOR_STRING)
	return highlighter
