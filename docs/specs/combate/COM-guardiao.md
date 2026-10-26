# COM-guardiao — Guardião de escudo

- **Status:** Implementada
- **Sprint:** 10
- **Relacionadas:** COM-dano, MAG-elementos, EXE-pecas (`alvo.escudo`), ADR-001

## Contexto

O guardião ensina a **ler um sentido antes de agir**: o escudo troca de elemento, e só o elemento que vence o escudo passa (decisão do Victor). Um feitiço fixo acerta uma vez em três; o feitiço que lê `alvo.escudo` acerta sempre.

## Fora do escopo

Guardião que anda ou ataca à distância. Bloquear passagem (portas por combate ficam para o mapa, Sprint 14).

## Regras

1. Em `targets`: `inimigo:guardiao`. Elemento do corpo: **`pedra`** (neutro). Vida **18**, dano de contato **1**. Fica parado.
2. **Escudo** (`GuardianShield`, regra pura): ciclo **fogo → planta → gelo → fogo…**, **4 s** cada, com **1 s sem escudo** (a brecha) entre um e outro. Começa em fogo. No último 1 s de cada escudo, ele pisca.
3. **Com escudo, só passa o elemento que vence o escudo** pela tabela de MAG-elementos: gelo passa pelo de fogo, fogo pelo de planta, raio pelo de gelo. O golpe que passa causa dano de "fraco" (projétil 6, faísca 2). Todo o resto, **inclusive o cajado**, é bloqueado: dano 0 e `Bloqueou`.
4. **Na brecha**, qualquer golpe acerta o corpo de pedra com dano normal (projétil 3, faísca 1, cajado 1). É a única chance do cajado: vencer só no cajado é possível, mas sofrido.
5. O escudo que vale é o da hora do impacto. O feitiço lê o escudo da hora da conjuração (ADR-001); como o escudo pisca antes de trocar, o jogador consegue evitar a troca no meio do voo.
6. O sentido `alvo.escudo` (e `escudo` em `inimigos`) é o elemento do escudo, ou `None` na brecha.

## Critérios de aceite

### COM-060 — Ciclo do escudo

- **Dado** um `GuardianShield` novo
- **Então** o escudo é `fogo` de 0 a 4 s, nenhum de 4 a 5 s, `planta` de 5 a 9 s, nenhum de 9 a 10 s, `gelo` de 10 a 14 s, e volta a `fogo` aos 15 s; pisca de 3 a 4 s

### COM-061 — Só a fraqueza passa

- **Dado** o escudo de fogo
- **Então** o projétil de gelo passa com dano 6; os projéteis de fogo e de raio, a faísca de fogo e o cajado são bloqueados com dano 0; com o escudo de planta, passa o fogo; com o de gelo, passa o raio

### COM-062 — A brecha

- **Dado** o guardião sem escudo
- **Então** o cajado dá 1, o projétil de fogo dá 3 e a faísca de raio dá 1

### COM-063 — O escudo na foto do mundo (cena)

- **Dado** o guardião com escudo de planta
- **Então** o alvo tem `"escudo": "planta"`; na brecha, `"escudo": null`

### COM-064 — Encontro com Python real (aceitação, `sala_c03`)

- **Dado** a sala do guardião
- **Quando** o mago conjura, em momentos com escudos diferentes, o feitiço que lê o escudo (com dicionário, ou com `if`)
- **Então** todo golpe passa e três conjurações derrotam o guardião
- **E** o feitiço fixo `lancar(gelo, projetil, alvo)` só causa dano quando o escudo é fogo (ou na brecha)

## Exemplos

```python
vence = {"fogo": gelo, "planta": fogo, "gelo": raio}
if alvo.escudo is None:
    lancar(fogo, projetil, alvo)
else:
    lancar(vence[alvo.escudo], projetil, alvo)
```

## Perguntas em aberto

- [ ] 4 s de escudo e 1 s de brecha são justos? (playtest)
