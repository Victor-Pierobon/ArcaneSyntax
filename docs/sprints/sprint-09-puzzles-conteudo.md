# Sprint 9 — Puzzles II: os 5 puzzles restantes

- **Status:** Em andamento (specs em revisão pelo Victor)
- **Fase do plano:** 5 · **Marco:** M3 · **Estimativa:** 16–25 h
- **Depende de:** Sprint 8

## Objetivo

Os 6 puzzles da Alpha passam nos testes de aceitação e são jogáveis numa sala de teste.

## Decisões do início da sprint (2026-10-25)

- **Custo de inscrição** (Victor): a primeira passagem por cada linha paga 0,1 a mais, para o loop custar menos que as mesmas linhas repetidas. Sem isso, as estrelas da ponte não separam o loop das 12 linhas, porque com o custo da Sprint 2 os dois davam o mesmo valor. A regra é cobrar "na primeira vez que a linha roda", e não "tudo antes de rodar", para que `meditar()` com mana 0 continue funcionando.
- **Peças e condições** (proposta aceita pelo Victor): `ler_runa(n)`, `inscrever(valor)`, `construir_bloco()`, `mundo.sala.runas` no protocolo v1; cristal mutável, runa, cadeado, vão `~` e placa `_`; condições `cadeados_abertos`, `ponte_completa`, `placas_pisadas`; estrelas por mana gasta nos feitiços que agem.
- **Levitar seguido de mover voa** (MAG-070), necessário para o elevador.
- **Salas:** `sala_p02` a `sala_p06`, em sequência depois da sala_03 (posição provisória até a Sprint 14).

## Specs

| Spec | O quê | IDs |
| --- | --- | --- |
| EXE-custo (regra 13) | custo de inscrição; critérios antigos recalculados | EXE-040 a 049 (recalculados), EXE-090 a 094 |
| EXE-pecas (regras 6 a 9) | `ler_runa`, `inscrever`, `construir_bloco` | EXE-023 (recalculado), EXE-100 a 105 |
| EXE-protocolo (regra 7) | `mundo.sala`, regras novas | EXE-110, EXE-111 |
| EXE-desbloqueio | peças novas na lista | — |
| PUZ-validacao (regras 8 a 15) | mecanismos, condições, estrelas | PUZ-007 a 009, PUZ-015 a 019 |
| MUN-salas | legenda `~` e `_` | — |
| MAG-acoes | levitar + mover; ações novas no mundo | MAG-070, MAG-071 |
| PUZ-02-runas | variáveis | PUZ-030 a 032 |
| PUZ-03-simbolo | condicionais | PUZ-040, 041 |
| PUZ-04-ponte | loops (com estrelas) | PUZ-050, 051 |
| PUZ-05-elevador | funções | PUZ-060, 061 |
| PUZ-06-revisao | revisão, com estrelas | PUZ-070 a 072 |

## Tarefas

- [x] Listar as peças e condições novas; escrever e atualizar as specs
- [ ] Revisão das specs pelo Victor
- [ ] Executor: custo de inscrição (EXE-090 a 094), recalcular os testes e fixtures afetados
- [ ] Executor: `ler_runa`, `inscrever`, `construir_bloco`, `mundo.sala` (EXE-100 a 111), fixture `10_pecas_de_puzzle.json`
- [ ] Godot: `SpellRequest` com `sala`; `PuzzleValidator` com as condições novas; estrelas (PUZ-007, 017)
- [ ] Godot: cristal mutável, runa, cadeado, ponte e placa (PUZ-008, 009, 015, 016, 018, 019); `WorldActions` (MAG-070, 071); autocompletar e realce das peças novas
- [ ] Puzzle 2, variáveis: `sala_p02` + aceitação (3–4 h)
- [ ] Puzzle 3, condicionais: `sala_p03` + aceitação (3–5 h)
- [ ] Puzzle 4, loops: `sala_p04` + aceitação (3–5 h)
- [ ] Puzzle 5, funções: `sala_p05` + aceitação (4–6 h)
- [ ] Puzzle 6, revisão: `sala_p06` + aceitação (3–5 h)
- [ ] Atualizar `docs/feiticos-exemplo.md` com os custos novos e as seções dos Puzzles 2 a 6
- [ ] Teste de mutação, captura de tela das salas, fechamento (relatório, diário, roadmap, arquitetura, handoff)

## Afetados pelo custo de inscrição (recalcular)

Fixtures `tests/contract/01` a `09` (`custo_mana` e `mago.mana`); testes de custo e de peças do pytest; testes do Godot que comparam mana ou custo estimado; `docs/feiticos-exemplo.md`; números em GRI-slots, GRI-erros, MUN-vida e UI-hud. Os testes vão apontar o resto.

## Testes

Aceitação com as soluções das specs PUZ-02 a PUZ-06: pelo menos três válidas, de estilos diferentes, e duas inválidas por puzzle. Se alguém mudar o validador e uma solução legítima parar de passar, o CI acusa. É assim que o pilar "muitas soluções" vira teste.

## Pronto quando

Os 6 puzzles passam nos testes de aceitação e são jogáveis.
