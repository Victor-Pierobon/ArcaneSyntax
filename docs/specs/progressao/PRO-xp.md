# PRO-xp — Experiência

- **Status:** Implementada
- **Sprint:** 12
- **Relacionadas:** PRO-niveis, BAL-valores, COM-dano, COM-chefe, PUZ-validacao (estrelas)

## Contexto

O GDD (Progressão) diz que a experiência "vem de derrotar monstros e resolver puzzles" e que "soluções econômicas em mana dão bônus de XP". A XP alimenta os níveis (PRO-niveis), que aumentam a mana máxima: o personagem cresce junto com o jogador.

## Fora do escopo

Gravar a XP em disco (save, Sprint 13). XP por descobrir salas ou por conceitos aprendidos. Mostrar a XP ganha flutuando sobre o inimigo (arte).

## Regras

1. Os valores ficam no balanceamento, seção `xp`: `elemental` **10**, `enxame` **2** (por bicho), `guardiao` **15**, `chefe` **50**, `puzzle` **20** e `bonus_estrela` **5**.
2. **Inimigo derrotado** dá a XP do seu tipo, seja qual for o golpe (feitiço ou cajado). Os inimigos reaparecem (COM-dano, regra 5) e dão XP de novo; o teto de nível (PRO-niveis) limita o ganho. O chefe não reaparece, então dá XP uma vez.
3. **Puzzle resolvido** dá `puzzle` só na primeira vez (resolvido, ele continua resolvido). Nos puzzles com estrelas, a economia dá **`bonus_estrela` por estrela acima de uma**: 3 estrelas dão +10, 2 dão +5 e 1 não dá bônus.
4. A XP é inteira e só cresce. Ela é do mago (`MagoState`), não da sala.
5. O registro mostra cada ganho: `+10 XP`; no puzzle com bônus, `+30 XP (economia +10)`.

## Critérios de aceite

### PRO-001 — Ganhar XP

- **Dado** um `MagoState` novo
- **Então** a XP é 0
- **Quando** ganha 10 e depois 2
- **Então** a XP é 12 e cada ganho emite `xp_changed`

### PRO-002 — XP do puzzle e bônus por economia

- **Então** `Progression.puzzle_xp(estrelas)` é 20 sem estrelas (0), 20 com 1, 25 com 2 e 30 com 3

### PRO-003 — Inimigos dão XP (cena)

- **Dado** uma sala com um elemental, um enxame de 2 bichos e um guardião
- **Quando** o mago derrota todos
- **Então** a XP sobe 10 + 2 + 2 + 15 = 29 e o registro mostra `+10 XP`

### PRO-004 — Inimigo que reaparece dá XP de novo (cena)

- **Dado** o mago derrotou o elemental
- **Quando** volta à sala e o derrota de novo
- **Então** a XP sobe mais 10

### PRO-005 — Puzzle dá XP só na primeira vez (cena)

- **Dado** uma sala com puzzle sem estrelas
- **Quando** o puzzle é resolvido
- **Então** a XP sobe 20; voltando à sala (o puzzle já vem resolvido), não sobe

### PRO-006 — Bônus de economia no jogo (aceitação, `sala_p04`)

- **Dado** a ponte do Puzzle 4
- **Quando** o mago a constrói com o loop econômico (3 estrelas)
- **Então** a XP sobe 30 e o registro mostra `+30 XP (economia +10)`

## Exemplos

Ato I inteiro, uma vez cada: elementais 2 × 10, enxame 6 × 2, guardião 15, chefe 50 = 97; seis puzzles 6 × 20 = 120, mais até 20 de economia (Puzzles 4 e 6). Total perto de 237.

## Perguntas em aberto

- [ ] Inimigos que reaparecem deveriam dar menos XP? (playtest: ver se o jogador "farma")
