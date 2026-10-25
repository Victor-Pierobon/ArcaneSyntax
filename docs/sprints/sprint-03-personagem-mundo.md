# Sprint 3 — Personagem e mundo

- **Status:** Planejada
- **Fase do plano:** 2 · **Marco:** M2 · **Estimativa:** 20–30 h
- **Depende de:** Sprint 0 (protótipo de movimento); assets provisórios escolhidos (tarefa do Victor na Sprint 0)

## Objetivo

Andar por duas ou três salas de teste com vida, dano e HUD.

## Tarefas

- [ ] Movimento completo: esquiva com invencibilidade curta, coyote time, jump buffer, avaliar aceleração gradual (6–9 h)
- [ ] Câmera com limites por sala (2–3 h)
- [ ] Tilemap (`TileMapLayer`) e colisões com o tileset provisório, substituindo os `ColorRect` (4–6 h)
- [ ] Transição entre salas (3–5 h)
- [ ] Vida, dano, volta ao último ponto seguro (3–4 h)
- [ ] HUD com vida e mana (2–3 h)

## Specs a escrever

- Atualizar `docs/specs/mundo/MUN-movimento.md`: esquiva, coyote time, jump buffer (novos IDs a partir de MUN-009).
- `docs/specs/mundo/MUN-salas.md`: transição (entrar pela porta X leva ao ponto Y da sala Z), limites da câmera por sala.
- `docs/specs/mundo/MUN-vida.md`: dano, morte, invencibilidade pós-dano, ponto seguro.

## Testes

- TDD: `PlayerMotor` (coyote, buffer, esquiva), `Health` (dano, morte, cura, invencibilidade), lógica de transição de salas.
- Cena (com `intent_source` injetado, nunca teclas): esquiva atravessa um projétil sem dano; câmera não passa dos limites.
- Manual: checklist de sensação do movimento.

## Notas

- Criar aqui o modelo do mago no `src/core` (vida, mana, mana_max) que o HUD lê e que vira o `mago` do `SpellRequest` nas sprints seguintes. A mana real mora no jogo; o executor só simula.
- Manter `Player.intent_source`: a Sprint 6 usa o mesmo caminho para `mover()` e `levitar()`.
- Personagens com cerca de 32 px de altura (GDD); o colisor atual é 12×30.

## Pronto quando

Atravessar 3 salas, levar dano de espinhos e voltar ao ponto seguro.
