# UI-hud — Vida e mana na tela

- **Status:** Implementada (visual provisório)
- **Sprint:** 3
- **Relacionadas:** MUN-vida

## Contexto

O jogador precisa ver a vida e a mana o tempo todo. A mana importa ainda mais aqui do que num jogo comum, porque é o custo dos feitiços. O visual é provisório até a arte da interface.

## Regras

1. O HUD lê um `MagoState` e se atualiza pelos sinais dele, sem consultar o estado a cada quadro.
2. Vida: texto `Vida atual/máximo`. Mana: barra mais o texto `atual/máximo` com uma casa decimal.
3. Textos via `textos.csv` (`HUD_VIDA`, `HUD_MANA`, `HUD_NIVEL`).
4. Desde a Sprint 12, abaixo da barra de mana: nível e XP (PRO-niveis, regra 6).
5. **A HUD não cobre o chão** (Sprint 18): os atalhos (1 a 5) ficam no bloco do topo, abaixo do passivo; a linha de teclas fica na última faixa da tela (y ≥ 348), sobre a pedra do chão ou a moldura. Achado na Sprint 17: com as salas do tamanho da tela, os atalhos ficavam em cima dos pés do mago.

## Critérios de aceite

### UI-001 — Mostra o estado inicial

- **Dado** um `MagoState` novo ligado ao HUD
- **Então** a vida mostra `5/5` e a mana `0.0/10.0`, com a barra vazia

### UI-002 — Acompanha mudanças

- **Quando** o mago leva 2 de dano e a mana vai a 4.9
- **Então** a vida mostra `3/5`, a mana `4.9/10.0` e a barra fica em 49%

### UI-018 — A HUD não cobre o chão

- **Dado** o HUD montado
- **Então** os atalhos estão no bloco do topo (abaixo do passivo) e a linha de teclas começa em y ≥ 348

