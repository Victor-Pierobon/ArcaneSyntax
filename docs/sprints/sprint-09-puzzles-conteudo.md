# Sprint 9 — Puzzles II: os 5 puzzles restantes

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor (as specs já foram commitadas em `8e9e035`)
- **Fase do plano:** 5 · **Marco:** M3 · **Estimativa:** 16–25 h
- **Depende de:** Sprint 8

## Objetivo

Os 6 puzzles da Alpha passam nos testes de aceitação e são jogáveis numa sala de teste.

## Tarefas

- [x] Listar as peças e condições novas; escrever e atualizar as specs
- [x] Executor: custo de inscrição; `ler_runa`, `inscrever`, `construir_bloco`; `mundo.sala` no protocolo v1
- [x] Godot: condições novas, estrelas, cristal mutável, runa, cadeado, ponte, placa, gravura; levitar seguido de mover voa
- [x] Puzzle 2, variáveis: `sala_p02`
- [x] Puzzle 3, condicionais: `sala_p03`
- [x] Puzzle 4, loops: `sala_p04`, com estrelas
- [x] Puzzle 5, funções: `sala_p05`
- [x] Puzzle 6, revisão: `sala_p06`, com estrelas
- [x] `docs/feiticos-exemplo.md` com os custos novos e os Puzzles 2 a 6
- [x] Teste de mutação, captura de tela das salas, fechamento

## Decisões

| Decisão | Por quê |
| --- | --- |
| **Custo de inscrição** (Victor): a primeira vez que cada linha roda numa execução custa 0,1 a mais | Com o custo da Sprint 2, um loop e as mesmas linhas repetidas custavam igual, e as estrelas da ponte não ensinavam nada. Cobrar "na primeira vez que a linha roda", e não "tudo antes de rodar", mantém `meditar()` com mana 0 funcionando, e o passivo que confere a mana antes de agir continua de graça com a mana cheia |
| Peças novas: `ler_runa(n)` (sentido, grátis, conta a partir de 1), `inscrever(valor)` (1), `construir_bloco()` (0,5); `mundo.sala.runas` opcional | Proposta aceita pelo Victor; o protocolo continua v1, e requisições antigas dão a mesma resposta |
| Puzzle 3 usa um **cristal mutável** em vez de uma porta nova | Reaproveita o alvo; como o símbolo nunca repete, um feitiço fixo nunca acerta três vezes seguidas |
| Estrelas pela mana gasta nos feitiços **que agem**; meditar e absorver não contam | Senão o passivo de absorver pioraria as estrelas só pelo tempo parado na sala |
| Puzzle 4 também tem estrelas, além do 6 | É assim que o loop mostra a vantagem (nota original da sprint) |
| Levitar seguido de mover **voa** (MAG-070) | O elevador precisa disso: sem essa regra, o mago cai antes de chegar à plataforma |
| Alturas do elevador **5, 7 e 6** (o rascunho previa 4, 6 e 5) | Com 4, o primeiro degrau teria 3 tiles e daria para subir só pulando |
| Salas `sala_p02` a `sala_p06` em sequência depois da sala_03, geradas por script | Posição provisória até a Sprint 14; gerar por script deixou a geometria do elevador exata |

## O que foi entregue

**Specs:** EXE-custo (regra 13; critérios recalculados; EXE-090 a 094), EXE-pecas (regras 6 a 9; EXE-100 a 105), EXE-protocolo (regra 7; EXE-110, 111), EXE-desbloqueio, PUZ-validacao (regras 8 a 16; PUZ-007 a 009, 015 a 019), MUN-salas (`~`, `_`, gravura), MAG-acoes (MAG-070, 071), PUZ-02 a PUZ-06 (novas), números atualizados em PUZ-01, GRI-slots e GRI-erros.

**Executor**
- `pieces.py`: custo de inscrição (`Contexto.inscritas`), regras `custo_inscricao`, `custo_inscrever`, `custo_bloco`; peças `ler_runa`, `inscrever`, `construir_bloco`
- `runner.py` e `protocol.py`: `sala` (validação de `mundo.sala.runas`)
- Fixtures de contrato 01 a 05 e 07 recalculadas; fixture nova `10_pecas_de_puzzle.json`

**Godot**
- `src/core/puzzles/puzzle_validator.gd`: condições `cadeados_abertos`, `ponte_completa`, `placas_pisadas`; `stars()`, `counts_for_stars()`
- `src/core/puzzles/mutable_crystal_rule.gd` (novo)
- `src/core/world/room_layout.gd`: `bridge_cells` (`~`), `plates` (`_`)
- `src/nodes/puzzles/rune.gd`, `rune_lock.gd`, `bridge.gd`, `pressure_plate.gd` (novos); `crystal.gd` com o cristal mutável
- `src/nodes/world/room.gd`: mecanismos novos, gravuras, `spell_room()`, `inscribe()`, `build_block()`, `engravings()`; `rng` vindo do `World`
- `src/nodes/world/world.gd`: `rng`, sala no contexto do feitiço, `room_mana_spent`, `puzzle_stars()`, mensagem de puzzle resolvido com estrelas
- `src/nodes/magic/action_player.gd`: ações novas; avisa ao levitar qual é a próxima ação
- `src/nodes/magic/world_actions.gd`: `act_inscrever`, `act_construir_bloco`, voo de levitar + mover
- `src/executor_client/spell_request.gd`: `room` → `mundo.sala`; `grimoire_ui.gd` manda a sala no Testar e na estimativa
- `mago_state.gd`, `completion_provider.gd`, `python_highlighter.gd`: peças novas
- `content/rooms/sala_p02..p06.tscn` (novas); `sala_03.tscn` com a saída para a `sala_p02`; `textos.csv` com 6 textos novos
- `game/node_2d.tscn` apagado (cena vazia criada por engano, a pedido do Victor)

## Testes

| Arquivo | Testes |
| --- | --- |
| `executor/tests/test_custo.py` | 9 recalculados, +5 (EXE-090 a 094) |
| `executor/tests/test_pecas_puzzle.py` (novo) | 9 |
| `executor/tests/test_desbloqueio.py` | +2; 1 recalculado |
| `executor/tests/test_pecas.py`, `test_protocolo.py` | números recalculados |
| `tests/unit/puzzles/test_puzzle_validator.gd` | +4 |
| `tests/unit/puzzles/test_mutable_crystal_rule.gd` (novo) | 6 |
| `tests/unit/world/test_room_layout.gd` | +1 |
| `tests/unit/magic/test_action_player.gd` | +2 |
| `tests/unit/executor_client/test_spell_contract.gd` | +2 |
| `tests/scene/puzzles/test_puzzle_mechanisms.gd` (novo) | 12 |
| `tests/scene/magic/test_world_actions.gd` | +2 (MAG-070) |
| `tests/acceptance/test_puzzle_02.gd` a `test_puzzle_06.gd` (novos; Python real, salas do jogo) | 7 + 8 + 6 + 6 + 7 |

Cada puzzle tem pelo menos três soluções válidas de estilos diferentes e duas inválidas.

Totais: **265 GdUnit4** e **131 pytest**, todos verdes. O pytest também passou com o Python 3.14 do runtime.

**Teste de mutação:** 12 mutações. Na primeira rodada, 10 foram pegas. "Erro no cristal mutável não zera" sobreviveu só porque a rodada usou o teste de aceitação; o teste de unidade PUZ-008 pega essa mutação. "Placa pisada no ar" revelou um teste fraco: faltava conferir que a placa só conta com o mago no chão, e o teste foi criado. Na segunda rodada, as 12 foram pegas.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| As placas eram numeradas na ordem de leitura do layout (de cima para baixo), não da esquerda para a direita como as runas | Teste de aceitação do Puzzle 5 (solução X) | `test_PUZ_016_placas_numeradas_da_esquerda_para_a_direita` (vermelho → verde) |
| As alturas do elevador não estavam gravadas na sala: o jogador teria que adivinhar | Captura de tela | `test_PUZ_060_as_alturas_estao_gravadas`, `test_PUZ_070_as_alturas_estao_gravadas` (vermelho → verde; gravuras novas, PUZ-validacao regra 16) |

**Teste fraco (não era bug):** placa pisada no ar, achado pela mutação. Teste: `test_PUZ_016_placa_nao_conta_com_o_mago_no_ar`.

**Nota de processo:** os testes de unidade do validador, do layout e do cristal mutável foram escritos no mesmo passo que o código, então não cheguei a vê-los falhar antes. A mutação cobre essas regras.

## Como verificar

Siga a seção "4c. Puzzles 2 a 6" de `docs/feiticos-exemplo.md`. As salas ficam depois da sala_03: desça até o fundo dela e saia pela direita. Conjure `meditar()` antes de cada puzzle, ou ligue o passivo do exemplo 2.1.

## Mudanças que afetam o jogo

- **Todo feitiço ficou um pouco mais caro.** `meditar()` com mana 0 deixa 4,8 (era 4,9) e `lancar` custa 3,2 (era 3,1). As três soluções do Puzzle 1 continuam passando.
- `levitar(...)` seguido de `mover(...)` agora voa na horizontal. Em salas futuras, isso pode abrir atalhos (pergunta em aberto no PUZ-05).
- A sala_03 ganhou uma saída à direita, no fundo, que leva aos puzzles.

## Limitações conhecidas

- Puzzles e estrelas não são gravados em disco: fechar o jogo recomeça tudo (Sprint 13).
- Os limites das estrelas do Puzzle 6 (20 e 24) são provisórios e precisam de calibração no playtest.
- As estrelas aparecem só como uma linha no registro de conjuração; não há tela de resultado.
- Um loop que lança três vezes no cristal mutável falha por causa do ADR-001, e isso pode frustrar. A explicação da serpente fica para a Sprint 13.
