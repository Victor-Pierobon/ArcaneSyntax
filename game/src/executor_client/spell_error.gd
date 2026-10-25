class_name SpellError
extends RefCounted
## Erro de um feitiço com a mensagem real do Python (spec EXE-erros).

## Linha ou coluna ausente (null no JSON).
const NO_POSITION := -1

var type: String
var message: String
var line: int = NO_POSITION
var column: int = NO_POSITION


static func make(p_type: String, p_message: String, p_line: int = NO_POSITION, p_column: int = NO_POSITION) -> SpellError:
	var error := SpellError.new()
	error.type = p_type
	error.message = p_message
	error.line = p_line
	error.column = p_column
	return error


static func from_dict(data: Dictionary) -> SpellError:
	return make(
		str(data.get("tipo", "")),
		str(data.get("mensagem", "")),
		_position(data.get("linha")),
		_position(data.get("coluna")),
	)


static func _position(value: Variant) -> int:
	return NO_POSITION if value == null else int(value)


func to_dict() -> Dictionary:
	return {
		"tipo": type,
		"mensagem": message,
		"linha": null if line == NO_POSITION else line,
		"coluna": null if column == NO_POSITION else column,
	}
