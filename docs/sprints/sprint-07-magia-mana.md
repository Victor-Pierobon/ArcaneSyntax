# Sprint 7 — Magia no mundo II: mana viva

- **Status:** Concluída em 2026-10-25 (parte técnica) · **playtest do núcleo pendente (Victor)** · aguardando revisão e commit
- **Fase do plano:** 4 · **Marco:** fecha o M2 depois do playtest · **Estimativa:** 10–16 h
- **Depende de:** Sprint 6

## Objetivo

O ciclo escrever → equipar → conjurar → ver acontecer funciona de ponta a ponta, e a mana se recupera por feitiços do jogador.

## Tarefas

- [x] `meditar()` e `absorver_mana()` no mundo (o mago parado já era da Sprint 6; agora com aura, brilho e som)
- [x] Slot passivo executado a cada 1 s, com custo por operação
- [x] Efeitos visuais e sons provisórios (gerados por código)
- [ ] **Playtest do núcleo**: roteiro pronto em `docs/playtest/roteiro-nucleo.md`; aplicar com alguém de fora (Victor)

## Decisões

| Decisão | Por quê |
| --- | --- |
| Slot passivo separado dos 5, salvo no grimório (`"passivo"`) | GDD: o grimório tem um slot passivo além dos 5 |
| Executa a cada **1 s**, sem sobreposição (pula o ciclo se a anterior não voltou) | Ritmo de "recarga automática" sem sobrecarregar |
| Qualquer erro desliga, **exceto** `ManaEsgotada` e `ExecutorIndisponivel`; editar o código ou reequipar religa | Um passivo quebrado não pode encher o registro a cada segundo; ficar sem mana é normal |
| `ManaEsgotada` aparece no registro só na primeira vez seguida; sucessos do passivo não aparecem | Registro legível |
| Ações do passivo num `ActionPlayer` próprio | Não atrasam as conjurações dos slots |
| A mana do passivo muda pela variação, como numa conjuração | Já resolvido na Sprint 5 (era a nota original desta sprint) |
| Sons e partículas gerados por código, sem arquivos | Provisórios; não viram retrabalho quando a arte e a trilha chegarem |
| Barramento de áudio `SFX` (`default_bus_layout.tres`) | Ajustar o volume no menu de opções (Sprint 14) |

## O que foi entregue

**Specs**: `docs/specs/magia/MAG-passivo.md` (MAG-050 a 059), `docs/specs/magia/MAG-efeitos.md` (MAG-060 a 062).

**Código**
- `src/core/magic/passive_scheduler.gd` (novo): quando rodar e quando desligar
- `src/core/grimoire/grimoire.gd`: `set_passive`, `clear_passive`, `passive`, sinal `passive_changed`; rename/delete acompanham; campo `"passivo"` no arquivo
- `src/nodes/grimoire/grimoire_ui.gd`: botão **Passivo** (`toggle_passive`)
- `src/nodes/ui/hud.gd`: `passive_label` + `set_passive_status`
- `src/nodes/world/world.gd`: `_execute` (execução comum a slots e passivo), `_run_passive`, `passive_scheduler`, `PassivePlayer`, `Sfx`, sons de acerto
- `src/nodes/fx/sfx.gd` (novo): sons por evento; `src/nodes/fx/fx.gd` (novo): partículas
- `src/nodes/magic/world_actions.gd`: sons e partículas nas ações; `training_target.gd`: sinal `was_hit` e explosão de partículas
- `world.tscn`: nós `PassivePlayer` e `Sfx`; `default_bus_layout.tres`; `textos.csv`: textos do passivo
- `docs/playtest/roteiro-nucleo.md` (novo); `docs/feiticos-exemplo.md` atualizado

## Testes

| Arquivo | Testes |
| --- | --- |
| `tests/unit/magic/test_passive_scheduler.gd` (novo) | 5 |
| `tests/unit/grimoire/test_grimoire_passive.gd` (novo) | 4 |
| `tests/scene/magic/test_passive.gd` (novo; 2 com o Python real) | 9 |
| `tests/scene/magic/test_sfx.gd` (novo) | 2 |
| `tests/scene/grimoire/test_grimoire_ui.gd` | +1 (botão Passivo) |
| `tests/scene/ui/test_hud.gd` | +1 (regressão) |

Totais: **179 GdUnit4** e **114 pytest**, todos verdes.

**Teste de mutação** (todas pegas): passivo sobrepondo execuções, `ManaEsgotada` desligando, ações do passivo na fila das conjurações, editar o código sem religar, aviso de mana repetido.

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| O status do passivo no HUD ficava em cima do mago, perto do chão | Captura de tela | `test_MAG_057_status_do_passivo_fica_no_topo` (vermelho → verde; foi para o bloco do topo) |

No caminho: o teste MAG-053 contou a estimativa de custo do grimório (que roda de propósito com o jogo pausado) como se fosse o passivo; o teste passou a ignorar as requisições de estimativa.

## Como verificar

`docs/feiticos-exemplo.md`, item 2.1 "Como passivo": equipe a recarga como **Passivo**, feche o grimório e veja a mana subir sozinha; experimente o passivo ruim para vê-lo ser desligado. Medite (1.1) para ver a aura; acerte bonecos para ouvir os sons.

**Checklist manual** (MAG-062): aura da meditação, brilho do absorver, explosão na cor do elemento, sons que não incomodam em repetição.

## Pendências

- **Playtest do núcleo** com 1–2 pessoas de fora (roteiro em `docs/playtest/roteiro-nucleo.md`). O marco M2 só fecha depois dele; registrar os achados em `docs/playtest/`.
- Checklists de sensação das Sprints 3 e 6.
