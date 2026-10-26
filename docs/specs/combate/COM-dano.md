# COM-dano — Vida, dano e os inimigos no feitiço

- **Status:** Implementada
- **Sprint:** 10
- **Relacionadas:** MAG-elementos, MAG-formas, MUN-vida, MUN-alvos, EXE-pecas (`inimigos`, `alvo.vida`, `alvo.escudo`), COM-elemental, COM-enxame, COM-guardiao

## Contexto

Até a Sprint 9 os bonecos só mostravam o efeito do golpe. Agora os inimigos têm vida e machucam o mago, e o elemento certo vence mais rápido. O feitiço enxerga os inimigos para poder escolher o elemento (condicionais) e percorrer a lista (loops), como pede o GDD em "Inimigos que pedem lógica, não só dano".

## Fora do escopo

Comportamento de cada inimigo (COM-elemental, COM-enxame, COM-guardiao). XP e níveis (Sprint 12). Chefe (Sprint 11). Arte e animação definitivas.

## Regras

1. **Dano** = parte inteira de `base × multiplicador`, com o multiplicador de MAG-elementos (fraco 2×, normal 1×, resiste 0,5×). Base: projétil **3**, faísca **1**, cajado **1**. O cajado é sempre normal.

   | Ataque | normal | fraco | resiste |
   | --- | --- | --- | --- |
   | projétil | 3 | 6 | 1 |
   | faísca | 1 | 2 | 0 |
   | cajado | 1 | — | — |

2. Cada inimigo tem vida inteira e nenhuma invencibilidade depois do golpe. Ao chegar a 0, é **derrotado**: sai na hora dos grupos de alvos e de inimigos (o próximo feitiço já não o vê), solta partículas e some.
3. O golpe mostra o efeito e o dano sobre o inimigo: `Fraco! −6`, `Acertou −3`, `Resistiu −1`; com dano 0, só `Resistiu`. Um golpe bloqueado (COM-guardiao) mostra `Bloqueou`. Acima do inimigo ficam, de baixo para cima, a barra de vida, o nome do elemento e o texto do golpe, sem um cobrir o outro (nos bichos do enxame o nome fica escondido: seis nomes juntos poluíam a tela).
4. **Contato:** encostar num inimigo tira **1** de vida do mago, como ataque (MUN-vida): o escudo do mago bloqueia, a esquiva evita, e vale a invencibilidade de 1 s. Quem continua encostado leva dano de novo quando a invencibilidade acaba. Ao levar dano de contato, o mago é empurrado para longe do inimigo (valor provisório, para ajustar no checklist de sensação).
5. **Os inimigos reaparecem** (decisão do Victor): sair da sala e voltar, ou morrer, monta a sala de novo com todos os inimigos. Exceção: o chefe derrotado não volta (COM-chefe, regra 7).
6. **Na foto do mundo** (EXE-protocolo, regra 8):
   - `inimigos` é a lista dos inimigos vivos da sala a até **12 tiles** do mago, do mais perto para o mais longe, cada um com `id`, `elemento`, `distancia` (tiles, uma casa), `vida` e `escudo` (elemento ou `null`).
   - Quando o `alvo` é um inimigo, ele também traz `vida` e `escudo`. Bonecos e cristais não trazem esses campos e não entram em `inimigos`.
7. Os inimigos ficam parados com o grimório aberto (o jogo pausa).
8. No layout, um inimigo é um dígito com `inimigo:<tipo>[:<parâmetro>]` em `targets` (MUN-alvos). O id é `<sala>_alvo_<dígito>`; no enxame, `<sala>_alvo_<dígito>_<n>`.

## Critérios de aceite

### COM-001 — Tabela de dano

- **Então** projétil de gelo contra fogo dá 6, projétil de raio contra fogo dá 3, projétil de fogo contra fogo dá 1, faísca de raio contra gelo dá 2, faísca de gelo contra gelo dá 0 e cajado contra qualquer elemento dá 1

### COM-002 — Vida e derrota

- **Dado** um elemental de fogo com vida 12
- **Quando** recebe dois projéteis de gelo
- **Então** fica com 6 depois do primeiro; no segundo, é derrotado, emite `defeated` uma vez e sai dos grupos de alvos e de inimigos na hora

### COM-003 — O golpe mostra o dano

- **Quando** um elemental de fogo recebe um projétil de gelo e depois uma faísca de fogo
- **Então** mostra `Fraco! −6` e depois `Resistiu`, e guarda o último dano (6, depois 0)
- **E** a barra de vida não cobre o nome do elemento (regressão achada por captura de tela)

### COM-004 — Contato machuca (cena)

- **Dado** o mago parado encostado num inimigo
- **Então** perde 1 de vida, é empurrado para longe do inimigo e, se continuar encostado, perde mais 1 só depois de 1 s

### COM-005 — Escudo e esquiva contra o contato (cena)

- **Dado** o mago com escudo ativo
- **Quando** encosta num inimigo
- **Então** o escudo some e a vida não muda; esquivando, a vida também não muda

### COM-006 — Inimigos na foto do mundo (cena)

- **Dado** uma sala com um boneco a 2 tiles, um inimigo a 6 tiles, outro a 3 tiles e um a 14 tiles do mago
- **Então** `spell_context()` tem `enemies` com os inimigos de 3 e 6 tiles, nessa ordem, cada um com `id`, `elemento`, `distancia`, `vida` e `escudo`; o boneco não entra, nem o de 14 tiles
- **E** depois de derrotar o de 3 tiles, a lista só tem o de 6

### COM-007 — Alvo inimigo traz vida e escudo (cena)

- **Dado** o inimigo mais perto do mago é um elemental de fogo com vida 12
- **Então** o alvo é `{"id", "elemento": "fogo", "distancia", "vida": 12, "escudo": null}`; com um boneco mais perto, o alvo não tem `vida` nem `escudo`

### COM-008 — Inimigos reaparecem (cena)

- **Dado** o mago derrotou o inimigo da sala
- **Quando** sai e volta, ou morre
- **Então** o inimigo está lá de novo, com a vida cheia

### COM-009 — Pausa congela (cena)

- **Dado** um inimigo andando
- **Quando** o jogo pausa
- **Então** ele não se mexe nem machuca enquanto o jogo estiver pausado

## Exemplos

```python
# O feitiço que pensa (GDD), agora com dano de verdade
if alvo.elemento == "fogo":
    lancar(gelo, projetil, alvo)
elif alvo.elemento == "gelo":
    lancar(raio, projetil, alvo)
else:
    lancar(fogo, projetil, alvo)
```

## Perguntas em aberto

- [ ] O empurrão do contato e os valores de vida estão bons de jogar? (checklist de sensação)
