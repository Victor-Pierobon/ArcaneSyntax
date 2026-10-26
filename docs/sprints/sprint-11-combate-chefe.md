# Sprint 11 — Combate II: chefe e balanceamento

- **Status:** Concluída em 2026-10-26 · aguardando revisão e commit do Victor
- **Fase do plano:** 6 · **Marco:** fecha o combate do M3 · **Estimativa:** 12–19 h
- **Depende de:** Sprint 10

## Objetivo

O chefe da Masmorra é vencível com um feitiço adaptável e todos os números do jogo moram num lugar só.

## Tarefas

- [x] Specs `COM-chefe` e `BAL-valores`
- [x] Chefe da Masmorra: duas fases que trocam de fraqueza, transição legível, orbe à distância
- [x] Arquivo de balanceamento `game/content/balanceamento.json`, lido por `Balance`; as `regras` vão ao executor em toda requisição
- [x] Sala `sala_c04`, teste de aceitação com Python real e orçamento de mana
- [x] `docs/feiticos-exemplo.md` (seção 4e), teste de mutação, captura de tela, fechamento

## Decisões

O Victor aprovou as recomendações ("pode seguir").

| Decisão | Por quê |
| --- | --- |
| **Regra própria do chefe** (`BossPhases`), não o `GuardianShield` | A fase troca o **elemento do corpo** (fogo → gelo); quem lê `alvo.elemento`, como já se aprendeu no elemental, vence. O guardião já cobrou `alvo.escudo` |
| Troca com vida ≤ 15 (metade); na fase 1 o golpe **para no limite** | A troca nunca é pulada por um golpe forte; o jogador sempre vê a fase 2 |
| **Transição de 1,5 s invulnerável** (`Fase 2!`, pisca entre a cor velha e a nova) | Deixa a troca legível; o feitiço já vê o elemento novo durante a transição, então o próximo golpe já sai certo |
| **Orbe à distância** a cada 3 s (fase 1) e 2 s (fase 2), que o escudo bloqueia | Dá uso ao `lancar(..., escudo)` no combate e pressiona o jogador a meditar com cuidado |
| O chefe **não reaparece** depois de derrotado (enquanto o jogo estiver aberto); a porta da sala abre | Padrão do gênero; o save em disco é da Sprint 13 |
| Balanceamento em **JSON** com seções `mago`, `executor`, `dano`, `elemental`, `enxame`, `guardiao`, `chefe` | Um arquivo para o playtest; a seção `executor` vai como `regras` |
| `REGRAS_PADRAO` continua no executor, com um pytest que exige igualdade com o arquivo | O executor roda sozinho (console, pytest) e no build não lê `game/`; o teste impede que os dois se separem |
| Sensação (pulo, esquiva, empurrão, velocidade dos projéteis do mago) **fica fora** do arquivo | É ajustada pelo checklist de sensação, não pelo balanceamento |

## O que foi entregue

**Specs:** COM-chefe e BAL-valores (novas); COM-dano (regra 5: o chefe não reaparece).

**Godot**
- `src/core/balance/balance.gd` (`Balance`, novo): `number`, `integer`, `list`, `rules()`, `validate(dados)` (aponta a chave que falta ou que não é número), `use_file`/`reset` para os testes
- `Damage`, `ElementTable.multiplier`, `ElementalBrain`, `SwarmBugBrain`, `GuardianShield`, `Elemental`, `SwarmBug`, `Guardian`, `Enemy` (contato) e `MagoState` (vida, mana máxima, invencibilidade) leem do `Balance`; as constantes de número saíram
- `World._execute` e o grimório (Testar e estimativa) mandam `Balance.rules()` como `regras`
- `src/core/combat/boss_phases.gd` (`BossPhases`, novo): fase, elemento, `resolve` com o limite da troca, `after_damage`, transição, relógio do orbe
- `src/nodes/combat/boss.gd` (`Boss`, novo) e `boss_bolt.gd` (`BossBolt`, novo)
- `Room`: `inimigo:chefe`, `boss_beaten`, sinal `boss_defeated`, porta que abre com o chefe derrotado; `World.defeated_bosses`
- `content/rooms/sala_c04.tscn` (nova); a `sala_c03` ganhou a saída à direita
- Textos `CHEFE_FASE` e `CHEFE_DERROTADO`

**Testes:** `tests/unit/balance/test_balance.gd` (BAL-001 a 003), `tests/unit/combat/test_boss_phases.gd` (COM-080 a 083), `tests/scene/combat/test_boss.gd` (COM-084 a 087, sala de teste `sala_chefe`), `tests/scene/world/test_balance_rules.gd` (BAL-004), `tests/acceptance/test_combate_04.gd` (COM-088), `executor/tests/test_balanceamento.py` (BAL-005).

**Orçamento de referência (COM-088):** o feitiço com dicionário vence em 6 conjurações e 20,4 de mana; o com `if/elif`, em 6 e 19,2. O limite do teste é 21.

**Totais:** 354 GdUnit4 e 145 pytest, verdes.

## Bugs encontrados

Nenhum bug no jogo. Dois testes estavam errados e foram corrigidos (não eram bugs do jogo):
- A aceitação esperava que o golpe final mostrasse só a vida que restava (3); o jogo mostra o dano inteiro (6), como em todo inimigo (COM-dano). A expectativa foi corrigida.
- O teste do relógio do orbe comparava floats (`2.1` contra `2.1`); passou a comparar décimos inteiros.

## Teste de mutação

4 mutantes nas regras novas:
- Morreram 3: tirar o limite da troca, montar o chefe mesmo derrotado e mandar `regras` vazias no Testar do grimório.
- Sobreviveu 1: carregar o resto da transição para o relógio do orbe. Ele muda o tempo em menos de um quadro e não tem efeito observável. Em vez de testar essa precisão, o código foi simplificado.

## Captura de tela

Fase 1 com o orbe no ar, transição (`Fase 2!`, nome já em `gelo`, `Fraco! −3`) e fase 2 (corpo azul, `Fraco! −6`). Tudo legível, sem sobreposição.

## Playtest

O Victor jogou tudo até a Sprint 10 e informou que está tudo funcionando (2026-10-26), sem pedir ajuste de valores. Isso fecha o playtest do núcleo (**M2**) e o dos puzzles e do combate. A calibração fina (estrelas do Puzzle 6, vida e tempos do combate) continua em aberto e agora se faz no `balanceamento.json`.

## Como verificar

Siga a seção "4e. O chefe da Masmorra" de `docs/feiticos-exemplo.md`. Para ir direto, mude **Start Room** do `world.tscn` para `sala_c04` e aperte F5.

## Limitações conhecidas

- Arte, animação e sons do chefe são provisórios (retângulo colorido, orbe desenhado por código).
- O orbe sai sem aviso; um brilho antes do disparo fica para o checklist de sensação.
- Derrotar o chefe fica só na memória da sessão (save na Sprint 13).
- Atrás da porta do chefe há só um nicho com ponto seguro, até a montagem da área (Sprint 14).
- Mudar o `balanceamento.json` exige reabrir o jogo.
