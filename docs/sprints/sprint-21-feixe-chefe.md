# Sprint 21 — Feixe, chefe mais rápido e magia mais cara

- **Status:** Concluída em 2026-10-27 · aguardando revisão e commit
- **Plano:** Alpha 1.1 (`docs/plano-alpha-1-1.md`; sprint incluída a pedido do Victor) · **Estimativa:** 12–18 h
- **Depende de:** Sprint 20 (commitada)

## Objetivo

Três pedidos do Victor depois de jogar a Sprint 20 (2026-10-27):

1. **O feixe:** uma forma mais forte que o projétil, "tipo kamehameha ou o Zoltraak de Frieren". Ele escolheu: carrega e dispara, atravessa todos os inimigos no caminho, aprendido com a serpente antes do chefe.
2. **O chefe ainda está lento e fácil:** ele escolheu "é lento", "pouca pressão" e "fácil de esquivar".
3. **A magia está barata:** "dá para castar várias magias em sequência sem pensar muito".

## Tarefas

- [x] Spec `MAG-feixe` (nova); COM-chefe (ritmo, orbes nos pilares, mira adiante); EXE-custo e BAL-valores (custos novos)
- [x] Executor: forma `feixe`, `custo_feixe`; custos novos (`custo_lancar` 4, `custo_faisca` 1,5); testes do executor com os valores novos
- [x] Godot: `dano.feixe`; `BeamRule` (regra pura); carregar e disparar; desbloqueio pela serpente da `sala_c03`; página da Referência; autocompletar e realce
- [x] Meditar leva 1,0 s
- [x] Chefe: mais rápido, orbes junto com os pilares, mira adiante, avisos mais curtos; medir as lutas e calibrar
- [x] Revisar o que cita custo (Referência, lições, dicas, `docs/feiticos-exemplo.md`) e as estrelas do Puzzle 6
- [x] Aceitação, teste de mutação, captura de tela, fechamento

## Decisões

| Decisão | Quem | Por quê |
| --- | --- | --- |
| Feixe: carrega 0,5 s e dispara; atravessa todos os inimigos na linha | Victor | Escolha dele entre três formas |
| Feixe aprendido com uma serpente na `sala_c03`, antes do chefe | Victor | O jogador aprende e já usa na luta |
| Chefe: mais rápido, mais pressão, avisos mais curtos (sem tirar os avisos) | Victor | "Ele é lento", "pouca pressão", "fácil de esquivar" |
| Custos: `lancar` 3 → 4, faísca 1 → 1,5, feixe 8; meditar continua +5, mas leva 1,0 s (era 0,5) | recomendação | O Puzzle 1 ensina meditar uma vez e lançar: com `lancar` acima de 4,6 ele quebraria. Meditar mais lento faz recuperar mana custar tempo, que é o que pesa contra o chefe |
| Mover, levitar, inscrever e bloco não mudam | recomendação | São ferramentas de puzzle; mudar o custo deles mexeria nas estrelas de quase todos os puzzles sem tocar no problema (combate) |
| O nome no código é `feixe` | recomendação | `raio` já é um elemento |
| **Projéteis, faíscas e orbes atravessam plataformas** (só pedra e porta fechada param tiros); as plataformas ganharam uma camada de física própria | recomendação, revertendo a da Sprint 17 | Na luta, quem fugia das marcas para baixo de uma plataforma não acertava mais o chefe (o projétil persegue o alvo e morria na tábua). O feixe já atravessava. As plataformas continuam segurando o mago e protegendo da investida |
| Chefe: voo a 140 px/s, descansos de 0,7/0,5/0,4 s, aviso do leque de 0,45 s, mira 0,3 s adiante, investida a 300 px/s com aviso de 0,6 s, 4 e 5 marcas de pilar, orbes junto dos pilares só na fase 3 | recomendação, medida | A primeira tentativa (orbes a 130 px/s, marcas a cada 0,5 s, orbes com pilares nas fases 2 e 3) fazia até quem se protege perder (ver Calibração) |
| Quem chega ao chefe está no nível 4 (mana 16), e quem se protege medita nas brechas e usa o passivo de `absorver_mana` | recomendação, medida | Com a magia mais cara, a luta pede 66 de mana. O XP do teste da Alpha leva ao nível 4; o passivo é a resposta que o jogo ensina para mana cara |

## O que foi entregue

**Specs:** MAG-feixe (nova, regras 1 a 10, MAG-080 a MAG-087); COM-chefe (ritmo, orbes nos pilares, mira adiante, COM-097 e COM-098, nível 4 na chegada); EXE-custo, EXE-pecas, BAL-valores (custos novos, `custo_feixe`, `dano.feixe`); COM-enxame (custos); MAG-formas e MAG-acoes (meditar de 1 s); GRI-slots (o feixe começa bloqueado); PUZ-06 (estrelas [22, 26]).

**Executor:** forma `feixe` com `custo_feixe` 8; `custo_lancar` 3 → 4; `custo_faisca` 1 → 1,5. Os contratos (`tests/contract/*.json`) foram regenerados só nos campos de custo.

**Godot**
- `BeamRule` (`src/core/magic/`, regra pura): onde o feixe termina e quem ele encosta; `Beam` (`src/nodes/magic/`): o desenho, com luz ao longo; `WorldActions._fire_beam`: carrega 0,5 s parado (com a luz crescendo na mão) e dispara; `Room.blocks_beam`
- `MagoState.LOCKED_AT_START` (o feixe) e `unlock`; `World.LESSON_UNLOCKS` (a lição `ensino_feixe` libera o feixe, avisa no registro e volta pelo save); serpente `ensino_feixe` na `sala_c03`; página Feixe na Referência; `feixe` no autocompletar e no realce
- `Damage`: forma `feixe` (dano 6)
- Meditar leva 1 s
- `BossBrain`: mira adiante no leque (`leque_adiante_s`), orbe junto da marca de pilar (`pilar_orbes`); o `Boss` passa a velocidade do mago
- Plataformas na camada `Room.PLATFORM_LAYER`; o mago pousa nelas, os tiros atravessam
- Estrelas do Puzzle 6: [22, 26]

**Testes:** `test_beam_rule.gd`, `test_beam.gd` (novos); executor (feixe, custos); `test_boss_brain.gd` (ritmo, COM-097, COM-098); `test_boss.gd` (tiros atravessam plataformas); `test_combate_04.gd` (nível 4, quem se protege medita nas brechas com o passivo, MAG-087); `test_world_actions.gd` (meditar de 1 s); aceitações dos puzzles, do enxame e da Alpha inteira com os custos novos (a Alpha ouve a serpente do feixe).

**Totais:** 626 GdUnit4 (612 na Sprint 20), 149 pytest e 32 do gerador de sprites, verdes; o pytest também no Python 3.14 do runtime.

## Calibração do chefe (as duas lutas medidas, uma ação por segundo)

| Configuração | Parado | Quem se protege |
| --- | --- | --- |
| Sprint 20 (custos antigos) | morre aos 20 s, chefe em 48 | vence com 3 de vida |
| Custos novos + chefe da Sprint 20 | morre aos 20 s | **perde** (28 s, chefe em 48) |
| Primeira proposta do chefe (orbes 130 px/s, marcas 0,5 s, orbes com pilares nas fases 2 e 3) | morre aos 17 s | **perde** (33 s) |
| Final: chefe da tabela de Decisões, nível 4, passivo, tiros atravessando plataformas | morre aos ~22 s, chefe em ~18 | **vence** aos ~26 s com 3 de vida |

O que mais pesou não foi o chefe: foi a magia mais cara (a luta pede 66 de mana em vez de 51) somada às plataformas que paravam os tiros de quem fugia para baixo delas. A medição mostrou os dois.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| Projéteis e orbes morriam nas plataformas: na arena, o mago que fugia das marcas para baixo de uma plataforma não acertava mais o chefe (decisão da Sprint 17 que virou problema) | Registro dos golpes na medição da COM-095 | `test_COM_092_tiros_atravessam_plataformas` (vermelho → verde: plataformas numa camada própria) |
| Nenhum teste dizia quanto tempo o meditar dura (a mudança de 0,5 para 1 s passaria sem nada falhar) | Ao montar a mutação | `test_MAG_007_meditar_dura_1_segundo` |

Também: o teste "sem orbe onde a fase não pede" (COM-097) foi escrito primeiro só lendo o balanceamento; reescrito para testar o comportamento. E, de novo, escrevi a `BeamRule` junto com o teste; tirei o código, confirmei o vermelho e devolvi.

## Teste de mutação

12 mutantes, 12 mortos: feixe que custa como o `lancar`; feixe com dano de projétil; feixe que atravessa pedra; feixe mais largo; carga que não trava o mago; save que não devolve o feixe; feixe liberado desde o começo; leque sem mira adiante; orbe em todo pilar; plataforma que para tiros de novo; mago que atravessa plataformas; meditar de volta a 0,5 s (este só morreu depois do teste novo de duração).

## Captura de tela

O feixe na sala de teste: carregando (a luz cresce na mão) e disparado, atravessando o boneco e o elemental de fogo (`Fraco! −12`) e parando na parede; o boneco atrás da parede e o do alto ficam intactos. A runa do código da linha aparece acima do mago.

## Como verificar

1. Jogue até a `sala_c03`: a serpente perto da fonte ensina o feixe ("Você aprendeu o feixe!"). Abra a Referência: a página Feixe aparece.
2. Conjure `lancar(gelo, feixe, alvo)` num elemental de fogo: o mago para meio segundo com uma luz crescendo na mão, e sai um feixe que atravessa todos na linha até a parede (12 de dano no de fogo).
3. Note a magia mais cara: `lancar` custa 4, a faísca 1,5, o feixe 8; meditar deixa o mago parado 1 s.
4. Na arena: o chefe voa e ataca mais rápido, o leque mira onde você vai estar, e na fase 3 cada marca de pilar vem com um orbe. Os tiros passam pelas plataformas.

## Limitações conhecidas

- A luta foi medida com robôs de uma ação por segundo; a meta de "um pouco mais difícil" é para o seu playtest. Os números estão em `balanceamento.json`, seção `chefe`.
- Sem arte própria para o feixe (`magia/feixe_<elemento>` não está no contrato ainda); o feixe é desenhado por código.
- O feixe não reflete nem faz curva; contra o chefe, carregar parado é arriscado de propósito.
