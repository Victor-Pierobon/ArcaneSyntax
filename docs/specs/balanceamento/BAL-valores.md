# BAL-valores — Os números do jogo num lugar só

- **Status:** Implementada
- **Sprint:** 11
- **Relacionadas:** EXE-custo, EXE-protocolo (campo `regras`), EXE-limites, MUN-vida, COM-dano, COM-elemental, COM-enxame, COM-guardiao, COM-chefe

## Contexto

Até a Sprint 10, os números de jogo estavam espalhados em constantes no Godot e em `REGRAS_PADRAO` no executor, e o Godot nunca mandava `regras`. Para calibrar o jogo pelo playtest sem caçar constantes, todos os números de dificuldade e de custo ficam em **um arquivo**, lido pelo jogo, que manda os custos ao executor em toda requisição.

## Fora do escopo

Sensação de movimento (pulo, coyote, esquiva, empurrão, velocidades dos projéteis do mago): continua em `PlayerMotor` e nos nós, ajustada pelo checklist de sensação. Tamanhos de corpo e de desenho. Limites de segurança do executor que não são balanceamento (1000 ações, 200 saídas, 256 MB, watchdog de 3000 ms). Editar o arquivo com o jogo aberto (recarregar ao vivo). Dificuldades selecionáveis.

## Regras

1. O arquivo é `game/content/balanceamento.json`, em JSON, com as seções `mago`, `executor`, `dano`, `elemental`, `enxame`, `guardiao`, `chefe` e, desde a Sprint 12, `xp` e `niveis` (PRO-xp, PRO-niveis; a mana máxima saiu de `mago` e vem do nível). A Sprint 14 acrescentou `xp.segredo` (MUN-segredos). As listas (`chefe.elementos`, `niveis.xp`, `niveis.mana_max`) são validadas pelo tipo dos itens, e as duas de `niveis` precisam ter o mesmo tamanho. Tempos em segundos (`_s`), distâncias em tiles (`_tiles`), velocidades em px/s.
2. Quem lê é a classe `Balance` (Godot), que carrega o arquivo uma vez e guarda o conteúdo. O jogo não tem outro lugar com esses números: as classes que antes tinham constantes passam a perguntar a `Balance`.
3. A seção `executor` tem exatamente as chaves de `REGRAS_PADRAO` (EXE-custo e EXE-limites: ganhos, custos e `limite_tempo_ms`). O `World` e o grimório mandam essa seção como `regras` em **toda** requisição: conjurar, passivo, Testar e estimativa de custo.
4. O executor continua com `REGRAS_PADRAO` como padrão (console de feitiços e testes do executor), mas os valores do arquivo e os do padrão são iguais, e um teste do executor garante isso: mudar um custo exige mudar os dois, e o teste avisa.
5. `Balance.validate` confere o arquivo: toda chave que o jogo lê existe e é número (ou lista de elementos, em `chefe.elementos`). O arquivo do jogo não tem erros. Arquivo ilegível, chave faltando ou valor inválido geram uma mensagem com o caminho da chave (ex.: `balanceamento: falta "chefe.vida"`) e o jogo usa 0 para o que faltar, sem travar.
6. Os testes podem carregar outro arquivo (`Balance.use_file`) e voltar ao do jogo (`Balance.reset`).
7. Os valores atuais (Sprint 10 + chefe da Sprint 11) não mudam com a mudança de lugar: as suítes continuam verdes sem ajuste.

## Critérios de aceite

### BAL-001 — O arquivo do jogo é válido

- **Dado** `res://content/balanceamento.json`
- **Então** `Balance.validate` não devolve erros, e `Balance.number("chefe", "vida")` é 30

### BAL-002 — Erros apontam a chave

- **Dado** um arquivo sem `chefe.vida` e com `dano.projetil` igual a `"três"`
- **Então** `validate` devolve `falta "chefe.vida"` e `"dano.projetil" não é número`; um arquivo que não é JSON devolve um erro de leitura
- **E** `Balance.number` de uma chave que falta devolve 0

### BAL-003 — Os números mudam o jogo

- **Dado** um arquivo de teste com vida do elemental 20, dano do projétil 4 e custo de `lancar` 5
- **Então** um elemental novo tem vida 20, o projétil normal dá 4 e as `regras` da requisição levam `custo_lancar` 5

### BAL-004 — As regras vão em toda requisição (cena)

- **Dado** o mundo com um `FakeSpellExecutor`
- **Quando** o mago conjura, o passivo roda e o grimório testa e estima
- **Então** toda requisição leva `regras` igual à seção `executor` do arquivo

### BAL-005 — Executor e arquivo concordam (pytest)

- **Então** a seção `executor` de `game/content/balanceamento.json` é igual a `REGRAS_PADRAO`

## Exemplos

```json
{
  "mago": {"vida": 5, "invencivel_s": 1.0},
  "executor": {"ganho_meditar": 5, "custo_lancar": 3, "custo_faisca": 1, "...": "..."},
  "dano": {"projetil": 3, "faisca": 1, "cajado": 1, "contato": 1, "fraco": 2, "normal": 1, "resiste": 0.5},
  "chefe": {"vida": 30, "elementos": ["fogo", "gelo"], "troca_vida": 15, "transicao_s": 1.5}
}
```

## Perguntas em aberto

- [ ] Vale recarregar o arquivo com uma tecla de desenvolvedor, para calibrar sem reabrir o jogo? (depois do playtest)
