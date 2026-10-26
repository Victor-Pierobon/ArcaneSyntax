# Sprint 12 — Progressão e sistemas da serpente

- **Status:** Concluída em 2026-10-26 · aguardando revisão e commit do Victor
- **Fase do plano:** 7 · **Marco:** M3 · **Estimativa:** 12–18 h
- **Depende de:** Sprints 9 e 11 (XP vem de puzzles e monstros)

## Objetivo

O jogador ganha XP e níveis, e o jogo tem um sistema de diálogo e páginas de referência prontos para receber conteúdo.

## Tarefas

- [x] Specs `PRO-xp`, `PRO-niveis`, `NAR-dialogo`, `GRI-referencia`
- [x] XP por monstros e puzzles, bônus por solução econômica
- [x] Níveis até o 5, cada um aumentando (e enchendo) a mana máxima; nível e XP no HUD
- [x] Sistema de diálogo com cenas em arquivo, escolhas e erros de autoria claros; serpente na sala (tecla E)
- [x] Aba Referência no grimório, com 13 páginas das peças na voz da serpente
- [x] Teste de mutação, captura de tela, fechamento

## Decisões

Recomendações minhas, seguidas depois do "pode seguir" do Victor. Todas podem mudar sem mexer em código: os números estão no `balanceamento.json` e os textos, no `textos.csv`.

| Decisão | Por quê |
| --- | --- |
| XP: elemental 10, bicho do enxame 2, guardião 15, chefe 50, puzzle 20 (na primeira vez), +5 por estrela acima de uma | O Ato I inteiro dá perto de 237 XP, o bastante para chegar ao nível 5 jogando tudo uma vez |
| Inimigos que reaparecem **dão XP de novo** | É mais simples. O teto no nível 5 limita o farm; fica como pergunta para o playtest |
| Níveis 0/30/70/130/210 de XP; mana máxima 10/12/14/16/18. **Subir enche a mana** | Recompensa visível na hora. A mana máxima saiu de `mago` e passou a vir do nível |
| Diálogos em `content/dialogos.json`, com falas que levam à `proxima` ou dão `opcoes` (até 3); os textos são chaves do `textos.csv` | Formato simples para escrever a Sprint 13 à mão. A validação aponta a cena e a fala com problema |
| A serpente **não puxa conversa sozinha**: com o mago a até 2 tiles aparece `E: falar` | Não interrompe o jogador nem os testes que passam pela sala. Puxar conversa em momentos-chave fica para a Sprint 13 |
| Caixa de diálogo **no alto da tela**, abaixo do HUD | Embaixo, ela cobria o mago e a serpente (veja os bugs) |
| Referência: uma aba no grimório; a página só aparece com as peças dela desbloqueadas | Segue o GDD ("cada peça ganha uma página"). As páginas de conceito vêm com os ensinamentos da Sprint 13 |

## O que foi entregue

**Specs:** PRO-xp, PRO-niveis, NAR-dialogo, GRI-referencia (novas). Atualizadas: BAL-valores (seções `xp` e `niveis`), UI-hud (regra 4) e MUN-alvos (`serpente:`).

**Godot**
- `Progression` (`src/core/mago/progression.gd`, novo): `level_for`, `mana_max_for`, `next_threshold`, `max_level`, `puzzle_xp`, `economy_bonus`
- `MagoState`: `xp`, `level`, `gain_xp`; sinais `xp_changed` e `leveled_up`; a mana máxima vem do nível
- `Enemy.setup(id, elemento, tipo, tamanho)`: o tipo dá a vida e a XP no balanceamento; `Enemy.xp`
- `World`: XP de inimigos (`_on_enemy_defeated`) e de puzzles (com o bônus), aviso de nível no registro, `talk()`, `serpent_in_reach()`, `dialogues`, `dialogue_box`
- `Hud.level_label` (`Nível 2 · XP 45/70`)
- `DialogueBook` e `DialogueRun` (`src/core/narrative/`, novos); `DialogueBox` e `Serpent` (`src/nodes/narrative/`, novos)
- `ReferenceBook` (`src/core/grimoire/reference_book.gd`, novo); `GrimoireUI` com abas (`show_reference`, `show_spells`, `select_page`) e `blocked` (não abre durante o diálogo)
- `Room`: `serpente:<cena>` em `targets`, `serpents()`
- Ação de entrada `talk` (tecla **E**); dica de controles atualizada
- Conteúdo: `content/dialogos.json` (cena de teste `serpente_ola`, na `sala_01`), `content/referencia.json` (13 páginas), textos novos no `textos.csv`, seções `xp` e `niveis` no `balanceamento.json`

**Testes:** `tests/unit/progression/test_progression.gd`, `tests/unit/narrative/test_dialogue.gd`, `tests/unit/grimoire/test_reference_book.gd`, `tests/scene/world/test_progression_world.gd` (sala de teste `sala_xp`), `tests/scene/narrative/test_dialogue_box.gd` (sala de teste `sala_serpente`), `tests/scene/grimoire/test_grimoire_reference.gd` e `test_PRO_006_bonus_de_economia` em `tests/acceptance/test_puzzle_04.gd`.

**Totais:** 387 GdUnit4 e 145 pytest, verdes.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| O mago parado ao lado da serpente cobria o aviso `E: falar` | Captura de tela | `test_NAR_005_aviso_fica_acima_do_mago` (vermelho: o aviso terminava em y 58, o mago começava em 50 → verde) |
| A caixa de diálogo, embaixo, cobria o mago e a serpente (o chão da sala fica no rodapé da tela) e encostava na linha dos slots | Captura de tela | `test_NAR_005_caixa_no_alto_sem_cobrir_o_hud` (vermelho: a caixa terminava em y 334 → verde) |

## Teste de mutação

7 mutantes, 7 mortos: subir de nível sem encher a mana; bônus contando todas as estrelas; inimigo sem XP; página visível com só uma das peças; avançar numa fala com opções; grimório abrindo durante o diálogo; validação sem conferir o fluxo da cena.

## Captura de tela

Serpente com o aviso, as três telas do diálogo (fala, opções e fala do mago), o HUD com `Nível 2 · XP 45/70`, a aba Referência (lista e página `alvo e inimigos`) e a aba Feitiços. Depois das duas correções, nada se sobrepõe.

## Como verificar

Siga a seção "4f. Progressão, serpente e referência" de `docs/feiticos-exemplo.md`.

## Limitações conhecidas

- O conteúdo do diálogo é uma cena de teste; as falas de verdade e as dicas são da Sprint 13.
- XP, nível e cenas vistas ficam só na memória da sessão (save na Sprint 13).
- Não há páginas de conceito nem atalho do editor para a página da peça.
- Os custos citados nas páginas de referência (3, 1, 0,5…) são texto; se o `balanceamento.json` mudar um custo, a página precisa ser atualizada à mão.
