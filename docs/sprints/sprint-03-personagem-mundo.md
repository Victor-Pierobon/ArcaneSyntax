# Sprint 3 — Personagem e mundo

- **Status:** Concluída em 2026-10-25 · aguardando revisão e commit do Victor · arte ainda provisória (assets não escolhidos)
- **Fase do plano:** 2 · **Marco:** M2 · **Estimativa:** 20–30 h
- **Depende de:** Sprint 0

## Objetivo

Andar por duas ou três salas de teste com vida, dano e HUD.

## Tarefas

- [x] Movimento completo: esquiva com invencibilidade, coyote time, jump buffer (aceleração gradual ficou para decidir jogando)
- [x] Câmera com limites por sala
- [x] Tilemap (`TileMapLayer`) e colisões, com **tileset provisório gerado por script** (os assets ainda não foram escolhidos)
- [x] Transição entre salas
- [x] Vida, dano, volta ao último ponto seguro, morte e renascimento
- [x] HUD com vida e mana

## Decisões

| Decisão | Por quê |
| --- | --- |
| Salas descritas em **texto** (um caractere por tile) | Fácil de revisar no git, de testar (MUN-036 confere todas as ligações) e de autorar sem arte. Quando o tileset definitivo chegar, decidir se as salas passam a ser pintadas no editor |
| Tileset provisório de 3 tiles (`assets/placeholder/`) | Não travar a sprint esperando assets; trocar a imagem depois mantém tudo funcionando |
| Esquiva protege de **ataques**, não de espinhos | Espinhos punem erro de plataforma; a esquiva é ferramenta de combate (Sprint 10) |
| Espinho: −1 de vida e volta ao ponto seguro; morte: vida cheia e volta à entrada da sala | Estilo do gênero; sem bancos ainda |
| Ponto seguro = entrada usada ou último marcador `*` tocado | Controle explícito de quem desenha a sala, sem heurística |
| Mana real em `MagoState` (começa em 0 de 10) | O executor só simula (ADR-001); 0 porque o GDD começa sem mana |
| Áreas da sala só ligam depois do primeiro quadro de física | Bug real encontrado pelo teste MUN-027 (ver abaixo) |
| Degraus de no máximo 2 tiles no level design | O pulo alcança 3 tiles quase no limite (MUN-salas, regra 8) |
| Erros de autoria viram `push_warning` + `authoring_errors` | Não travar o jogo; o teste MUN-036 garante zero erros nas salas do jogo |

## O que foi entregue

**Specs**
- Atualizada: `docs/specs/mundo/MUN-movimento.md` (MUN-009 a 014)
- Novas: `docs/specs/mundo/MUN-vida.md` (MUN-020 a 027), `docs/specs/mundo/MUN-salas.md` (MUN-030 a 036), `docs/specs/ui/UI-hud.md` (UI-001, 002)

**Código**
- `src/core/player/player_intent.gd` (`dodge_pressed`), `src/core/player/player_motor.gd` (coyote, buffer, esquiva)
- `src/core/mago/health.gd`, `src/core/mago/mago_state.gd`
- `src/core/world/room_layout.gd`
- `src/nodes/world/room.gd`, `src/nodes/world/world.gd` + `world.tscn` (nova cena principal)
- `src/nodes/ui/hud.gd`
- Removida: `src/nodes/world/prototype_room.tscn`

**Conteúdo**
- `assets/placeholder/tiles.png` + `tiles.tres` + `LEIAME.md`
- `content/rooms/sala_01.tscn` (início, espinhos, ponto seguro), `sala_02.tscn` (escada de plataformas até a saída alta), `sala_03.tscn` (chega por cima, desce e volta)
- `project.godot`: ação `dodge` (Shift, K), cena principal `world.tscn`, fundo escuro
- `textos.csv`: `HUD_VIDA`, `HUD_MANA`, dica de controles com a esquiva

## Testes

| Arquivo | Testes |
| --- | --- |
| `tests/unit/player/test_player_motor.gd` | 18 (+10) |
| `tests/unit/world/test_health.gd` (novo) | 5 |
| `tests/unit/world/test_mago_state.gd` (novo) | 4 |
| `tests/unit/world/test_room_layout.gd` (novo) | 4 |
| `tests/scene/player/test_player_scene.gd` (agora numa `Room`) | 5 (+3) |
| `tests/scene/world/test_world.gd` (novo, salas de `tests/fixtures/rooms/`) | 7 |
| `tests/scene/world/test_content_rooms.gd` (novo) | 2 |
| `tests/scene/ui/test_hud.gd` (novo) | 2 |

Totais: **65 GdUnit4** e **105 pytest** (sem mudança no executor), todos verdes.

## O que os testes pegaram

- **Bug real:** ao morrer e renascer, a área dos espinhos da sala recarregada "via" o mago na posição antiga no primeiro quadro e tirava mais 1 de vida. O mesmo poderia acontecer com saídas ao chegar numa sala. Corrigido ligando as áreas só depois do primeiro quadro de física; o MUN-027 virou o teste de regressão.
- Dois erros de teste (não do jogo): mago solto dentro do teto e direção "segurada" depois da transição.

Revisão manual das salas (os testes não pegam isso): a sala_02 tinha degraus de 3 tiles (no limite do pulo) e a sala_03 não deixava voltar. As duas foram refeitas com degraus de 2 tiles.

Capturas de tela tiradas por script confirmaram tiles, plataformas, espinhos, HUD e textos traduzidos renderizando.

## Desvios do plano

- Tileset provisório próprio em vez de um pacote do itch.io (assets não escolhidos).
- Aceleração gradual não implementada (pergunta aberta em MUN-movimento).

## Como verificar

Abra `game/project.godot` e aperte F5 (ou `godot --path game`). A/D ou setas andam, Espaço/W pula, **Shift esquiva**. Na sala_01, pule os espinhos (ou caia neles para ver o dano e a volta ao ponto seguro) e saia pela direita; na sala_02, suba as plataformas até a saída alta; na sala_03, desça e suba de volta.

**Checklist de sensação** (só dá para avaliar jogando; anotar impressões no diário):
- [ ] O pulo parece alto o bastante? (3 tiles hoje)
- [ ] A esquiva tem a distância certa? (3 tiles)
- [ ] Coyote time e jump buffer ajudam sem parecer trapaça?
- [ ] Falta aceleração ao começar/parar de andar?

## Pendências

- Escolher os assets e trocar `tiles.png` (manter as 3 coordenadas, ver `assets/placeholder/LEIAME.md`).
- Aceleração gradual: decidir jogando.
