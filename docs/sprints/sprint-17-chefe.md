# Sprint 17 — Chefe 2.0

- **Status:** Concluída em 2026-10-27 · aguardando revisão e commit
- **Plano:** Alpha 1.1 (`docs/plano-alpha-1-1.md`) · **Estimativa:** 16–24 h
- **Depende de:** Sprint 16 (commitada, `3606ff1`)

## Objetivo

O chefe deixa de ser um saco de pancada parado. Ele tem três fases (fogo → gelo → planta), se move pela arena e ataca com aviso: orbes em leque, pilares que saem do chão e investida. Quem fica parado conjurando perde; quem presta atenção vence.

## Tarefas

- [x] Revisar a spec `COM-chefe` (2.0): fases, ciclo, ataques, arena, critérios novos
- [x] Balanceamento: seção `chefe` nova (vida 90, três fases, tempos dos ataques)
- [x] `BossPhases` com três fases e dois limites (COM-080 a COM-082), TDD
- [x] `BossBrain` (regra pura): ciclo mover → aviso → ataque → descanso, ordem por fase, pontos, leque, pilares, investida (COM-083, COM-089 a COM-091), TDD
- [x] Nós: `Boss` voando entre os pontos; leque de `BossBolt`; `BossPillar` (marca e pilar); investida; cancelamento na transição; o chefe como alvo a qualquer distância
- [x] Arena `sala_c04` de 40×22 (COM-093); `AreaMap` e a Alpha inteira (MUN-085) verdes
- [x] Cenas: COM-092, COM-085, COM-086, COM-087
- [x] Aceitação com Python real: COM-088 (o feitiço vence as três fases), COM-094 (parado perde), COM-095 (quem se protege vence)
- [x] Arte do chefe pelo contrato (`chefe/` em `content/arte.json`), com provisório
- [x] Teste de mutação, captura de tela, fechamento (relatório, diário, roadmap, arquitetura, handoff)

## Decisões (por recomendação; o Victor aprovou o rumo em 2026-10-27)

| Decisão | Por quê |
| --- | --- |
| A arena é a própria `sala_c04`, refeita com 40×22 e as mesmas saídas | O caminho e a Alpha inteira (MUN-085) continuam valendo; a Sprint 19 só encaixa a arena no mapa novo |
| Vida 90, trocas em 60 e 30, o golpe trava em cada limite | Cada fase tem 30 de vida; com o feitiço de referência, 5 conjurações por fase, nenhuma cortada |
| Um ataque novo por fase: leque, depois pilares, depois investida; a fase nova começa pelo ataque que apresenta | O jogador aprende um aviso de cada vez |
| Ciclo fixo, sem sorteio | Dá para aprender o padrão; e a regra pura é testável sem sementes |
| O chefe voa entre pontos marcados na sala (`chefe:ponto`, `chefe:investida`) | Movimento fácil de ler na tela e de testar; o level design decide os pontos |
| Na arena, o chefe é alvo a qualquer distância | A arena tem 40 tiles; sem isso, `alvo` viraria `None` longe dele e o feitiço de referência daria erro |
| Os pilares saem do primeiro chão sob o mago, plataformas incluídas | Regra única e fácil de entender; "sair da marca" sempre funciona. Em aberto na spec: plataformas como refúgio |
| "Parado perde" e "quem se protege vence" medidos com um mago que faz uma ação por segundo | Ritmo de quem aperta teclas; um robô que conjura a cada quadro não diz nada sobre a luta de uma pessoa |
| Barra de vida no alto da tela fica para a Sprint 20 | É interface; a barra sobre o corpo continua |
| As plataformas `=` param os projéteis do mago e os orbes do chefe (como já paravam) | Abrigo e obstáculo ao mesmo tempo, nos dois sentidos: regra simétrica e fácil de entender. Na arena, o mago que conjura de baixo de uma plataforma perde o golpe |
| Quem se protege na COM-095 esquiva em vez de levantar o escudo | O escudo dura 2 s e o orbe leva quase 3 s para atravessar a arena: o escudo levantado no aviso acaba antes de o orbe chegar. A esquiva atravessando o orbe é o uso certo; o escudo continua bloqueando (COM-085) |
| A COM-094 usa a mana máxima 14 (nível 3, 70 de XP), a de quem chega ao chefe pelo caminho normal | É a luta que o jogador vai ter; com mana 10 a luta fica mais longa e o "parado perde" mais fácil |

## O que foi entregue

**Specs:** COM-chefe 2.0 (regras 1 a 18; COM-080 a COM-096, com COM-089 a COM-096 novos); BAL-valores (listas por fase do chefe); MAG-formas, regra 3 (o projétil que persegue o chefe não tem o limite de 12 tiles).

**Godot**
- `content/balanceamento.json`, seção `chefe` nova: vida 90, três elementos, trocas em 60 e 30, tempos e listas por fase (`descanso_s`, `ataques`, `leque_orbes`, `pilar_marcas`). `Balance` valida as listas novas: ataques conhecidos e uma posição por fase
- `BossPhases`: três fases, um limite por troca, uma fase por vez; `tick(delta)` só cuida da transição
- `BossBrain` (`src/core/combat/`, regra pura, nova): início, ciclo mover → aviso → ataque → descanso, pontos em ordem, investida pelo lado de lá, leque (`fan`), marcas de pilar com o relógio delas, cancelamento na troca; devolve eventos que o nó aplica
- `RoomLayout.floor_below` (o chão sob o mago, `#` ou `=`)
- `Boss` reescrito em cima do `BossBrain`: voa, avisa (brilho; tremida e faixa no chão na investida), solta o leque, cria marcas e pilares, limpa tudo na troca e na derrota; arte pelo contrato (`parado`, `mover`, `orbe`, `golpe`, `troca`, por elemento, com reserva)
- `BossPillar` (novo): marca piscando, pilar de 1×4 tiles que machuca enquanto está de pé; arte `chefe/aviso` e `chefe/pilar`. `BossBolt`: alcance de 48 tiles, arte `chefe/orbe_voando_<elemento>`
- `Enemy.any_distance`: o chefe é alvo a qualquer distância (`World.current_target`, `current_enemies`) e o `Projectile` que o persegue não some pelo alcance
- `Room`: `chefe:ponto` e `chefe:investida` em `targets` viram os pontos do chefe (`Boss.arena`)
- Arena `sala_c04` de 40×22 (gerada por script): degraus a 2 tiles do chão e refúgios a 4, quatro pontos no alto, investida nos dois lados, porta do chão ao teto, mesmas saídas

**Testes:** `tests/unit/combat/test_boss_phases.gd` (refeito), `tests/unit/combat/test_boss_brain.gd` (novo, 20 casos), `tests/scene/combat/test_boss.gd` (refeito, sala `sala_chefe` nova, balanceamento de tempos curtos para os ataques), `tests/acceptance/test_combate_04.gd` (refeito: arena, feitiço nas três fases, parado perde, quem se protege vence), `test_balance.gd` (listas do chefe), `test_alpha_completa.gd` (luta de cima da plataforma, até 20 conjurações).

**A luta medida (COM-094 e COM-095, uma ação por segundo, vida 5, mana 14):** o mago parado morre aos 33 s com o chefe em 12 de 90; o mago que sai das marcas e esquiva vence aos 32 s com 3 de vida. Uma pessoa joga mais devagar que uma ação por segundo; os 2 a 4 minutos do plano ficam para o playtest.

**Totais:** 544 GdUnit4 (508 na Sprint 16), 145 pytest e 32 do gerador de sprites, verdes. A Alpha inteira (MUN-085) continua passando com a arena nova.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| O projétil do mago sumia depois de 12 tiles: na arena de 40 tiles, o feitiço de referência não alcançava o chefe longe (mesmo com o chefe no `alvo`) | Lendo o código do `Projectile` antes da aceitação | `test_COM_092_projetil_alcanca_o_chefe_longe` (vermelho → verde: perseguindo quem é alvo a qualquer distância, o alcance não vale) |
| A marca do pilar (3 px no chão) ficava atrás do mago parado em cima dela: o aviso não aparecia justamente para quem precisava | Captura de tela ampliada da arena | `test_COM_085_aviso_do_pilar_aparece_na_frente_do_mago` (vermelho → verde: a marca pisca com o contorno translúcido do pilar inteiro, desenhada na frente do mago) |

## Teste de mutação

16 mutantes, 16 mortos: limite da fase 2 ignorado; duas fases de uma vez; leque sem abertura; investida pelo ponto mais perto; fase nova que continua a lista velha; troca que não limpa as marcas; descanso da fase 1 em todas; pilar sem aviso; marca no mago e não no chão; pilar que não machuca; derrota que deixa os pilares; projétil com alcance perseguindo o chefe; chefe fora de `inimigos` longe; pontos fora de ordem; arte que ignora o aviso; chefe que não voa.

## Captura de tela

Arena no começo, aviso do leque, orbes no ar, fase 2, marcas de pilar (ampliada, antes e depois da correção), pilar de pé, aviso da investida (faixa no chão) e a investida. O chefe ainda é o retângulo provisório na cor da fase (a arte entra quando a leva do chefe chegar).

## Como verificar

1. Abra o `world.tscn` e rode com F6 depois de trocar `start_room` para `sala_c04` (ou jogue até o fim pelo menu). Na arena: o chefe espera 2 s e começa a voar entre os pontos.
2. Fase 1: ele brilha e solta 3 orbes; o do meio vem em você. Ande, pule ou esquive (Shift) na direção do orbe.
3. Com o feitiço do dicionário, leve-o a 60: `Fase 2!`, ele fica azul e passa a marcar o chão sob você (o contorno pisca). Saia da marca.
4. Em 30: `Fase 3!`, verde. Ele desce para um lado, treme, a faixa aparece no chão e ele atravessa. Suba na plataforma alta, pule ou esquive através dele.
5. Fique parado só conjurando e meditando: você deve perder. Os números estão em `game/content/balanceamento.json`, seção `chefe`.

## Limitações conhecidas

- O chefe, as marcas, os pilares e os orbes ainda são provisórios (retângulos e círculos); a arte entra pelo contrato (`chefe/` no `arte.json`) quando a leva chegar.
- A barra de atalhos e a linha de teclas do HUD ficam por cima do chão da arena (a sala tem o tamanho da tela). Vale para todas as salas refeitas: rever na Sprint 18 ou na 20 (interface).
- A luta foi medida com um mago que faz uma ação por segundo (~32 s); a duração para uma pessoa (meta de 2 a 4 min) e a margem do "parado perde" (o chefe ficou com 12 de 90) ficam para o playtest.
- Plataformas param projéteis e orbes: o mago embaixo de uma plataforma perde o golpe. Decisão por recomendação (ver Decisões).
- Sem som próprio para os avisos (os sons definitivos estão fora da 1.1).
