# Sprint 2 — Executor: custo, limites e sandbox

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor · build de fumaça feito na Sprint 15 (BLD-alpha)
- **Fase do plano:** 1 · **Marco:** fecha o M1 · **Estimativa:** 15–23 h
- **Depende de:** Sprint 1

## Objetivo

O feitiço custa mana, um loop infinito falha sem travar nada, e o código do jogador não mexe no computador.

## Tarefas

- [x] Decidir a regra de custo (Victor escolheu "linhas baratas") e escrever `EXE-custo`
- [x] Contagem de instruções → custo (por instrumentação da AST, não `sys.settrace`; ver Decisões)
- [x] Custo base por peça + `custo_mana` na resposta + mana debitada do mago simulado
- [x] Limite de mana: `ManaEsgotada`
- [x] Limite de tempo no worker: `TempoEsgotado`
- [x] Watchdog no Godot
- [x] Sandbox: AST + builtins em lista branca + `getattr` protegido
- [x] Estimativa de custo: decidido que é uma execução comum com foto fictícia (EXE-custo regra 11); a Sprint 5 implementa no Godot
- [x] Fixtures, protocolo, cliente Godot e console atualizados
- [x] Extras: limite de ações e de saídas, teto de memória do worker
- [ ] Build de fumaça: **parcial**. O código já procura `executor/` e `runtime/` ao lado do `.exe` no jogo exportado (com teste), mas a exportação de verdade precisa dos templates de exportação do Godot (~1 GB), que não estão instalados

## Decisões

| Decisão | Por quê |
| --- | --- |
| Instrução simples custa 0,1, cobrada **depois** de rodar | `meditar()` com mana 0 funciona, inclusive dentro de função do jogador |
| `return/break/continue/raise` cobram **antes** | Não existe "depois" para elas |
| Estruturas (`while/if/for/try/with/match/def/class`) não custam | Fácil de explicar: custa o que roda dentro |
| Teto de mana aplicado **depois** de pagar a instrução | Sem isso, o loop de absorver ficaria preso em 2,9 de 3 para sempre |
| Mana em décimos inteiros ("gotas") | Sem erro de float; resolução de 0,1 |
| Sentidos atualizados a cada instrução (antes: a cada peça) | Consistente com o custo; `print(mana)` mostra o gasto |
| Instrumentação da AST em vez de `sys.settrace` | Mais rápida, determinística entre versões, e o erro de limite levantado num gancho comum não desliga a contagem (com `settrace`, uma exceção no tracer desliga o tracer) |
| Limites herdam de `BaseException` + `except:` e `BaseException` proibidos + gancho relança o estouro | Três camadas para o feitiço não capturar `ManaEsgotada`/`TempoEsgotado` |
| Gancho grátis `__volta__` no início de cada volta de laço | Laços sem instrução paga (`while True: if False: pass`) também param pelo tempo |
| Imports: só `math` e `random` | Suficiente para o Ato I |
| `SystemExit` fora da lista de builtins | EXE-037 atualizado: agora dá `NameError` |
| Teto de memória de 256 MB no worker (Job Object no Windows, `RLIMIT_AS` no Linux) | `"a" * 10**9` não pode travar a máquina |
| Watchdog do Godot de 3000 ms (worker: 1000 ms) | Cobre código preso em C, onde o relógio do worker não roda |

## O que foi entregue

**Specs**
- Novas: `docs/specs/executor/EXE-custo.md` (EXE-040 a 049), `EXE-limites.md` (EXE-050 a 058), `EXE-sandbox.md` (EXE-060 a 068)
- Atualizadas: `EXE-protocolo` (tabela de `regras`, `custo_mana`, tipos de erro), `EXE-pecas` (regra 3, EXE-019, EXE-023), `EXE-erros` (EXE-037)

**Executor**
- `arcane_executor/pieces.py`: contabilidade em gotas, custos, ganchos `instrucao`/`volta`, limites (`LimiteDoFeitico`, `ManaEsgotada`, `TempoEsgotado`, `LimiteExcedido`), `FeiticoProibido`
- `arcane_executor/sandbox.py` (novo): verificador da AST, builtins permitidos, `getattr`/`setattr`/`hasattr`/`delattr` protegidos, importador com lista branca
- `arcane_executor/runner.py`: parse → sandbox → instrumentação → execução
- `arcane_executor/protocol.py`: `custo_mana`
- `arcane_executor/worker.py`: teto de memória

**Godot**
- `SpellResult.cost`
- `PythonSpellExecutor`: `timeout_ms` (watchdog), pipe passado para a thread, `base_dir()` para o jogo exportado
- Console de feitiços mostra o custo

**Contrato**: fixtures 01–06 refeitas com custo; novas `07_mana_esgotada` e `08_feitico_proibido`. Os valores foram calculados à mão antes de rodar e bateram com a implementação.

## Testes

| Arquivo | Testes |
| --- | --- |
| `executor/tests/test_custo.py` (novo) | 15 |
| `executor/tests/test_limites.py` (novo) | 9 |
| `executor/tests/test_sandbox.py` (novo) | 28 (com parametrizados) |
| `executor/tests/test_worker.py` | +1 (EXE-057, processo real) |
| `game/tests/integration/executor/test_python_spell_executor.gd` | +2 (custo, EXE-058) |
| `game/tests/unit/executor_client/test_spell_contract.gd` | +1 |
| `game/tests/unit/executor_client/test_python_spell_executor_paths.gd` (novo) | 2 |

Totais: **105 pytest** (verdes em 3.15 local e 3.14 standalone) e **28 GdUnit4**.

**Teste de mutação manual** (quebrar o código e ver se algum teste falha):

| Mutação | Resultado |
| --- | --- |
| Teto aplicado antes de pagar | pego (1 falha) |
| Sem checagem de atributo interno | pego (4 falhas) |
| Saltos sem custo | **escapou** → criado `test_EXE_042_saltos_pagam_antes` → pego |
| Sem gancho de volta | pego (teste trava por timeout) |
| Limite herdando de `Exception` | escapou, porque a 2ª camada (relançar o estouro) cobre; criado teste direto da regra |

No lado Godot, os testes foram escritos antes do código, mas não rodados em vermelho antes da implementação.

## Desvios do plano

- `sys.settrace` trocado por instrumentação da AST (ver Decisões).
- Build de fumaça só na parte de código (falta exportar de verdade).
- Limites de ações (1000), de saídas (200) e de texto (500 caracteres) não estavam no plano.

## Como verificar

- Console de feitiços: experimente `while True: pass`, `import os`, `alvo.__class__`, e o feitiço de mana do GDD começando com mana 0. O painel mostra o custo.
- Testes: `docs/arquitetura.md`, seção Testes.

## Para fazer o build de fumaça (Victor)

1. No editor do Godot: **Editor → Manage Export Templates → Download and Install**.
2. **Project → Export → Add… → Windows Desktop**; exportar para uma pasta vazia, ex.: `build/ArcaneSyntax.exe`.
3. Copiar para a mesma pasta: `executor/` (só `arcane_executor/` e `run_worker.py`) e `runtime/python/`.
4. Para conjurar no build, a cena principal precisa usar o executor. Hoje só o console usa: exporte com `run/main_scene` apontando para `res://src/nodes/dev/spell_console.tscn`, ou peça para eu montar um preset de teste.
5. O `export_presets.cfg` passa a ser versionado (saiu do `.gitignore` nesta sprint).

## Limitações conhecidas

- Compreensões (`[x for x in ...]`) não pagam por volta; o tempo cobre os extremos.
- `"{0.__class__}".format(x)` lê atributos internos como texto (sem acesso a objetos).
- Um feitiço que estoura o limite dentro de um bloco `finally` pode registrar ações nesse bloco antes do gancho relançar o erro.
- Sandbox dentro do processo não segura ataque deliberado (ver modelo de ameaça em EXE-sandbox).
