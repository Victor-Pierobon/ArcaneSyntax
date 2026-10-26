# GRI-referencia — Páginas de referência

- **Status:** Implementada
- **Sprint:** 12, 13
- **Relacionadas:** GRI-grimorio, EXE-desbloqueio, EXE-pecas, NAR-dialogo, GDD (Interface e feedback)

## Contexto

"Cada peça e cada conceito ganha uma página no grimório, escrita pelo mascote, que o jogador consulta quando quiser" (GDD). Esta sprint entrega a aba de referência e as páginas das peças que já existem. As páginas de conceito (sequência, variáveis, condicionais, loops, funções) entram na Sprint 13, junto com os ensinamentos da serpente.

## Fora do escopo

Páginas de conceito (Sprint 13). Busca, favoritos e links entre páginas. Abrir a página da peça sob o cursor do editor.

## Regras

1. As páginas ficam em `game/content/referencia.json`, uma lista em ordem: `[{"id": "lancar", "requer": ["lancar"]}, ...]`. O título e o texto são as chaves `REF_<ID>_TITULO` e `REF_<ID>_TEXTO` do `textos.csv` (id em maiúsculas).
2. O texto aceita BBCode simples (`[b]`, `[code]`) e quebras de linha (`\n` no `textos.csv`). É escrito na voz da serpente.
3. Uma página só aparece se **todas** as peças de `requer` estão desbloqueadas (EXE-desbloqueio). `requer` vazio: sempre aparece.
4. **Erros de autoria** (`ReferenceBook.validate`): arquivo ilegível, página sem `id`, id repetido, chave de título ou texto ausente no `textos.csv`, peça de `requer` que não existe. O arquivo do jogo não tem erros.
5. O grimório tem duas abas: **Feitiços** (o que já existia) e **Referência**: lista de páginas à esquerda e o texto da selecionada à direita. Abre na primeira página visível. Trocar de aba não perde o feitiço em edição.
6. Páginas desta sprint: `lancar`, `elementos`, `formas`, `mover`, `levitar`, `meditar`, `absorver_mana`, `inscrever`, `construir_bloco`, `sentidos` (`mana`, `mana_max`, `vida_atual`), `alvo` (`alvo` e `inimigos`), `ler_runa` e `print`.
7. Desde a Sprint 13, cinco páginas de **conceito**, sem requisito, depois das peças: `sequencia`, `variaveis`, `condicionais`, `loops` e `funcoes` (NAR-serpente, regra 5).

## Critérios de aceite

### GRI-080 — Páginas visíveis pelo desbloqueio

- **Dado** as páginas `a` (requer `lancar`), `b` (requer `lancar` e `gelo`) e `c` (sem requisito)
- **Quando** só `lancar` está desbloqueada
- **Então** `visible_pages` é `a` e `c`, nessa ordem

### GRI-081 — Erros de autoria

- **Dado** páginas com id repetido, peça `voar` em `requer` e id `sem_texto` sem chaves no `textos.csv`
- **Então** `validate` acusa cada um, com o id da página

### GRI-082 — O conteúdo do jogo é válido

- **Então** `res://content/referencia.json` não tem erros, tem as 18 páginas das regras 6 e 7, na ordem, e o texto da página `lancar` tem quebra de linha e cita `lancar(`

### GRI-083 — Aba de referência (cena)

- **Dado** o grimório aberto, com um feitiço em edição
- **Quando** troca para a aba Referência
- **Então** a lista mostra os títulos das páginas visíveis e o texto da primeira; selecionar outra mostra o texto dela
- **Quando** volta para a aba Feitiços
- **Então** o feitiço e o texto em edição estão como antes

### GRI-084 — Peça bloqueada esconde a página (cena)

- **Dado** o mago sem `levitar` desbloqueado
- **Então** a aba Referência não lista a página `levitar`

## Perguntas em aberto

- [ ] Vale um atalho no editor (F1 sobre a peça) para abrir a página dela? (depois do playtest)
