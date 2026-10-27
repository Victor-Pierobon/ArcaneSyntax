# Sprint 20 — Integração da arte e brilho

- **Status:** Concluída em 2026-10-27 · aguardando revisão e commit
- **Plano:** Alpha 1.1 (`docs/plano-alpha-1-1.md`) · **Estimativa:** 12–20 h
- **Depende de:** Sprint 19 (commitada, `bcd2792`) e da arte do Victor

## Objetivo

Com pouca arte nova, mudar a cara do jogo pelo que não depende dela: salas escuras com luz nas tochas, cristais, feitiços, serpente e mago; partículas com a cara de cada elemento; tremida de câmera e um congelamento curto nos golpes do chefe; as linhas do código virando runas que brilham ao conjurar. A interface fica pronta para a moldura e o logo do Victor (contrato `ui/`).

## Arte que chegou

Nenhuma arte nova desde a primeira leva (Sprint 16). No gerador (`py -3 scripts/sprites/gerar.py status`): 46 gerações gastas, ~28 pendentes (chefe, aviso, pilar, orbe, `bau_abrindo`, `porta_abrindo`, placa, cadeado, fonte, retrato da serpente, fundo). O assistente **não gasta gerações** do Victor sem ele pedir. Como o plano prevê, a sprint entra com o que há; o que chegar depois entra pelo contrato sem código novo (o chefe já está ligado desde a Sprint 17).

## Tarefas

- [x] Spec `ART-brilho` (luz, partículas, tremida, congelamento, runas, moldura e logo)
- [x] Luz: sala escura (`CanvasModulate`) e luz nas tochas, cristais acesos, projéteis, escudo, serpente, fonte, mago, inimigos e ataques do chefe
- [x] Partículas por elemento (`ParticleStyle`, regra pura): brasas, flocos, faíscas, folhas
- [x] Tremida de câmera (`CameraShake`, regra pura) e congelamento curto nos golpes do chefe; opção para desligar a tremida
- [x] Runas do código: cada ação do feitiço solta uma runa com o número da linha
- [x] Interface: moldura (9-slice) nos menus, no grimório e na caixa de diálogo, e logo no menu inicial, quando os arquivos existirem
- [x] Teste de mutação, captura de tela, fechamento

## Decisões (por recomendação; o Victor revisa)

| Decisão | Por quê |
| --- | --- |
| Uma escuridão só para todas as salas, e o mago sempre com uma luz fraca em volta | O jogador nunca perde o mago de vista; salas mais ou menos escuras ficam para quando a arte do cenário chegar |
| Opção "Tremer a tela" (ligada por padrão) | Tremida de câmera incomoda algumas pessoas; desligar não muda nada além do visual |
| O congelamento é só quando um golpe do chefe acerta o mago (0,06 s) | É o momento que o jogador precisa sentir; congelar em todo golpe deixaria a luta travada |
| Runa do código com o número da linha, na cor do elemento da ação | Liga o que acontece no mundo à linha que o causou (o pilar "código real"), sem esconder o mago |
| A fonte em pixel fica para quando o Victor escolher o arquivo | Fonte não é PNG e não entra no contrato de hoje; moldura e logo entram |
| Textos do mundo não escurecem (o nome do elemento, os números, os avisos) | São informação de jogo; a sala escura não pode esconder o que o jogador lê para escrever o feitiço |
| Calibrar o chefe: voo a 100 px/s (era 60) e descansos de 1,0/0,8/0,6 s (eram 1,5/1,2/1,0) | O congelamento mudou uns quadros e o mago parado passou a vencer: a margem era fina demais (ver Bugs). Vida, dano e o feitiço de referência não mudam |

## O que foi entregue

**Specs:** ART-brilho (nova, regras 1 a 11, ART-060 a ART-067); COM-chefe (voo e descansos calibrados); UI-menus (opção Tremer a tela).

**Godot**
- `Lighting` (`src/nodes/fx/`): escuro do mundo (`CanvasModulate` no `World`), luzes com uma textura radial gerada por código, `keep_readable` para os textos do mundo
- Luz em: tocha (cintila), cristal aceso (`Crystal.glow`, na cor de quem o acendeu), projétil, escudo, serpente, fonte, inimigos (o chefe troca a cor com a fase), orbe e pilar de pé do chefe, e o mago (fraca, para não sumir no escuro)
- `ParticleStyle` (`src/core/fx/`, regra pura) e `Fx.element_burst`: brasas, flocos, faíscas e folhas no golpe, na derrota, no cristal aceso e na troca de fase do chefe
- `CameraShake` (`src/core/fx/`, regra pura); `World.shake`, `World.hit_stop`; a `Room` repassa os golpes do chefe à parte (`boss_struck`) e o pedido de tremida (`camera_rumble`); o `Boss` pede tremida na troca de fase, no pilar perto do mago e na derrota
- Opção **Tremer a tela** (`Settings.screen_shake`, `tremer_tela` no `opcoes.json`, botão no menu de opções)
- `CodeRune` (`src/nodes/fx/`): a linha de cada ação vira uma runa acima do mago
- `UiSkin` (`src/nodes/ui/`): moldura 9-slice nos menus, na caixa de diálogo e no grimório (`panel_style()`), logo no menu inicial (`TitleMenu.logo`), quando os arquivos existirem

**Testes:** `tests/unit/fx/test_fx_rules.gd`, `tests/scene/fx/` (luz, partículas, tremida e congelamento, runas), `tests/scene/art/test_ui_skin.gd`, `test_settings.gd`, `test_menus.gd` (opção), `test_boss.gd` (alvo liberado), `test_boss_brain.gd` (velocidade e descansos calibrados).

**A luta, de novo (COM-094 e COM-095):** o mago parado morre aos ~20 s com o chefe em ~48 de 90; quem sai das marcas e esquiva vence aos ~28 s com 3 de vida.

**Totais:** 612 GdUnit4 (581 na Sprint 19), 145 pytest e 32 do gerador de sprites, verdes.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| Os textos do mundo escureciam com a sala: o nome do elemento sobre o inimigo, os números das runas e das gravuras e o "E: falar" quase sumiam | Captura de tela com a luz | `test_ART_060_textos_do_mundo_nao_escurecem` (vermelho → verde: todo `Label` da sala com `Lighting.READABLE`) |
| O projétil que perseguia o chefe dava erro ("previously freed instance") quando o chefe era liberado no meio do voo (o mago morre e a sala é montada de novo). Existia desde a Sprint 17 | A luta COM-094 depois do congelamento (o parado passou a morrer com projéteis no ar) | `test_COM_092_projetil_segue_quando_o_chefe_some` (vermelho → verde: o projétil confere se o alvo ainda existe antes de tudo) |
| O mago parado passou a vencer o chefe (27 s, 1 de vida): o congelamento de 0,06 s mudou uns quadros e a luta, que já era decidida no fio desde a Sprint 17 (chefe com 12 de 90), virou | A aceitação COM-094 na suíte completa | COM-094/095 com a calibração nova (parado morre com o chefe em ~48; o atento vence com 3 de vida). Sem o congelamento, os números voltavam aos da Sprint 17: a causa era a margem fina, não o congelamento |

Também: escrevi as duas primeiras regras puras (`ParticleStyle`, `CameraShake`) junto com os testes; percebi, tirei o código, confirmei o vermelho e devolvi.

## Teste de mutação

15 mutantes, 15 mortos (um depois de reforçar o teste): mundo sem escuro; tocha com raio errado; cristal sempre aceso; chefe que não troca a cor da luz; texto do mundo que escurece; fogo que cai; explosão sem o estilo do elemento; tremida que não cai; **opção de tremer ignorada** (sobreviveu: o teste olhava só o deslocamento da câmera, que já sai zerado com a opção desligada, e o trauma se acumulava escondido; reforçado: com a opção desligada, o trauma fica em zero); tremer a tela que não grava; sair no meio do congelamento deixa o jogo parado; todo ataque congela; runa sem a cor do elemento; moldura ignorada; alvo liberado de novo.

## Captura de tela

`sala_01` (tochas e a serpente), `sala_c01` (elementais com luz na cor do corpo, plataformas que caem), `sala_c04` (o chefe). A sala ficou escura e azulada, as tochas acendem um círculo laranja, os inimigos brilham na cor do elemento. Foi a captura que mostrou os textos escurecidos.

## Como verificar

1. Jogue um pouco: a sala escura, a luz das tochas e dos inimigos, o mago sempre visível. Conjure: a runa com o número da linha sobe acima do mago, na cor do elemento.
2. Acerte um inimigo de cada elemento: as partículas mudam (brasas sobem, flocos caem devagar, faíscas rápidas, folhas para o lado).
3. Na arena: a tela treme na troca de fase e quando um golpe do chefe acerta, e o jogo para um instante nesse golpe. Em Opções, "Tremer a tela: Não" desliga a tremida.
4. Para ver a moldura e o logo: ponha `game/assets/ui/moldura.png` (48×48) e `game/assets/ui/logo.png` e abra o jogo.

## Limitações conhecidas

- **Arte:** nada novo chegou; ~28 gerações pendentes no gerador. Fonte em pixel, ícones de vida e mana e o pacote de cenário ficam para quando chegarem.
- Uma escuridão só para todas as salas; salas mais claras ou mais escuras ficam para a arte do cenário.
- O congelamento usa `Engine.time_scale`; a tela de pausa no mesmo quadro de um golpe do chefe espera os 0,06 s.
- A luz não muda nada no jogo (nem puzzle de tocha); é só visual.
