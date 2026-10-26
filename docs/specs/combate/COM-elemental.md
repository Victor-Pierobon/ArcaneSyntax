# COM-elemental — Elemental

- **Status:** Implementada
- **Sprint:** 10
- **Relacionadas:** COM-dano, MAG-elementos, MUN-salas

## Contexto

O primeiro inimigo ensina que o elemento importa: cada elemental tem uma fraqueza, e o feitiço que lê `alvo.elemento` e escolhe o ataque (o "feitiço que pensa" do GDD) vence todos com um slot só.

## Fora do escopo

Ataques à distância. Elementais que voam ou caem de plataformas.

## Regras

1. Em `targets`: `inimigo:elemental:<elemento>`, com elemento `fogo`, `gelo` ou `planta` (sem elemento: `fogo`). Elemento desconhecido é erro de autoria.
2. Vida **12**, dano de contato **1** (COM-dano). Fraquezas pela tabela de MAG-elementos: fogo perde para gelo, gelo para raio, planta para fogo.
3. **Comportamento** (`ElementalBrain`, regra pura):
   - **Patrulha:** anda a **30 px/s** entre 3 tiles à esquerda e 3 tiles à direita do ponto onde nasceu, virando nas pontas.
   - **Perseguição:** quando o mago está a até **6 tiles** na horizontal e a até **2 tiles** de altura, anda na direção dele a **45 px/s**. O mago anda a ~120 px/s, então dá para fugir.
   - Quando o mago sai desse alcance, volta a patrulhar a partir de onde está.
4. O elemental **anda no chão em que nasceu**: só avança se o tile à frente, na altura do corpo, está livre e o tile embaixo dele é sólido (pedra ou plataforma). Se não puder avançar, vira (patrulha) ou espera (perseguição).

## Critérios de aceite

### COM-020 — Patrulha

- **Dado** um elemental num chão largo, sem o mago por perto
- **Então** anda para um lado até 3 tiles do ponto inicial, vira, e vai até 3 tiles do outro lado

### COM-021 — Perseguição

- **Dado** o mago a 5 tiles à esquerda, na mesma altura
- **Então** o elemental anda para a esquerda a 45 px/s; com o mago a 5 tiles mas 3 tiles acima, continua patrulhando

### COM-022 — Não cai nem atravessa parede

- **Dado** um elemental perto de uma beirada (ou de uma parede)
- **Então** na patrulha ele vira antes dela; perseguindo o mago do outro lado, para na beirada

### COM-023 — Perde o mago

- **Dado** o elemental perseguindo
- **Quando** o mago fica a mais de 6 tiles
- **Então** volta a patrulhar

### COM-024 — Elemento errado (cena)

- **Dado** os elementais de fogo, gelo e planta
- **Então** `alvo.elemento` de cada um é o seu elemento, e cada um vence com dois projéteis da sua fraqueza (6 + 6)

### COM-025 — Encontro com Python real (aceitação, `sala_c01`)

- **Dado** a sala com um elemental de fogo e um de gelo, e o mago com mana suficiente
- **Quando** conjura o feitiço adaptável (COM-dano, exemplo) duas vezes em cada um
- **Então** os dois são derrotados
- **E** o feitiço fixo `lancar(fogo, projetil, alvo)` precisa de 12 projéteis no elemental de fogo, e o cajado, de 12 golpes

## Perguntas em aberto

- [ ] Vida 12 e 45 px/s deixam a luta tensa sem ser injusta no cajado? (playtest)
