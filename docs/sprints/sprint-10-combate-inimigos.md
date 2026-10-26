# Sprint 10 — Combate I: inimigos

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor
- **Fase do plano:** 6 · **Marco:** M3 · **Estimativa:** 18–26 h
- **Depende de:** Sprint 7

## Objetivo

Três inimigos que pedem lógica, não só dano.

## Tarefas

- [x] Listar as peças e sentidos novos; escrever e atualizar as specs
- [x] Executor: `inimigos`, `alvo.vida`, `alvo.escudo`, forma `faisca` (custo 1); `mundo.inimigos` no protocolo v1
- [x] Vida dos inimigos, dano e fraquezas elementais; contato machuca e empurra o mago
- [x] Inimigo 1: elemental (fogo, gelo ou planta), fraco contra o elemento que o vence
- [x] Inimigo 2: enxame, vencido por um loop de faíscas sobre a lista `inimigos`
- [x] Inimigo 3: guardião que alterna o elemento do escudo
- [x] Salas `sala_c01` a `sala_c03`, testes de aceitação com Python real
- [x] `docs/feiticos-exemplo.md` (seção 4d), teste de mutação, captura de tela, fechamento

## Decisões

| Decisão | Por quê |
| --- | --- |
| **Forma nova `faisca`** (Victor): custo 1, dano base 1; o projétil passa a ter dano 3 | Com mana máxima 10, um loop de projéteis (3 cada) sobre 6 inimigos não cabia. Seis faíscas custam 6,7. O projétil continua melhor contra inimigos grandes |
| **Guardião: só a fraqueza passa** (Victor), com 1 s de brecha sem escudo entre as trocas | Ler `alvo.escudo` vira obrigatório; a brecha deixa o cajado possível, mas sofrido |
| **Inimigos reaparecem** (Victor) ao sair e voltar ou ao morrer | Padrão do gênero; nada a guardar até o save da Sprint 13 |
| Projétil **persegue** o alvo e **só acerta ele** (MAG-formas, regras 2 e 3) | Os inimigos se mexem; e num loop sobre o enxame cada golpe precisa ir para quem o feitiço escolheu |
| `inimigos`: inimigos vivos até 12 tiles, do mais perto para o mais longe; bonecos e cristais ficam de fora | É a lista do enxame; o `alvo` continua sendo o mais perto de qualquer tipo |
| `alvo` que também está em `inimigos` é o mesmo objeto | `alvo is inimigos[0]` faz sentido para o jogador |
| Dano truncado (`floor`): faísca contra quem resiste dá 0 | Deixa claro que a faísca do elemento errado não serve |
| Elemental só anda no chão em que nasceu e persegue até 2 tiles de altura | A sala_c01 tem uma borda segura, 3 tiles acima, para conjurar com calma |
| Salas `sala_c01..c03` depois da porta do Puzzle 6, geradas pelo mesmo script das salas de puzzle | Posição provisória até a Sprint 14 |

## O que foi entregue

**Specs:** COM-dano, COM-elemental, COM-enxame, COM-guardiao (novas); EXE-pecas (regras 10 a 13; EXE-120 a 126), EXE-custo (faísca; EXE-095, 096), EXE-protocolo (regra 8; EXE-112, 113), EXE-desbloqueio (EXE-086), MAG-formas (faísca, perseguição, só acerta o alvo, escudo dá invencibilidade; MAG-015 a 017), MUN-vida, MUN-alvos, MUN-salas, MAG-elementos.

**Executor**
- `pieces.py`: `Alvo` com `vida` e `escudo` (criado por `_alvo_da_foto`, fora da classe); `inimigos` (lista nova a cada execução, o alvo é o mesmo objeto); forma `faisca` e regra `custo_faisca`
- `runner.py` e `protocol.py`: `mundo.inimigos` e os campos opcionais do alvo, validados
- Fixture de contrato nova `11_combate.json`

**Godot**
- `src/core/combat/`: `Damage`, `ElementalBrain`, `SwarmBugBrain`, `GuardianShield` (novos, regras puras)
- `src/nodes/combat/`: `Enemy`, `Elemental`, `SwarmBug`, `Guardian` (novos)
- `TrainingTarget`: `hit(elemento, forma)`, `body_size`, `last_form`; `Crystal` acompanha
- `Projectile`: forma `faisca`, perseguição, só acerta o alvo escolhido; `WorldActions` passa forma e alvo
- `Room`: `inimigo:<tipo>` em `targets`, `enemies()`, sinal `player_attacked`
- `World`: `current_enemies()`, vida e escudo no alvo, `enemies` no contexto do feitiço, dano de contato com empurrão
- `PlayerMotor.knock_back`; `Health`: bloquear com o escudo dá invencibilidade
- `SpellRequest` (`mundo.inimigos`), `GrimoireUI` (Testar e estimativa com os inimigos), `MagoState`, autocompletar e realce com `faisca` e `inimigos`; som `derrota`; texto `Bloqueou`
- `content/rooms/sala_c01..c03.tscn` (novas); `sala_p06.tscn` com a saída para a `sala_c01`

## Testes

| Arquivo | Testes |
| --- | --- |
| `executor/tests/test_pecas_combate.py` (novo) | 11 |
| `executor/tests/test_desbloqueio.py` | +1 (EXE-086) |
| `tests/unit/combat/` (novos: dano, elemental, enxame, escudo do guardião) | 3 + 8 + 7 + 5 |
| `tests/unit/player/test_player_motor.gd` | +1 (empurrão) |
| `tests/unit/world/test_health.gd` | +1 (regressão), 1 ajustado |
| `tests/unit/executor_client/test_spell_contract.gd` | +3 |
| `tests/scene/combat/test_combat.gd` (novo) | 16 |
| `tests/scene/magic/test_projectiles.gd` (novo) | 5 |
| `tests/acceptance/test_combate_01.gd` a `03` (novos; Python real, salas do jogo) | 3 + 4 + 4 |

Totais: **325 GdUnit4** e **144 pytest**, todos verdes. O pytest também passou com o Python 3.14 do runtime.

**Teste de mutação:** 23 mutações (4 no executor, 19 no Godot). Na primeira rodada, 22 foram pegas. "Inimigos fora de ordem" sobreviveu: na posição de entrada da `sala_combate`, a ordem de leitura do layout já coincidia com a distância, e o COM-006 passava sem ordenar. Teste criado: `test_COM_006_inimigos_do_mais_perto_para_o_mais_longe`, com o mago do outro lado da sala; com ele, a mutação é pega (23 de 23).

## Bugs encontrados (cada um com teste de regressão)

| Bug | Como apareceu | Teste |
| --- | --- | --- |
| O escudo bloqueava a mordida, mas o inimigo continuava encostado e mordia no quadro seguinte: contra contato, o escudo não servia para nada | Teste de cena COM-005 | `test_MAG_013_bloquear_da_invencibilidade` (vermelho → verde); o fim do `test_MAG_013_escudo_bloqueia_um_ataque_mas_nao_espinho` mudou junto com a regra |
| A barra de vida ficava em cima do nome do elemento, que aparecia riscado | Captura de tela | `test_COM_003_barra_de_vida_nao_cobre_o_nome` (vermelho → verde) |

**Achado lendo o código (antes de ir para o jogo):** a fábrica de alvos era um método estático de `Alvo`, e o feitiço podia chamar `alvo.da_foto({...})` e mirar em qualquer id. Virou função do módulo; o teste `test_EXE_123_alvo_nao_fabrica_alvos` foi escrito depois da correção, e a mutação "alvo ganha um método público" confirma que ele pega.

**Nota de processo:** os testes de projétil (MAG-015 a 017) e os da sala (COM-043, erros de autoria) foram escritos antes do código, mas rodei a primeira vez já com a implementação pronta, então não os vi vermelhos. A mutação cobre essas regras.

## Como verificar

Siga a seção "4d. Combate com inimigos" de `docs/feiticos-exemplo.md`. Para ir direto às salas, abra `world.tscn` no editor, mude **Start Room** para `sala_c01` e aperte F5.

## Mudanças que afetam o jogo

- O projétil agora **persegue** o alvo e atravessa os outros alvos no caminho. Nos puzzles isso não muda nada (os cristais não se mexem), mas um `lancar` sem alvo continua acertando o primeiro que tocar.
- O escudo, ao bloquear, dá 1 s de invencibilidade.
- A sala_p06 ganhou uma saída à direita, depois da porta, que leva ao combate.

## Limitações conhecidas

- Arte, animação e sons dos inimigos são provisórios (retângulos coloridos, som gerado por código).
- O guardião não bloqueia a passagem; portas que abrem com combate ficam para o mapa (Sprint 14).
- Os inimigos não dão XP ainda (Sprint 12).
- Valores (vida, velocidades, empurrão, tempos do escudo) são provisórios; o arquivo de balanceamento é da Sprint 11.
