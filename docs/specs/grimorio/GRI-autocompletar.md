# GRI-autocompletar — Sugestões no editor

- **Status:** Implementada
- **Sprint:** 5
- **Relacionadas:** EXE-desbloqueio, GRI-grimorio

## Contexto

O GDD pede autocompletar das peças conhecidas: ajuda o iniciante a lembrar os nomes sem dar a resposta.

## Regras

1. Enquanto o jogador digita um nome, o editor sugere palavras que **começam** com o que já foi digitado (sem diferenciar maiúsculas).
2. Ordem: peças do jogo e sentidos primeiro, depois builtins (`print`, `range`…), depois palavras-chave (`while`, `def`…).
3. **Só peças desbloqueadas** são sugeridas (sentidos sempre).
4. Funções (peças-ação e builtins) inserem o nome seguido de `(`; constantes e palavras-chave inserem só o nome.
5. Nada é sugerido para um prefixo vazio, nem dentro de comentários.

## Critérios de aceite

### GRI-070 — Sugere pelo começo

- **Quando** o prefixo é `la`
- **Então** `lancar` é sugerido, inserindo `lancar(`; com `me`, aparecem `meditar` e `mover` não aparece

### GRI-071 — Não sugere bloqueadas

- **Dado** `raio` bloqueado
- **Quando** o prefixo é `ra`
- **Então** `raio` não aparece, mas `range` aparece

### GRI-072 — Ordem e grupos

- **Quando** o prefixo é `p`
- **Então** `projetil` vem antes de `print`, que vem antes de `pass`; `print` insere `print(` e `pass` insere `pass`

### GRI-073 — Prefixo vazio e comentário

- **Então** prefixo vazio não sugere nada; o texto antes do cursor `# la` não sugere nada

### GRI-074 — Editor ligado

- **Então** o editor do grimório tem o autocompletar ligado
