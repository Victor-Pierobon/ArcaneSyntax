# GRI-slots — Os 5 slots e a conjuração

- **Status:** Implementada
- **Sprint:** 5
- **Relacionadas:** GRI-feiticos, GRI-erros, MUN-alvos, MUN-vida (`MagoState`), EXE-desbloqueio

## Contexto

Cinco feitiços ficam ligados a teclas e são conjurados na hora (GDD). Esta sprint liga o grimório ao executor: o código roda de verdade e gasta a mana do HUD. As ações ainda não acontecem no mundo (Sprint 6); aparecem num **registro de conjuração** na tela.

## Regras

**Slots**

1. O grimório tem **5 slots** (teclas **1** a **5**). Cada slot guarda o nome de um feitiço ou fica vazio. O mesmo feitiço pode estar em mais de um slot.
2. Renomear um feitiço atualiza os slots; apagar esvazia os slots dele (sinal `slots_changed`).
3. Os slots são salvos no mesmo arquivo do grimório, no campo `"slots"` (lista de 5 nomes, `""` para vazio). Arquivos antigos sem o campo continuam válidos. Um nome que não existe mais vira slot vazio; um campo com formato errado torna o arquivo ilegível (GRI-feiticos, regra 9).
4. No grimório, os botões **1–5** equipam o feitiço selecionado no slot (apertar de novo no slot que já tem esse feitiço o desequipa). Equipar salva no disco.
5. O HUD mostra os 5 slots com o nome de cada feitiço (ou `—`).

**Conjurar**

6. Apertar a tecla de um slot com o mundo rodando (grimório fechado) envia ao executor: o código do feitiço, o estado real do mago (`MagoState.to_spell_mago()`), o alvo atual (MUN-alvos) e as peças desbloqueadas (`MagoState.unlocked_pieces`).
7. Com o resultado, a mana do mago muda pela **variação** (`mana final − mana enviada`), e não pelo valor absoluto. Assim, duas conjurações seguidas não apagam o efeito uma da outra.
8. O resultado vai para o **registro de conjuração** (as últimas 6 linhas na tela): ações, visões (`print`) e custo; ou o erro, com a frase no mundo (GRI-erros).
9. Slot vazio: o registro avisa e nada é enviado.
10. Com o jogo pausado (grimório aberto), as teclas de slot não conjuram.
11. Todas as peças da Alpha começam desbloqueadas, menos o `feixe`, que a serpente da `sala_c03` ensina (Sprint 21, MAG-feixe, regra 8); o mecanismo já estava ligado.

## Critérios de aceite

### GRI-030 — Equipar e esvaziar

- **Dado** os feitiços "Fogo" e "Gelo"
- **Quando** equipa "Fogo" nos slots 1 e 3 e depois esvazia o 3
- **Então** os slots são `["Fogo", "", "", "", ""]`; equipar um nome inexistente dá `NOT_FOUND`; slot fora de 1–5 dá `INVALID_SLOT`

### GRI-031 — Renomear e apagar mexem nos slots

- **Quando** "Fogo" vira "Chama" e depois "Gelo", equipado no slot 2, é apagado
- **Então** o slot 1 mostra "Chama" e o slot 2 fica vazio, com `slots_changed` emitido

### GRI-032 — Slots salvos

- **Quando** salva e carrega
- **Então** os slots voltam iguais; um arquivo sem `slots` carrega com todos vazios; um nome inexistente vira vazio; `slots` com tamanho errado torna o arquivo ilegível

### GRI-033 — Equipar pelo grimório

- **Quando** aperta o botão 2 com "Fogo" selecionado
- **Então** o slot 2 tem "Fogo" e o disco também; apertar 2 de novo esvazia

### GRI-034 — HUD mostra os slots

- **Então** o HUD lista `1 Fogo`, `2 —` … e acompanha as mudanças

### GRI-040 — Conjurar envia o estado real

- **Dado** "Fogo" no slot 1, mana 7 e um boneco de fogo por perto
- **Quando** conjura o slot 1
- **Então** o executor recebe o código do feitiço, `mago` com mana 7, o alvo do boneco e a lista de peças desbloqueadas

### GRI-041 — Mana pela variação

- **Dado** mana 10, e o executor responde mana final 6.9 para uma mana enviada de 10
- **Quando** antes da resposta chegar a mana real vai a 8
- **Então** a mana final é 4.9

### GRI-042 — Registro de conjuração

- **Quando** uma conjuração termina
- **Então** o registro mostra o slot, o nome, as ações, as visões e o custo; com erro, mostra a frase no mundo

### GRI-043 — Slot vazio

- **Quando** conjura um slot vazio
- **Então** o registro avisa e o executor não é chamado

### GRI-044 — Pausado não conjura

- **Dado** o grimório aberto
- **Então** a tecla de slot não chama o executor

### GRI-045 — De ponta a ponta com o Python de verdade

- **Dado** o feitiço `meditar()` no slot 1, mana 0, executor real
- **Quando** conjura
- **Então** a mana do mago vai a 4.8 (4,9 antes do custo de inscrição da Sprint 9)
