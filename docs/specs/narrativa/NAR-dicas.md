# NAR-dicas — Dicas em três níveis

- **Status:** Implementada
- **Sprint:** 13
- **Relacionadas:** NAR-serpente, NAR-dialogo, SAV-progresso, PUZ-01 a PUZ-06, GDD ("Os mascotes como sistema de dicas")

## Contexto

"Quando o jogador trava, o mascote ajuda em três níveis: primeiro lembra o conceito, depois sugere a estrutura do código, e só por último mostra um exemplo parcial" (GDD). As dicas são opcionais, sempre pedidas pelo jogador, e nunca entregam a solução inteira.

## Fora do escopo

Dicas que aparecem sozinhas (por tempo travado ou por erros repetidos). Penalidade por usar dica (estrelas e XP não mudam). Dicas para o combate.

## Regras

1. As dicas ficam em `game/content/dicas.json`: `{"<puzzle_id>": ["CHAVE_1", "CHAVE_2", "CHAVE_3"]}`, as chaves no `textos.csv`. Nível 1 lembra o conceito; nível 2 sugere a estrutura; nível 3 mostra um exemplo parcial (com lacunas ou com outros números).
2. Todo puzzle das salas do jogo tem exatamente **3** dicas, e toda chave existe (teste de conteúdo).
3. A cena da dica é montada pelo jogo (`HintBook.scene(puzzle, nível)`) no formato de NAR-dialogo:
   - fala `pergunta`: "Quer uma dica? Esta é a N de 3." (`SERPENTE_DICA_PERGUNTA_N`), com as opções **Sim** → `dica` e **Agora não** → `nao`;
   - fala `dica`: o texto da dica daquele nível;
   - fala `nao`: "Tudo bem. Tentar sozinho também ensina."
4. O nível oferecido é o **próximo**: 1 na primeira vez, depois 2, depois 3. A dica **conta como usada** só quando a fala `dica` aparece. Depois da terceira, falar de novo oferece a terceira outra vez.
5. As dicas usadas por puzzle (`World.hints_used`) são guardadas no save (SAV-progresso).
6. Usar dica não muda estrelas nem XP.

## Critérios de aceite

### NAR-040 — Conteúdo das dicas

- **Então** `res://content/dicas.json` tem 3 dicas para cada um dos 6 puzzles (`p01_meditar` a `p06_revisao`), e `HintBook.validate` não acusa erros
- **E** `validate` acusa puzzle com 2 dicas e chave ausente no `textos.csv`, com o id do puzzle na mensagem

### NAR-041 — A cena da dica

- **Então** `HintBook.scene("p02_runas", 2)` é uma cena válida (NAR-dialogo) que começa em `pergunta`, cujas opções levam a `dica` (texto da 2ª dica) e a `nao`

### NAR-042 — Os níveis avançam só quando a dica aparece (cena)

- **Dado** a lição vista e o puzzle sem solução
- **Quando** o mago fala com a serpente e responde "Agora não"
- **Então** nenhuma dica foi usada; falando de novo e respondendo "Sim", vê a dica 1 e `hints_used` do puzzle vira 1
- **E** as próximas conversas oferecem a 2 e a 3; depois da 3, oferecem a 3 de novo, e `hints_used` fica em 3

## Exemplos

P4 (ponte): 1. "Lembra do loop? Ele repete o que está dentro dele." 2. "Um `for` com `range` e o `construir_bloco()` dentro, indentado." 3. "`for i in range(…):` / `    construir_bloco()` — quantos blocos tem o vão?"
