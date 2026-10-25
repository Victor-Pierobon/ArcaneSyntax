# GRI-feiticos — Feitiços do grimório e como são guardados

- **Status:** Implementada
- **Sprint:** 4
- **Relacionadas:** GRI-grimorio; Sprint 5 (slots), Sprint 13 (save completo)

## Contexto

O grimório guarda todos os feitiços que o jogador escreveu, para reaproveitar em qualquer parte da torre (GDD). É o primeiro dado do jogador gravado em disco, então perder ou corromper esse arquivo é inaceitável.

## Fora do escopo

Slots e conjuração (Sprint 5); save do resto do progresso (Sprint 13); perfis múltiplos.

## Regras

1. Cada feitiço tem **nome** e **código**. A lista mantém a ordem de criação.
2. **Nome:** espaços nas pontas são removidos; não pode ficar vazio; no máximo **24** caracteres; único sem diferenciar maiúsculas de minúsculas ("Fogo" e "fogo" são o mesmo nome).
3. Renomear segue as mesmas regras; mudar só maiúsculas/minúsculas do próprio nome é permitido.
4. Criar, renomear, apagar e editar código emitem sinais (`spell_created`, `spell_renamed`, `spell_deleted`, `spell_code_changed`). Os slots da Sprint 5 vão ouvir `spell_renamed` e `spell_deleted`.
5. Nome padrão de um feitiço novo: `Feitiço N`, com o menor N livre.
6. **Arquivo:** `user://grimorio.json`, em JSON legível: `{"versao": 1, "feiticos": [{"nome": "...", "codigo": "..."}]}`.
7. **Gravação atômica:** grava num `.tmp` e só então substitui o arquivo, para uma queda no meio não destruir o grimório.
8. **Arquivo inexistente:** grimório vazio, sem erro.
9. **Arquivo ilegível** (não é JSON, formato errado, nomes inválidos ou de versão mais nova): o jogo abre com o grimório vazio, avisa o jogador, e **antes de qualquer novo salvamento** copia o arquivo original para `grimorio.json.bak`.
10. O grimório começa vazio: o primeiro feitiço nasce no Puzzle 1 (Sprint 8).

## Critérios de aceite

### GRI-010 — Criar

- **Quando** cria "Bola de fogo" e depois "Escudo"
- **Então** a lista é `["Bola de fogo", "Escudo"]`, nessa ordem, e o código de cada um começa vazio (ou o código informado)

### GRI-011 — Nome vazio e espaços

- **Quando** cria `""` ou `"   "`
- **Então** é recusado com `EMPTY_NAME`; `"  Raio  "` vira `"Raio"`

### GRI-012 — Nome repetido

- **Dado** "Fogo" existe
- **Quando** cria "fogo" ou "FOGO "
- **Então** é recusado com `DUPLICATE_NAME`

### GRI-013 — Nome longo

- **Quando** cria um nome com 25 caracteres
- **Então** é recusado com `NAME_TOO_LONG`; com 24, é aceito

### GRI-014 — Renomear

- **Dado** "Fogo" e "Gelo"
- **Quando** renomeia "Fogo" para "Chama"
- **Então** a lista é `["Chama", "Gelo"]` (mesma posição), o código vai junto e `spell_renamed("Fogo", "Chama")` é emitido; renomear para "gelo" dá `DUPLICATE_NAME`; renomear "Gelo" para "GELO" é permitido; renomear um nome inexistente dá `NOT_FOUND`

### GRI-015 — Apagar

- **Quando** apaga "Fogo"
- **Então** sai da lista e `spell_deleted("Fogo")` é emitido; apagar de novo dá `NOT_FOUND`

### GRI-016 — Editar código

- **Quando** muda o código de "Fogo"
- **Então** `code_of("Fogo")` devolve o novo código e `spell_code_changed("Fogo")` é emitido; mudar para o mesmo código não emite nada

### GRI-017 — Nome padrão

- **Dado** "Feitiço 1" e "Feitiço 3" existem
- **Então** o próximo nome padrão é "Feitiço 2"

### GRI-020 — Salvar e carregar

- **Dado** feitiços com acentos, aspas e várias linhas de código
- **Quando** salva e carrega
- **Então** nomes, códigos e ordem são idênticos

### GRI-021 — Arquivo inexistente

- **Então** carrega um grimório vazio, sem problema reportado

### GRI-022 — Arquivo corrompido

- **Dado** um arquivo que não é JSON, ou um JSON sem `feiticos`, ou com nomes repetidos
- **Quando** carrega
- **Então** o grimório vem vazio, `last_problem` explica o motivo, e o original fica guardado em `.bak` com o conteúdo intacto

### GRI-023 — Versão mais nova

- **Dado** um arquivo com `versao` 2
- **Então** mesmo tratamento do GRI-022 (não sobrescreve sem backup)

### GRI-024 — Gravação atômica

- **Quando** salva sobre um arquivo existente
- **Então** o arquivo final é válido e não sobra `.tmp`
