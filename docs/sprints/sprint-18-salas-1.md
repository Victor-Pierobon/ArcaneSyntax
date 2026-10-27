# Sprint 18 — Salas I: começo e puzzles

- **Status:** Concluída em 2026-10-27 · aguardando revisão e commit
- **Plano:** Alpha 1.1 (`docs/plano-alpha-1-1.md`) · **Estimativa:** 18–26 h (+4 a 6 h das plataformas novas)
- **Depende de:** Sprint 17 (commitada, `d8d36e6`)

## Objetivo

As oito primeiras salas (`sala_01` a `03` e `sala_p02` a `p06`) deixam de ser corredores baixos: ficam pelo menos do tamanho da tela, usam a altura, têm plataformas, perigos, inimigos no caminho e segredos novos. Os puzzles continuam os mesmos (mesmo conceito, mesmo validador, mesma aceitação com Python real); muda a sala em volta e o caminho até eles. Entram a plataforma que se move e a que cai (decisão do Victor, 2026-10-27).

## Tarefas

- [x] Spec `MUN-plataformas` (nova); `MUN-salas` (legenda, tamanho, alcance a pé); `MUN-segredos` (segredos novos); `UI-hud` (a HUD não cobre o chão)
- [x] `PlatformPath` e `FallingPlatformRule` (regras puras), TDD; `RoomLayout` lê `-`, `>` e `+`
- [x] Nós `MovingPlatform` e `FallingPlatform`; a `Room` monta; cenas MUN-103 a MUN-105
- [x] `WalkMap` (regra pura): alcance a pé com o pulo de verdade, para pegar degrau alto e sala sem volta
- [x] HUD: atalhos no bloco do topo, linha de teclas no fundo da tela
- [x] As oito salas refeitas (geradas por script, como as da Sprint 14), com tochas
- [x] Aceitação de cada puzzle, dos segredos (velhos e novos, dois caminhos cada), `AreaMap` e Alpha inteira (MUN-085) de novo
- [x] Teste de mutação, captura de tela de todas as salas, fechamento

## Decisões (por recomendação; o Victor revisa)

| Decisão | Por quê |
| --- | --- |
| Plataforma que se move: `>` e um `+` no outro extremo, no próprio layout | O caminho fica visível no texto da sala, como o resto; sem dicionário extra na cena |
| Velocidades e tempos das plataformas nas classes, não no balanceamento | São sensação (como o pulo), e a BAL-valores deixa sensação de fora |
| A HUD sai do chão: atalhos no bloco do topo, linha de teclas na última faixa da tela | Com as salas do tamanho da tela, os atalhos ficavam em cima dos pés do mago (achado na Sprint 17) |
| Segredos: de 2 para 5 (novos na `sala_01`, `sala_p03` e `sala_p06`), cada um com um caminho com feitiço e um só com movimento | Plano da 1.1 e regra do Victor da Sprint 14 |
| Inimigos no caminho só nos corredores (`sala_02`, `sala_03`) e na chegada da `sala_p03`, longe da área do puzzle | O puzzle pede calma para escrever código; os inimigos ficam na travessia |
| Verificação de alcance a pé (`WalkMap`) com limites um pouco abaixo do pulo real | O `AreaMap` não tem gravidade e não pega degrau alto demais; a física de verdade fica para a aceitação |

## O que foi entregue

**Specs:** MUN-plataformas (nova, regras 1 a 12, MUN-100 a MUN-105); MUN-salas (legenda `-`, `>`, `+`; regras 9 e 10, MUN-110 e MUN-111); MUN-segredos (MUN-096 a MUN-098); UI-hud (regra 5, UI-018).

**Godot**
- `RoomLayout` lê `-` (plataforma que cai), `>` (que se move) e `+` (o outro extremo); `moving_platforms`, `falling_platforms`; `>` sem `+` e `+` sozinho são erros de sala
- `PlatformPath` e `FallingPlatformRule` (`src/core/world/`, regras puras); `MovingPlatform` (`AnimatableBody2D`, leva o mago) e `FallingPlatform` (treme, cai, volta; madeira avermelhada com rachaduras) em `src/nodes/world/`; a `Room` monta as duas (`moving_platforms()`, `falling_platforms()`)
- `WalkMap` (`src/core/world/`, regra pura): alcance a pé com os limites do pulo (vão de 4/3/2 para chão na mesma altura/1 acima/2 acima, cabeça livre, pulo não atravessa pedra)
- HUD: atalhos no bloco do topo; linha de teclas na última faixa da tela
- As oito salas refeitas, geradas por `scripts/salas/salas18.py`:
  - `sala_01`: escada de plataformas até o alto e prateleira com o baú novo;
  - `sala_02`: duas plataformas que caem na escada e um elemental de fogo no alto, no lugar do boneco de gelo;
  - `sala_03`: poço de espinhos de 10 atravessado por uma plataforma que se move, enxame de 2 sobre o poço, degrau do lado de lá para voltar;
  - `sala_p02`: entrada no alto, serpente na chegada, escada com duas que caem, runas pelo chão;
  - `sala_p03`: elemental de gelo num bloco na chegada (o mago passa por cima; ele não desce e fica a mais de 12 tiles do cristal), plataforma que sobe até o baú novo;
  - `sala_p04`: entrada no alto, escada com uma que se move, vão de 12 sobre espinhos (a ponte de sempre);
  - `sala_p05`: o elevador de sempre, com um corredor depois da porta (vão de espinhos com uma que cai);
  - `sala_p06`: 6 linhas a mais no alto, com o baú novo (plataforma que sobe e um vão de 6);
  - tochas em todas, menos na `sala_p06` (os 9 dígitos de `targets` já estão em uso; ver Limitações)
- 5 segredos na área (eram 2); o resumo do fim conta de 5

**Testes:** `test_platform_rules.gd`, `test_walk_map.gd`, `test_rooms_walk.gd` (novos, unidade), `test_platforms.gd` (novo, cena, sala `sala_plataformas`), `test_hud.gd` (UI-018), `test_segredos.gd` (+9: com feitiço, só com movimento e sem esquiva não alcança, para os três baús novos), aceitações dos puzzles 4 e 6 e a Alpha inteira com as coordenadas novas, `test_area_map.gd` (5 segredos), `test_menus.gd` (resumo).

**Totais:** 578 GdUnit4 (544 na Sprint 17), 145 pytest e 32 do gerador de sprites, verdes. A Alpha inteira (MUN-085) passa com as salas novas.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| Os atalhos (1 a 5) ficavam em cima dos pés do mago nas salas do tamanho da tela | Captura da arena na Sprint 17 | `test_UI_018_a_hud_nao_cobre_o_chao` (vermelho → verde: atalhos no bloco do topo, teclas na última faixa) |
| A plataforma que cai era igual à fixa (as rachaduras de 1 px somem na escala do jogo): o mago caía sem ter como prever | Captura de tela das salas | `test_MUN_104_a_que_cai_se_distingue_da_fixa` (vermelho → verde: madeira avermelhada e rachaduras mais grossas) |

| Teste intermitente da Sprint 17: na luta do chefe (COM-088 e a Alpha inteira), o mago conjura de cima da plataforma alta; na investida da fase 3 o chefe vai ao chão, o projétil desce, bate na plataforma (que para projéteis) e um dos 15 golpes se perdia. Passou na Sprint 17 por sorte de tempo | Suíte completa da Sprint 18 (14 golpes de 15) | `PuzzleDriver.wait_boss_above`: os dois testes esperam o chefe ficar acima do mago antes de conjurar, como um jogador espera a linha livre. Não deu para forçar o vermelho (depende do tempo); três rodadas verdes depois |

Também saíram três testes errados antes do código (layouts que não testavam o que diziam: um degrau intermediário, um `+` na linha errada, um vão raso por onde dava para descer e subir); estão corrigidos nos próprios testes.

## Teste de mutação

17 mutantes, 15 mortos e 2 equivalentes: degrau de 3 permitido; vão de 5 permitido; cabeça que não precisa caber; pulo que atravessa pedra; plataforma vertical sem ligação; ponta da horizontal que não encosta no `+`; caminho sem pausa; pisar de novo reinicia o tremor; plataforma caída que continua segurando; ninguém pisa; sem o tom avermelhado; teclas em cima do chão; sala sem plataformas novas; `sala_p04` sem um degrau da volta; `sala_03` sem o degrau do lado de lá do poço.

Equivalentes: **`sync_to_physics` desligado** (no Godot 4 a `AnimatableBody2D` leva o mago do mesmo jeito; só a sincronia com o passo da física muda) e **vão de 5 no segredo da `sala_01`** (da beirada da plataforma, 5 tiles também pedem esquiva; o 6 dá folga, e os dois testes, com e sem esquiva, continuam valendo).

## Captura de tela

As oito salas inteiras (câmera afastada) e na altura do mago. Conferido: a plataforma que se move (runas azuis) e a que cai (avermelhada) aparecem; nenhuma sala tem a HUD em cima do chão; os baús novos ficam visíveis do caminho.

## Como verificar

1. Jogue do começo (Novo jogo) até a `sala_c01`: as salas novas, as plataformas que caem (avermelhadas) na `sala_02` e na `sala_p02`, a que se move sobre os espinhos da `sala_03`, o elemental na chegada da `sala_p03`.
2. Os três baús novos: no alto da `sala_01` (escada à direita dos espinhos e um salto com esquiva para a esquerda, ou `levitar` + `mover`), na `sala_p03` (a plataforma que sobe e um salto com esquiva para a direita) e na `sala_p06` (a plataforma que sobe à esquerda e um salto com esquiva).
3. Para gerar as salas de novo: `py -3 scripts/salas/salas18.py game/content/rooms` (na raiz) e rodar os testes listados no topo do script.

## Limitações conhecidas

- **Só 9 dígitos por sala** (`targets` usa `1` a `9`): a `sala_p06` já usa todos e ficou sem tocha. A Sprint 20 (luz) vai precisar de mais marcas: vale abrir outra forma de pôr decoração (por exemplo, uma lista de tochas na cena).
- A `sala_p05` ficou com um bloco grande de pedra à direita (o elevador antigo não muda); a decoração fica para a arte (Sprint 20).
- O `WalkMap` é uma aproximação (pulo em linha reta, sem arco nem plataforma em movimento de verdade); a física de verdade fica nas aceitações.
- Entradas no alto à esquerda (`sala_p02`, `sala_p04`) ficam perto do bloco da HUD; não cobre o mago, mas fica apertado.
- Velocidade e pausas das plataformas: checklist de sensação (perguntas em aberto da MUN-plataformas).
- `sala_c01` a `c03` e a `sala_fim` ainda são as antigas (Sprint 19).
