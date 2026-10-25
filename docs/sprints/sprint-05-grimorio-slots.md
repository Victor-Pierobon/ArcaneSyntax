# Sprint 5 — Grimório II: slots, erros, custo e autocompletar

- **Status:** Planejada
- **Fase do plano:** 3 · **Marco:** M2 · **Estimativa:** 15–21 h
- **Depende de:** Sprint 4; Sprint 2 (estimativa de custo)

## Objetivo

Equipar um feitiço num slot, conjurar por tecla, entender o erro e saber quanto o feitiço custa.

## Tarefas

- [ ] 5 slots + conjurar por tecla (ações `slot_1` … `slot_5`) (4–6 h)
- [ ] Painel de erros com a linha marcada no editor (3–4 h)
- [ ] Custo de mana estimado de cada feitiço (3–4 h)
- [ ] Autocompletar das peças conhecidas (5–7 h)
- [ ] Criar `game/tests/support/fake_spell_executor.gd` (1 h)

## Specs a escrever

- `docs/specs/grimorio/GRI-slots.md`: equipar, trocar, desequipar, slot vazio, conjurar envia o feitiço com o estado atual do mago.
- `docs/specs/grimorio/GRI-erros.md`: mostra `tipo: mensagem` real do Python, a linha marcada e uma frase no mundo por tipo de erro ("a runa da linha 4 está malformada"); erros do executor (`ManaEsgotada`, `TempoEsgotado`, `FeiticoProibido`) com frase própria.
- `docs/specs/grimorio/GRI-autocompletar.md`: sugere só peças desbloqueadas; inclui elementos, formas e sentidos.

## Testes

- TDD: modelo `Slots`, provedor de autocompletar (lista de peças desbloqueadas → sugestões), mapeamento de tipo de erro → frase no mundo.
- `FakeSpellExecutor` para testar o painel de erros e a conjuração sem subir Python.

## Notas

- Conjurar sempre executa; o custo real só se sabe na execução. Se a mana não basta, o executor para com `ManaEsgotada` (Sprint 2).
- Autocompletar com `CodeEdit.add_code_completion_option` + `update_code_completion_options`.
- A lista de peças desbloqueadas vai precisar chegar ao executor também (para recusar peça bloqueada). Decidir aqui se entra no protocolo.

## Pronto quando

Equipar um feitiço no slot 1, apertar a tecla e ver as ações no log; um erro marca a linha no editor.
