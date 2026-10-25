# Sprint 5 — Grimório II: slots, erros, custo e autocompletar

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor
- **Fase do plano:** 3 · **Marco:** M2 · **Estimativa:** 15–21 h
- **Depende de:** Sprint 4; Sprint 2

## Objetivo

Equipar um feitiço num slot, conjurar por tecla, entender o erro e saber quanto o feitiço custa.

## Tarefas

- [x] 5 slots + conjurar por tecla (1–5)
- [x] Painel de erros com a linha marcada no editor (+ botão **Testar**)
- [x] Custo de mana estimado
- [x] Autocompletar das peças conhecidas
- [x] `FakeSpellExecutor` em `tests/support/`
- [x] Extra: **peças bloqueadas no executor** (decisão abaixo)
- [x] Extra: **bonecos de treino** como `alvo` (sem eles não dava para testar `lancar(..., alvo)` nem o feitiço adaptável)
- [x] Extra: **registro de conjuração** na tela (as ações ainda não acontecem no mundo)

## Decisões

| Decisão | Por quê |
| --- | --- |
| **O executor recusa peças bloqueadas** (`pecas` na requisição; sem o campo, tudo liberado) | Peças são os upgrades do metroidvania; esconder só no autocompletar furaria a progressão. Opção recomendada; o Victor seguiu para a sprint sem se opor |
| Verificação dupla: nomes no código (antes de rodar) + texto em `lancar` (durante) | Pega `lancar(raio, …)` e também `lancar(alvo.elemento, …)` com elemento bloqueado |
| Todas as peças começam desbloqueadas (`MagoState.unlocked_pieces`) | A progressão é da Sprint 12; o mecanismo já está ligado |
| Mana aplicada pela **variação** (`final − enviada`) | Duas conjurações ou passivo + conjuração não apagam uma à outra (era nota da Sprint 7, antecipada) |
| Slots no mesmo arquivo do grimório (`"slots"`), sem mudar a `versao` | Campo opcional; arquivos antigos continuam válidos |
| Mesmo feitiço pode ocupar mais de um slot | Sem motivo para proibir |
| **Testar** usa o estado real, mas não gasta mana nem muda o mundo | Depurar sem punição |
| Custo estimado: mana 1000/1000 + alvo de fogo; recalcula 0,5 s depois de parar de digitar | Spec EXE-custo regra 11; não executa a cada tecla |
| Alvo = boneco mais próximo num raio de 12 tiles; distância em tiles | Mesmo mecanismo vai servir para os inimigos (grupo `alvos`) |
| Frases no mundo para cada tipo de erro, sempre junto do erro real do Python | GDD: aprender a ler o erro de verdade |

## O que foi entregue

**Specs**: `EXE-desbloqueio` (EXE-080 a 085), `MUN-alvos` (MUN-040 a 043), `GRI-slots` (GRI-030 a 034, 040 a 045), `GRI-erros` (GRI-050 a 053, 060 a 062), `GRI-autocompletar` (GRI-070 a 074); `EXE-protocolo` atualizada (`pecas`, `PecaBloqueada`).

**Executor**: `pieces.py` (`PECAS_DESBLOQUEAVEIS`, `PecaBloqueada`, checagem em `lancar`), `sandbox.py` (`verificar_pecas`, `Violacao.tipo`), `runner.py` e `protocol.py` (campo `pecas`). Fixture `09_peca_bloqueada`.

**Godot**
- `src/core/grimoire/grimoire.gd` — slots (`equip`, `unequip`, `slot`, `slots`, `slots_changed`, `Problem.INVALID_SLOT`)
- `src/core/grimoire/spell_report.gd` — frases de erro, texto das ações, linhas do registro e do painel
- `src/core/grimoire/completion_provider.gd` — sugestões
- `src/core/mago/mago_state.gd` — `ALL_PIECES`, `unlocked_pieces`
- `src/core/world/room_layout.gd` — dígitos `1`–`9` = bonecos
- `src/executor_client/spell_request.gd` — `pieces`
- `src/nodes/world/training_target.gd` (novo), `room.gd` (`targets`), `world.gd` (`cast`, `current_target`, `spell_context`, `executor`, `spell_cast`), `world.tscn` (nós `Executor` e `CastLog`)
- `src/nodes/grimoire/grimoire_ui.gd` — botões de slot, Testar, painel com rolagem, linha marcada, custo estimado, autocompletar
- `src/nodes/ui/hud.gd` — barra de slots; `src/nodes/ui/cast_log.gd` (novo)
- `project.godot`: ações `slot_1` … `slot_5`; `textos.csv`: frases de erro, textos do grimório e do registro
- Salas: bonecos de fogo, planta e raio na sala_01; de gelo na sala_02
- `docs/feiticos-exemplo.md` atualizado para testar no jogo

## Testes

| Arquivo | Testes |
| --- | --- |
| `executor/tests/test_desbloqueio.py` (novo) | 8 |
| `executor/tests/test_contrato.py` | +1 fixture |
| `tests/unit/grimoire/test_grimoire_slots.gd` (novo) | 5 |
| `tests/unit/grimoire/test_spell_report.gd` (novo) | 5 |
| `tests/unit/grimoire/test_completion_provider.gd` (novo) | 4 |
| `tests/unit/world/test_room_layout.gd` | +1 |
| `tests/unit/executor_client/test_spell_contract.gd` | +1 |
| `tests/scene/grimoire/test_grimoire_ui.gd` | +9 |
| `tests/scene/world/test_casting.gd` (novo, com `FakeSpellExecutor` e 1 com Python real) | 8 |
| `tests/scene/world/test_targets.gd` (novo) | 3 |
| `tests/scene/ui/test_hud.gd` | +1 |

Totais: **114 pytest** e **132 GdUnit4**, todos verdes.

**Teste de mutação** (todas pegas): mana absoluta em vez de variação, conjurar com o jogo pausado, autocompletar sugerindo peça bloqueada, slot sem acompanhar o renomear, alvo sem limite de alcance.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| A linha do custo ficava cortada no painel de resultado do grimório | Captura de tela | `test_GRI_051_painel_mostra_todas_as_linhas_do_resultado` (vermelho → verde; painel agora rola) |

Erros de compilação e de teste no caminho (não eram bugs do jogo): `PackedStringArray([...])` não é aceito como constante em GDScript (virou `Array[String]`); não dá para guardar uma corrotina numa variável e esperar depois (o teste passou a esperar o sinal `spell_cast`).

## Como verificar

Siga `docs/feiticos-exemplo.md`, seção "Onde testar": Tab → Novo → cole um feitiço → botão 1 → Esc → tecla 1. Comece com o 2.1 (recarga), porque o jogo começa com mana 0. Na sala_01, ande entre os bonecos e conjure o feitiço adaptável (3.2) para ver o elemento mudar.

## Limitações conhecidas

- As ações aparecem só no registro; acontecem no mundo na Sprint 6.
- A estimativa de custo supõe um alvo de fogo; com outro alvo, o custo real pode ser diferente (o texto avisa).
- O autocompletar não foi testado com teclado de verdade (headless não entrega teclas): os testes cobrem o provedor e a ligação do editor; vale conferir digitando.
- Uma função do jogador com o nome de uma peça bloqueada também é recusada (EXE-desbloqueio, regra 7).
