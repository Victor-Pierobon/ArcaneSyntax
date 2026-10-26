# MUN-vida — Vida, mana do mago, dano e pontos seguros

- **Status:** Implementada
- **Sprint:** 3
- **Relacionadas:** MUN-movimento, MUN-salas, UI-hud, EXE-protocolo (`mago`)

## Contexto

O mago precisa de vida e mana reais no jogo: o HUD mostra, os espinhos tiram, e o estado vira o `mago` do `SpellRequest` nas próximas sprints. O executor só simula a mana (ADR-001); a mana verdadeira mora aqui.

## Fora do escopo

Dano de inimigos (COM-dano), recuperação de mana por feitiços no mundo (Sprint 7), save (Sprint 13).

## Regras

1. `Health` (regra pura): vida inteira de 0 até `maximum` (padrão **5**). Dano reduz, cura aumenta, nunca passa dos limites.
2. Depois de levar dano, **1 s de invencibilidade**: danos nesse tempo são ignorados. Desde a Sprint 10, vale também depois de o escudo bloquear um ataque (MAG-formas, regra 5).
3. A esquiva deixa o mago invulnerável a ataques. **Espinhos ignoram essa proteção** (só respeitam a invencibilidade pós-dano).
4. Ao chegar a 0, o sinal `died` é emitido uma única vez.
5. `MagoState` reúne `health`, `mana` e `mana_max` (padrão: vida 5/5, mana **0** de **10**, porque o jogo começa sem mana, segundo o GDD). A mana tem resolução de 0,1 e fica entre 0 e `mana_max`. `to_spell_mago()` gera o `mago` do protocolo.
6. **Espinhos:** tocar tira 1 de vida e leva o mago ao último ponto seguro, parado.
7. **Ponto seguro:** é a entrada pela qual o mago chegou na sala, ou o último marcador de ponto seguro (`*` no layout, MUN-salas) que ele tocou.
8. **Morte:** vida cheia e volta à entrada pela qual chegou na sala atual. A mana é mantida.
9. **Fonte** (Sprint 14, MUN-mapa): `fonte` em `targets` põe uma fonte na sala. Com o mago a até 2 tiles aparece `E: beber`; a tecla E enche a vida e a mana, avisa no registro e salva. Pode ser usada quantas vezes quiser. Se a serpente também estiver ao alcance, E fala com a serpente. Na Masmorra, há uma fonte na `sala_c03`, antes do chefe.

## Critérios de aceite

### MUN-020 — Dano e limites

- **Dado** vida 5/5
- **Quando** leva 2 de dano
- **Então** fica com 3; com dano 10, fica com 0 (nunca negativo); curar 10 a partir de 3 vai a 5

### MUN-021 — Morte uma vez

- **Dado** vida 1
- **Quando** leva dano duas vezes (passada a invencibilidade)
- **Então** `died` é emitido uma única vez e a vida é 0

### MUN-022 — Invencibilidade pós-dano

- **Dado** o mago acabou de levar dano
- **Quando** leva outro dano antes de 1 s
- **Então** é ignorado; depois de 1 s, conta

### MUN-023 — Esquiva protege de ataques, não de espinhos

- **Dado** o mago esquivando
- **Quando** recebe dano de ataque
- **Então** é ignorado; dano de espinho conta

### MUN-024 — Mana do mago

- **Dado** `MagoState` novo
- **Então** vida 5/5 e mana 0/10; `set_mana(10.06)` dá 10 (teto); `set_mana(-1)` dá 0; `set_mana(4.94)` dá 4.9
- **E** `to_spell_mago()` é `{"vida": 5, "mana": 0.0, "mana_max": 10.0}`

### MUN-025 — Espinhos (cena)

- **Dado** o mago numa sala, com um ponto seguro registrado
- **Quando** toca nos espinhos
- **Então** perde 1 de vida e aparece no ponto seguro, parado

### MUN-026 — Ponto seguro atualizado por marcador (cena)

- **Dado** o mago entrou pela entrada A
- **Quando** passa por um marcador `*` e depois toca nos espinhos
- **Então** volta para o marcador, não para a entrada

### MUN-027 — Morte e renascimento (cena)

- **Dado** o mago com 1 de vida e mana 3
- **Quando** toca nos espinhos
- **Então** renasce na entrada da sala com vida 5/5 e mana 3

### MUN-028 — Fonte enche vida e mana (cena)

- **Dado** o mago com vida 2 e mana 1, perto de uma fonte
- **Quando** aperta E
- **Então** fica com vida e mana cheias e o registro avisa; longe da fonte, E não faz nada
