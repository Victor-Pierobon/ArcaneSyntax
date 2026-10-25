# EXE-protocolo — Protocolo Godot ↔ executor (v1)

- **Status:** Implementada
- **Sprint:** 1
- **Relacionadas:** ADR-001, ADR-002, EXE-pecas, EXE-erros

## Contexto

O jogo envia o código do feitiço e uma foto do mundo; o executor devolve o que o feitiço fez. Esse contrato é a fronteira entre as duas metades do projeto, então ele é testado dos dois lados com as mesmas fixtures (`tests/contract/`).

## Fora do escopo

Custo de mana, limites de mana e tempo, sandbox (Sprint 2: EXE-custo, EXE-limites, EXE-sandbox).

## Regras

1. Transporte: uma requisição JSON por linha no stdin do worker; uma resposta JSON por linha no stdout, na mesma ordem.
2. Requisição:
   ```json
   {
     "versao": 1,
     "id": 7,
     "codigo": "lancar(fogo, projetil, alvo)",
     "mundo": {
       "mago": {"vida": 10, "mana": 5, "mana_max": 20},
       "alvo": {"id": "elemental_1", "elemento": "fogo", "distancia": 4.5}
     },
     "regras": {"ganho_meditar": 5, "ganho_absorver": 1}
   }
   ```
   `mundo.alvo` pode ser `null`. `regras` é opcional; valores ausentes usam o padrão (`ganho_meditar` 5, `ganho_absorver` 1).
3. Resposta:
   ```json
   {
     "versao": 1,
     "id": 7,
     "ok": true,
     "acoes": [{"tipo": "lancar", "linha": 1, "elemento": "fogo", "forma": "projetil", "alvo": "elemental_1"}],
     "saidas": [],
     "mago": {"vida": 10, "mana": 5, "mana_max": 20},
     "erro": null
   }
   ```
   `mago` é o estado do mago simulado no fim da execução (ADR-001).
4. Toda ação e toda saída carregam a `linha` do código do jogador que a gerou.
5. Quando dá erro, `ok` é `false` e `erro` segue EXE-erros. As ações e saídas produzidas **antes** do erro continuam na resposta.
6. Uma requisição inválida nunca derruba o worker: ele responde com erro e segue lendo.

## Critérios de aceite

### EXE-001 — Resposta de sucesso

- **Dado** uma requisição válida com código sem erros
- **Quando** o executor a processa
- **Então** a resposta tem `versao` 1, o mesmo `id`, `ok` true, `erro` null e as listas `acoes` e `saidas`

### EXE-002 — Estado final do mago

- **Dado** um feitiço que muda a mana do mago
- **Quando** termina
- **Então** `mago` traz a mana simulada final

### EXE-003 — Regras padrão

- **Dado** uma requisição sem `regras`
- **Quando** o feitiço chama `meditar()`
- **Então** a mana sobe 5

### EXE-004 — Requisição inválida

- **Dado** uma requisição sem `codigo`, sem `mundo`, com `versao` diferente de 1, ou uma linha que não é JSON
- **Quando** o executor a processa
- **Então** responde `ok` false com `erro.tipo` `"RequisicaoInvalida"`, `erro.linha` null e `mago` null, repetindo o `id` quando ele existir

### EXE-005 — Worker persistente

- **Dado** o worker rodando
- **Quando** recebe três requisições seguidas, uma delas inválida
- **Então** devolve três respostas, na ordem, e continua vivo

### EXE-006 — print não corrompe o protocolo

- **Dado** um feitiço que chama `print`
- **Quando** o worker o executa
- **Então** o stdout contém só a linha JSON da resposta, e o texto aparece em `saidas`

### EXE-007 — Cliente Godot

- **Dado** o `PythonSpellExecutor` no Godot
- **Quando** executa `lancar(fogo, projetil, alvo)` com um alvo no mundo
- **Então** recebe um `SpellResult` com uma ação `lancar` na linha 1, usando o mesmo worker em chamadas seguidas

### EXE-008 — Worker morto é substituído

- **Dado** o worker do Godot foi encerrado de fora
- **Quando** o jogo executa outro feitiço
- **Então** um worker novo é criado e o feitiço roda normalmente

### EXE-009 — Contrato compartilhado

- **Dado** as fixtures em `tests/contract/`
- **Quando** rodam as suítes
- **Então** o executor produz exatamente cada `resposta` a partir da `requisicao`, e o Godot lê cada `resposta` sem perder campos
