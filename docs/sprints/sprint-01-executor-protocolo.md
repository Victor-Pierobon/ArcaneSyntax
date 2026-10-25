# Sprint 1 — Executor: protocolo e peças

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor
- **Fase do plano:** 1 · **Marco:** M1 · **Estimativa:** 14–21 h
- **Depende de:** Sprint 0

## Objetivo

O Godot manda código Python e recebe uma lista de ações em JSON. É o maior risco técnico do projeto, por isso veio primeiro.

## Tarefas

- [x] Spike: Python embutido e latência (ver ADR-002)
- [x] ADR-001: modelo de execução
- [x] Protocolo v1 com linha em cada ação
- [x] API de peças: `lancar`, `mover`, `levitar`, `meditar`, `absorver_mana`; sentidos `mana`, `mana_max`, `vida_atual`, `alvo.elemento`, `alvo.distancia`
- [x] `print` capturado como "visão" (`saidas`)
- [x] Erros de sintaxe e execução com linha e mensagem real do Python
- [x] Cliente Godot (`PythonSpellExecutor`)
- [x] Fixtures de contrato compartilhadas
- [x] Extra: console de feitiços para testar à mão

## Resultado do spike (Windows 11, Python standalone 3.14.9)

| Modelo | Latência |
| --- | --- |
| Processo novo por feitiço | ~26 ms (mediana) |
| Worker persistente | ~0,04 ms (mediana), 0,06 ms (p95); subir o worker ~30 ms uma vez |

`OS.execute_with_pipe` do Godot funcionou com o Python standalone na primeira tentativa.

## Decisões

| Decisão | Onde |
| --- | --- |
| Snapshot do mundo + simulação local só do mago; mundo externo não muda durante a execução | ADR-001 |
| Worker persistente, JSON por linha, rodado com `-I -S -u` | ADR-002 |
| Python standalone 3.14.9 (`python-build-standalone` release `20261021`), baixado por `scripts/fetch_python.sh` para `runtime/` | ADR-002 |
| Elementos e formas são strings comuns (`fogo == "fogo"`) | EXE-pecas, regra 1 |
| Sentidos são ressincronizados a cada peça; `mana = 999` não dá mana | EXE-pecas, EXE-023 |
| Erro no meio preserva ações e saídas anteriores | EXE-protocolo, regra 5 |
| Requisição inválida responde `mago: null` | EXE-004 |
| `raise SystemExit` vira erro comum | EXE-037 (acrescentado durante a sprint) |
| Saída do worker em JSON ASCII (`ensure_ascii=True`); entrada lida como UTF-8 | `protocol.py`, `worker.py` |
| `mover(passos)` e `levitar(altura)` em tiles | EXE-pecas |
| Valores padrão: `ganho_meditar` 5, `ganho_absorver` 1 | EXE-protocolo |

## O que foi entregue

**Documentos**
- `docs/adr/ADR-001-modelo-de-execucao.md`, `docs/adr/ADR-002-processo-e-runtime-python.md`
- `docs/specs/executor/EXE-protocolo.md` (EXE-001 a 009), `EXE-pecas.md` (EXE-010 a 024), `EXE-erros.md` (EXE-030 a 037)

**Executor Python** (`executor/`)
- `arcane_executor/pieces.py`, `runner.py`, `protocol.py`, `worker.py`, `run_worker.py`

**Godot** (`game/src/executor_client/`)
- `spell_executor.gd` (interface), `python_spell_executor.gd`, `spell_request.gd`, `spell_result.gd`, `spell_error.gd`
- `game/src/nodes/dev/spell_console.gd` + `.tscn` (ferramenta de desenvolvimento)

**Contrato** (`tests/contract/`)
- `01_lancar_com_alvo`, `02_loop_de_mana`, `03_todas_as_acoes`, `04_saida_print`, `05_erro_execucao_parcial`, `06_requisicao_invalida`

**Outros**
- `scripts/fetch_python.sh`; `runtime/` no `.gitignore`
- CI: Python 3.14 nos dois jobs; job do Godot exporta `ARCANE_PYTHON`
- README com instruções do console e do `fetch_python.sh`

## Testes

| Arquivo | Testes | Cobre |
| --- | --- | --- |
| `executor/tests/test_protocolo.py` | 12 | EXE-001 a 004 |
| `executor/tests/test_pecas.py` | 21 | EXE-010 a 024 |
| `executor/tests/test_erros.py` | 8 | EXE-030 a 037 |
| `executor/tests/test_worker.py` | 2 | EXE-005, 006 (processo real) |
| `executor/tests/test_contrato.py` | 7 | EXE-009 |
| `executor/tests/test_smoke.py` | 1 | — |
| `game/tests/unit/executor_client/test_spell_contract.gd` | 7 | EXE-009 lado Godot |
| `game/tests/integration/executor/test_python_spell_executor.gd` | 6 | EXE-007, 008 (Python real) |

Totais: **51 pytest** (verdes em Python 3.15 local e 3.14 standalone) e **23 GdUnit4** (com os 10 da Sprint 0).
Teste de mutação manual: deslocar a linha das ações em +1 derrubou 10 testes pytest e 1 de integração no Godot; revertido.

## Desvios do plano

- `custo_mana` ficou fora do protocolo: entra na Sprint 2 junto com a regra de custo.
- O `FakeSpellExecutor` previsto no roadmap ainda não foi criado (nenhum sistema precisa dele ainda).

## Como verificar

- Console: `godot --path game res://src/nodes/dev/spell_console.tscn` (ou F6 com a cena aberta no editor). Só foi verificado que a cena abre sem erros; o layout não foi conferido visualmente.
- Worker na mão: `echo '{"versao":1,"id":1,"codigo":"meditar()","mundo":{"mago":{"vida":10,"mana":0,"mana_max":20},"alvo":null}}' | runtime/python/python.exe -I -S -u executor/run_worker.py`

## Limitações conhecidas (resolvidas na Sprint 2)

- Sem sandbox: `import os`, `open()` funcionam.
- Sem limites: `while True: pass` trava o worker para sempre, e a thread do Godot fica presa esperando.
- `test_EXE_006` usa `import sys` para testar escrita direta no stdout; com o sandbox, esse teste precisa mudar.
