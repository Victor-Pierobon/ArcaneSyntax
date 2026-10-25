# EXE-erros — Erros do feitiço

- **Status:** Implementada
- **Sprint:** 1
- **Relacionadas:** EXE-protocolo, GDD "Erros"

## Contexto

O GDD exige a mensagem real da linguagem com a linha marcada, para o aprendizado sair do jogo. A tradução para o mundo ("a runa da linha 4 está malformada") e a explicação da serpente ficam no Godot (Sprint 5); o executor entrega os dados crus e corretos.

## Regras

1. Formato: `"erro": {"tipo": "NameError", "mensagem": "name 'x' is not defined", "linha": 3, "coluna": null}`.
2. `tipo` é o nome da classe da exceção Python; `mensagem` é `str(exceção)` (para `SyntaxError`, o texto `msg`).
3. `linha` é sempre do código do jogador, nunca do executor. Se o erro nasce dentro de uma peça, a linha é a da chamada.
4. `coluna` só é preenchida em erros de sintaxe (1 = primeira coluna); nos demais é null.
5. Erro de sintaxe: nada roda, então `acoes` e `saidas` vêm vazias. Erro durante a execução: o que rodou antes fica na resposta (EXE-protocolo, regra 5).
6. Detalhes internos do executor (caminhos de arquivo, frames do executor) nunca aparecem na mensagem.

## Critérios de aceite

### EXE-030 — Erro de sintaxe

- **Quando** o feitiço é `x = 1\nif x > 0\n    meditar()`
- **Então** `erro.tipo` é `"SyntaxError"`, `erro.linha` é 2, `erro.coluna` é um número, e não há ações

### EXE-031 — Erro de indentação

- **Quando** o feitiço é `if True:\nmeditar()`
- **Então** `erro.tipo` é `"IndentationError"` e `erro.linha` é 2

### EXE-032 — Erro de execução com linha

- **Quando** o feitiço é `meditar()\nprint(x)`
- **Então** `erro` é `{"tipo": "NameError", "mensagem": "name 'x' is not defined", "linha": 2, "coluna": null}`

### EXE-033 — Execução parcial preservada

- **Quando** o feitiço é `print("antes")\nmeditar()\n1 / 0\nmeditar()`
- **Então** há 1 ação `meditar`, a saída `antes`, e `erro.tipo` `"ZeroDivisionError"` na linha 3

### EXE-034 — Erro dentro de peça aponta a linha do jogador

- **Quando** o feitiço é `\n\nlevitar(-1)`
- **Então** `erro.tipo` é `"ValueError"` e `erro.linha` é 3

### EXE-035 — Erro dentro de função do jogador

- **Quando** o feitiço define uma função na linha 1 cujo corpo, na linha 2, faz `return 1 / 0`, e a chama na linha 3
- **Então** `erro.linha` é 2 (onde o erro aconteceu)

### EXE-036 — Sem vazamento de detalhes internos

- **Dado** qualquer erro
- **Então** `erro.mensagem` não contém o caminho do executor nem `arcane_executor`

### EXE-037 — Feitiço não derruba o worker

- **Quando** o feitiço faz `raise SystemExit`
- **Então** a resposta é um erro comum com `erro.tipo` `"SystemExit"` e o worker continua atendendo
