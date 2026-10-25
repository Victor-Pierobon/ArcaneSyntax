# Sprint 6 — Magia no mundo I: ações, formas e elementos

- **Status:** Planejada
- **Fase do plano:** 4 · **Marco:** M2 · **Estimativa:** 17–25 h
- **Depende de:** Sprint 5

## Objetivo

As ações devolvidas pelo executor acontecem no mundo.

## Tarefas

- [ ] `ActionPlayer`: interpreta a fila de ações e anima no mundo (5–8 h)
- [ ] Formas: projétil e escudo (5–7 h)
- [ ] Elementos: fogo, gelo, raio, com interações (5–7 h)
- [ ] Ataque básico de cajado sem custo de mana (2–3 h)

## Specs a escrever

- `docs/specs/magia/MAG-acoes.md`: ordem de execução, ação desconhecida ignorada com aviso, alvo que sumiu entre a execução e a animação, o que fazer com as ações de um feitiço que deu erro no meio.
- `docs/specs/magia/MAG-formas.md`: projétil (velocidade, alcance, acerto), escudo (duração, o que bloqueia).
- `docs/specs/magia/MAG-elementos.md`: tabela de interações (ex.: gelo contra fogo).

## Testes

- TDD: `ActionPlayer` com um mundo falso (adapter), tabela de interações elementais.
- Cena: projétil acerta alvo; escudo bloqueia.

## Notas

- `mover(passos)` e `levitar(altura)` usam o `Player.intent_source` ou um tween; passos e altura estão em tiles de 16 px.
- O executor identifica alvos por `id` (string); o jogo precisa de um registro id → Node.
- **Decisão pendente:** quando o feitiço dá erro na linha 3, as ações das linhas 1–2 acontecem no mundo? O executor já as devolve (EXE-protocolo, regra 5).

## Pronto quando

O feitiço adaptável do GDD (`feitico_adaptavel`) acerta alvos de elementos diferentes com o elemento certo.
