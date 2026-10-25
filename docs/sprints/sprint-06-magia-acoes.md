# Sprint 6 — Magia no mundo I: ações, formas e elementos

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor
- **Fase do plano:** 4 · **Marco:** M2 · **Estimativa:** 17–25 h
- **Depende de:** Sprint 5

## Objetivo

As ações devolvidas pelo executor acontecem no mundo.

## Tarefas

- [x] `ActionPlayer`: toca a fila de ações em ordem, com fila entre conjurações
- [x] Formas: projétil e escudo
- [x] Elementos: fogo, gelo e raio, com tabela de fraquezas e efeito visível nos bonecos
- [x] Ataque de cajado sem custo (tecla **J**)
- [x] Extra: `mover`, `levitar` e `meditar` movendo o mago de verdade (previsto como parte do `ActionPlayer`)
- [x] Extra: visões (`print`) flutuando sobre o mago

## Decisões

| Decisão | Por quê |
| --- | --- |
| **Ações parciais acontecem** quando o feitiço dá erro | Decisão do Victor: o código rodou até ali |
| `ActionPlayer` só sequencia; quem faz cada ação é um `port` (`WorldActions` no jogo, `FakeWorldPort` nos testes) | Fila testável sem cena, mundo testável separado |
| `mover`/`levitar`/`meditar` controlam o mago pela mesma `intent_source` do teclado (e de volta ao terminar) | Respeitam colisões e a física; nada de teleporte |
| `levitar` = voo controlado no motor (`fly_y`, MUN-015), sobe a 96 px/s, paira 0,3 s e solta | Reaproveita o motor; o elevador do Puzzle 5 vai usar |
| `mover` termina ao chegar, ao ficar 0,3 s parado (parede) ou em 3 s | Um feitiço nunca prende o jogador |
| Esperas em tempo de jogo (`create_timer(..., false)`) e laços que ignoram quadros pausados | Com o grimório aberto, tudo congela |
| Projétil mira o centro do alvo pelo id; sem alvo (ou alvo sumido) vai reto para onde o mago olha | Spec MAG-formas |
| Escudo bloqueia **um** ataque (não espinhos) e some; dura 2 s | Simples e legível; o elemento fica guardado para o guardião e o chefe |
| Tabela: fogo > planta, gelo > fogo, raio > gelo; cada elemento resiste a si mesmo | Ciclo simples do GDD; dano de verdade na Sprint 10 |
| A mana continua sendo aplicada quando o resultado chega, não aos poucos | Mais simples; rever se parecer estranho jogando |

## O que foi entregue

**Specs**: `docs/specs/magia/MAG-acoes.md` (MAG-001 a 009, 019), `MAG-formas.md` (MAG-010 a 014), `MAG-elementos.md` (MAG-030 a 033); `MUN-movimento` ganhou o voo controlado (regra 9, MUN-015).

**Código**
- `src/core/magic/element_table.gd` — efetividade
- `src/core/player/player_intent.gd` (`fly_y`), `player_motor.gd` (voo)
- `src/core/mago/health.gd` — `shielded` e sinal `attack_blocked`
- `src/nodes/magic/action_player.gd`, `world_actions.gd`, `projectile.gd`, `shield.gd` (novos)
- `src/nodes/world/training_target.gd` — hurtbox, `hit()`, texto de efeito, `center()`
- `src/nodes/world/world.gd` — liga `ActionPlayer` e `WorldActions`, toca as ações (inclusive parciais) e as visões, `find_target()`, tecla de cajado; `world.tscn` com os novos nós
- `project.godot`: ação `attack` (J); `textos.csv`: `ALVO_FRACO`, `ALVO_RESISTIU`, `ALVO_ACERTOU`, dica atualizada
- `docs/feiticos-exemplo.md` atualizado

## Testes

| Arquivo | Testes |
| --- | --- |
| `tests/unit/magic/test_action_player.gd` (novo, com `FakeWorldPort`) | 4 |
| `tests/unit/magic/test_element_table.gd` (novo) | 3 |
| `tests/unit/player/test_player_motor.gd` | +1 (MUN-015) |
| `tests/unit/world/test_health.gd` | +1 (escudo) |
| `tests/scene/magic/test_world_actions.gd` (novo, sala `sala_aberta`) | 16 |

Totais: **157 GdUnit4** e **114 pytest** (sem mudança no executor), todos verdes.

**Teste de mutação**: pegas de primeira: ações parciais não tocando, `mover` sem detectar parede, tabela de elementos trocada, `levitar` sem voo. **Escaparam duas**, e os testes foram reforçados:

| Mutação que escapou | Por quê | Teste novo |
| --- | --- | --- |
| Esperas ignorando a pausa | O MAG-009 só conferia o projétil | `test_MAG_009_pausa_congela_a_fila_de_acoes` |
| Projétil ignorando o alvo | No MAG-010 o boneco estava bem na frente do mago | `test_MAG_010_projetil_mira_o_alvo_mesmo_de_costas` |

## Bugs encontrados

Nenhum bug de jogo nesta sprint. Erros no caminho: uma substituição de texto caiu dentro do setter de `World.executor` em vez do `_ready` (erro de compilação, corrigido na hora); o teste MAG-005 comparava o controle com o do teclado em vez de "o controle de antes"; um teste mirava num boneco atrás de outro.

## Como verificar

Siga `docs/feiticos-exemplo.md`. Na sala_01, conjure **3.1** (bola de fogo) e **3.2** (adaptável) perto dos bonecos e veja o efeito; **3.4** ergue o escudo; **4.1** levita; **4.2** patrulha; **J** dá um golpe de cajado. Com um erro no meio (5.3), a parte antes do erro acontece.

**Checklist de sensação** (jogando):
- [ ] A velocidade do projétil (220 px/s) e o atraso de 0,15 s entre ações parecem bons?
- [ ] O levitar (96 px/s, paira 0,3 s) é gostoso de usar?
- [ ] Perder o controle durante `mover`/`meditar` incomoda?
- [ ] Gastar a mana toda no começo da conjuração (e não aos poucos) parece estranho?

## Limitações conhecidas

- Bonecos não têm vida; só mostram o efeito (dano de verdade na Sprint 10).
- Visual provisório: projétil é um círculo, escudo é um círculo translúcido, cajado não tem animação.
- Sem sons (Sprint 7).
