# Sprint 9 — Puzzles II: os 5 puzzles restantes

- **Status:** Planejada
- **Fase do plano:** 5 · **Marco:** M3 · **Estimativa:** 16–25 h
- **Depende de:** Sprint 8

## Objetivo

Os 6 puzzles da Alpha passam nos testes de aceitação e são jogáveis numa sala de teste.

## Tarefas

- [ ] Puzzle 2, variáveis: guardar valores lidos na sala para abrir um cadeado de runas (3–4 h)
- [ ] Puzzle 3, condicionais: porta que muda de símbolo (3–5 h)
- [ ] Puzzle 4, loops: ponte de 12 blocos (3–5 h)
- [ ] Puzzle 5, funções: elevador com `levitar(altura)` em alturas diferentes (4–6 h)
- [ ] Puzzle 6, revisão: combina os conceitos, com estrelas por economia de mana (3–5 h)

## Specs a escrever

Uma por puzzle (`PUZ-02` a `PUZ-06`), cada uma com pelo menos **três soluções válidas de estilos diferentes**, **duas inválidas** e os limites de mana das estrelas.

## Testes

Aceitação com essas soluções. Se alguém mudar o validador e uma solução legítima parar de passar, o CI acusa. É assim que o pilar "muitas soluções" vira teste.

## Notas

- **Peças novas no executor:** os puzzles 2, 3 e 4 vão precisar de sentidos e ações que ainda não existem (ler o valor de uma runa, o símbolo da porta, construir um bloco). Listar todas no início da sprint, atualizar `EXE-pecas` e o protocolo (campos novos, sem quebrar a v1) e só depois montar os puzzles.
- A ponte de 12 blocos é o exemplo do GDD de "bloqueio por conhecimento": 12 linhas soltas funcionam, mas custam mais mana que um loop; as estrelas mostram a diferença.

## Pronto quando

Os 6 puzzles passam nos testes de aceitação e são jogáveis.
