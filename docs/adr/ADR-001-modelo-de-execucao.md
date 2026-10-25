# ADR-001 — Modelo de execução dos feitiços

- **Status:** Aceita
- **Data:** 2026-10-25

## Contexto

O GDD diz que o executor recebe o código e devolve uma lista de ações para o jogo animar. Mas feitiços como `while mana < mana_max: absorver_mana()` precisam ver o mundo mudar **durante** a execução.

## Opções

1. **Snapshot + simulação local.** O jogo envia uma foto do mundo; o executor roda o feitiço inteiro de uma vez, simulando dentro dele os efeitos que as peças têm sobre o próprio mago (mana). Devolve todas as ações no fim.
2. **Interativo.** O executor pausa a cada peça e pergunta ao jogo o estado atualizado.

## Decisão

Opção 1 para a Alpha.

- O executor guarda o estado real do mago (`mana`, `mana_max`, `vida`) e o atualiza quando uma peça muda algo (`meditar`, `absorver_mana`). Os sentidos do jogador (`mana`, `vida_atual`…) são sincronizados com esse estado a cada chamada de peça.
- Mudanças no **resto do mundo** (inimigo que morre, porta que abre) não são vistas durante a mesma execução. Feitiços que dependem disso (`while inimigo.vivo:`) são resolvidos executando o feitiço de novo em ciclos (slot passivo, conjuração repetida), não com o executor esperando o jogo.

## Consequências

- Executor simples, determinístico e fácil de testar: mesma entrada, mesma saída.
- A execução passo a passo dos puzzles (Sprint 8) só precisa reproduzir a lista de ações com as linhas, sem conversa com o executor.
- Se um puzzle da Alpha exigir ler o mundo mudando no meio do feitiço, reabrir esta decisão.
