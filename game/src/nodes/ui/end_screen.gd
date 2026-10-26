class_name EndScreen
extends MenuPanel
## Tela de fim da demonstração (spec UI-menus, regra 7): o resumo do jogo; Enter volta ao menu inicial.

signal done

var summary_label: Label
var back_button: Button


func _init() -> void:
	super._init()
	title_label.text = "FIM_TITULO"
	summary_label = add_label("", 10)
	back_button = add_button("FIM_VOLTAR")
	back_button.pressed.connect(confirm)


func show_summary(summary: Dictionary) -> void:
	summary_label.text = "\n".join([
		tr("FIM_NIVEL") % [summary["nivel"], summary["xp"]],
		tr("FIM_PUZZLES") % [summary["puzzles"], summary["puzzles_total"]],
		tr("FIM_ESTRELAS") % summary["estrelas"],
		tr("FIM_LICOES") % [summary["licoes"], summary["licoes_total"]],
		tr("FIM_SEGREDOS") % [summary["segredos"], summary["segredos_total"]],
	])
	show_panel()


func summary_text() -> String:
	return summary_label.text


func confirm() -> void:
	if not is_showing():
		return
	hide_panel()
	done.emit()
