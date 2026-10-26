# MAG-elementos — Fogo, gelo, raio e as fraquezas

- **Status:** Implementada (efeitos provisórios)
- **Sprint:** 6
- **Relacionadas:** MAG-formas, MUN-alvos, COM-dano (dano de verdade nos inimigos, Sprint 10)

## Contexto

Elementos diferentes contra alvos diferentes é o que faz o jogador descobrir o feitiço que pensa (GDD, "O feitiço que pensa"). Nesta sprint os bonecos só **mostram** o efeito; dano e vida dos inimigos vêm na Sprint 10, usando a mesma tabela.

## Regras

1. Tabela de efetividade (`ElementTable`), ataque × alvo:

   | Ataque \ Alvo | fogo | gelo | raio | planta | outro |
   | --- | --- | --- | --- | --- | --- |
   | **fogo** | resiste | normal | normal | **fraco** | normal |
   | **gelo** | **fraco** | resiste | normal | normal | normal |
   | **raio** | normal | **fraco** | resiste | normal | normal |
   | **cajado** | normal | normal | normal | normal | normal |

   "Fraco" vale **2×**, "resiste" vale **0,5×**, "normal" vale **1×**.
2. O boneco atingido mostra um texto flutuante: `Fraco!`, `Resistiu` ou `Acertou`, e pisca na cor do ataque. Ele guarda o último elemento recebido e o efeito (para testes e para a Sprint 10).
3. Os nomes dos elementos vêm do executor (EXE-pecas); `planta` existe só como elemento de alvo.

## Critérios de aceite

### MAG-030 — Fraquezas

- **Então** gelo contra fogo, fogo contra planta e raio contra gelo são "fraco" (2×)

### MAG-031 — Resistência

- **Então** cada elemento contra ele mesmo é "resiste" (0,5×)

### MAG-032 — Neutro

- **Então** fogo contra gelo, raio contra planta, cajado contra qualquer um e qualquer ataque contra um elemento desconhecido são "normal" (1×)

### MAG-033 — O boneco mostra o efeito

- **Quando** um boneco de fogo recebe gelo
- **Então** guarda `gelo` e o efeito "fraco", e mostra `Fraco!`
