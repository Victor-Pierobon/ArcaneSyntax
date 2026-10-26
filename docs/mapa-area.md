# Mapa da área — Ato I (Fundações e Masmorra)

- **Status:** Decidido pelo Victor e montado na Sprint 14. As regras que os testes verificam estão em `docs/specs/mundo/MUN-mapa.md`
- **Relacionadas:** `docs/sprints/sprint-14-montagem-area.md` (MUN-mapa vem de lá), NAR-serpente, PUZ-01 a PUZ-06, COM-*

## Ideia

A Masmorra é a base da torre. O mago desce em zigue-zague: cada andar ensina um conceito antes da sala que o cobra (o mapa é o currículo, GDD). Hoje as 12 salas existem, mas ligadas em fila, de forma provisória. Este rascunho propõe a forma da área e o que bloqueia cada passagem. A regra de equilíbrio vale: **nenhuma porta depende só de nível**.

## Desenho

```
                       ┌──────────────┐
                       │   sala_01    │  entrada da torre
                       │ serpente: P1 │  sequência (cristal adormecido)
                       └──────┬───────┘
                              │ porta de runas (P1)
                       ┌──────┴───────┐      ┌──────────────┐
                       │   sala_02    │──────│   sala_03    │  corredores de movimento
                       │ boneco gelo  │      │ espinhos     │  (treino de pulo/esquiva)
                       └──────────────┘      └──────┬───────┘
                                                    │ descida
  ┌──────────────┐     ┌──────────────┐      ┌──────┴───────┐
  │  sala_p04    │─────│  sala_p03    │──────│  sala_p02    │  variáveis (runas e Σ)
  │ loops: ponte │     │ condicionais │      │ serpente: P2 │
  └──────┬───────┘     │ cristal      │      └──────────────┘
         │             └──────────────┘
  ┌──────┴───────┐     ┌──────────────┐
  │  sala_p05    │─────│  sala_p06    │  revisão (os quatro mecanismos)
  │ funções:     │     │ serpente: P6 │
  │ elevador     │     └──────┬───────┘
  └──────────────┘            │ porta (P6)
                       ┌──────┴───────┐      ┌──────────────┐
                       │  sala_c01    │──────│  sala_c02    │  enxame (loop sobre a lista)
                       │ elementais   │      └──────┬───────┘
                       │ (condicionais)│            │
                       └──────────────┘      ┌──────┴───────┐      ┌──────────────┐
                                             │  sala_c03    │──────│  sala_c04    │  chefe
                                             │ guardião     │      │ (adaptável)  │
                                             │ (ler sentido)│      └──────────────┘
                                             └──────────────┘
```

## Passagens e o que as bloqueia

| De → para | Bloqueio | Conceito exigido | Já ensinado em |
| --- | --- | --- | --- |
| sala_01 → sala_02 | porta de runas do P1 | sequência | sala_01 (serpente) |
| sala_02 → sala_03 | nenhum | — | — |
| sala_03 → sala_p02 | nenhum (descida) | — | — |
| sala_p02 → sala_p03 | porta do P2 | variáveis | sala_p02 |
| sala_p03 → sala_p04 | porta do P3 | condicionais | sala_p03 |
| sala_p04 → sala_p05 | ponte do P4 | loops | sala_p04 |
| sala_p05 → sala_p06 | colunas do P5 | funções | sala_p05 |
| sala_p06 → sala_c01 | porta do P6 | revisão | sala_p02 a p05 |
| sala_c01 → c02 → c03 | inimigos (não bloqueiam a passagem; dá para fugir) | condicionais, loops, ler sentidos | P3, P4 |
| sala_c03 → sala_c04 | nenhum | — | — |
| sala_c04 → sala_fim | porta do chefe | tudo do ato | — |
| sala_c01 → sala_01 | atalho de mão única (abre por trás) | — | — |

Na Sprint 14 entraram também os baús da `sala_02` e da `sala_03` e a fonte da `sala_c03`, e todas as portas passaram a ir do chão ao teto (com `levitar`, dava para voar por cima da porta do P1).

## Para decidir no papel (Victor)

- [x] Os corredores `sala_02` e `sala_03` continuam só de movimento, ou ganham um segredo cada? **Victor (Sprint 14): um segredo cada, mas o jogador deve ser recompensado por resolver de várias formas, não de uma forma específica.** Cada baú tem um caminho com feitiço e um só com pulo e esquiva (MUN-segredos).
- [x] Atalho de volta: depois do P6, uma passagem de mão única para a `sala_01`? **Sim**: a saída alta da `sala_c01` leva à entrada `C` da `sala_01`, atrás de uma porta de atalho que abre por trás.
- [x] Onde ficam os pontos de recuperação de vida? **Uma fonte na `sala_c03`, antes do chefe** (vida e mana com E).
- [x] O que fica atrás da porta do chefe na Alpha? **A `sala_fim`**: a serpente se despede e aparece a tela de fim com o resumo.
