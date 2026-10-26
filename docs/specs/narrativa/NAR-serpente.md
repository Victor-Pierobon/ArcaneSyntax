# NAR-serpente — A serpente ensina

- **Status:** Implementada
- **Sprint:** 13
- **Relacionadas:** NAR-dialogo, NAR-dicas, SAV-progresso, GRI-referencia, PUZ-01 a PUZ-06, GDD (Personagens; Currículo)

## Contexto

A serpente é a primeira mentora (GDD): curiosa, falante e paciente. Cada sala de puzzle do Ato I ensina um conceito, e ela o apresenta antes de o jogador tentar. Esta spec define onde ela aparece, o que fala primeiro e quando a lição conta como vista. As dicas ficam em NAR-dicas.

## Fora do escopo

Retrato, voz e animação. Falas no combate e no chefe. Falas que reagem a erros do feitiço (ex.: depois de um `SyntaxError`). Conceitos dos atos seguintes.

## Regras

1. Há uma serpente em cada sala de puzzle, perto da entrada, com uma cena de **lição** (`serpente:<cena>` em `targets`):

   | Sala | Puzzle | Cena | Conceito |
   | --- | --- | --- | --- |
   | `sala_01` | P1 | `ensino_sequencia` | apresentação e sequência |
   | `sala_p02` | P2 | `ensino_variaveis` | variáveis |
   | `sala_p03` | P3 | `ensino_condicionais` | condicionais |
   | `sala_p04` | P4 | `ensino_loops` | loops |
   | `sala_p05` | P5 | `ensino_funcoes` | funções |
   | `sala_p06` | P6 | `ensino_revisao` | revisão dos cinco |

2. Toda cena de lição tem uma fala com id **`licao`**, o coração do ensinamento. A lição **conta como vista** quando essa fala aparece. Recusar a conversa antes dela (ex.: "Agora não" na apresentação) não conta.
3. Ao falar com a serpente (tecla E):
   - lição ainda não vista → toca a lição;
   - lição vista e puzzle da sala sem solução → oferece a próxima dica (NAR-dicas);
   - lição vista e puzzle resolvido (ou sala sem puzzle) → toca a lição de novo.
4. As lições vistas são guardadas no save (SAV-progresso).
5. O texto segue a voz da serpente: frases curtas, um exemplo de código pequeno, sem dar a solução do puzzle. A lição termina apontando a página de conceito na Referência (GRI-referencia).
6. A cena de teste `serpente_ola` da Sprint 12 deixa de existir: a apresentação vira o começo de `ensino_sequencia`.

## Critérios de aceite

### NAR-020 — Toda sala de puzzle tem a sua serpente (conteúdo)

- **Então** cada sala da tabela tem um `serpente:<cena>` com a cena da tabela, e cada cena existe, é válida (NAR-004) e tem a fala `licao`

### NAR-021 — Primeira conversa é a lição (cena)

- **Dado** uma sala com puzzle sem solução e a serpente da lição `ensino_sequencia`
- **Quando** o mago fala com ela e a conversa passa pela fala `licao`
- **Então** a lição fica em `World.seen_lessons`
- **E** recusando antes da `licao` ("Agora não"), ela não fica

### NAR-022 — Depois da lição, a dica (cena)

- **Dado** a lição vista e o puzzle sem solução
- **Quando** o mago fala com a serpente
- **Então** a cena aberta é a da próxima dica (NAR-dicas)

### NAR-023 — Puzzle resolvido repete a lição (cena)

- **Dado** a lição vista e o puzzle resolvido
- **Quando** o mago fala com a serpente
- **Então** a cena aberta é a lição de novo

## Exemplos

Lição de loops (resumo): "Repetir uma linha 12 vezes funciona, mas cada linha nova custa a inscrição. O `for` escreve uma vez e repete: `for i in range(3): meditar()`. Na Referência tem a página Loops."
