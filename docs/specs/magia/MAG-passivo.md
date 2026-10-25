# MAG-passivo — O slot passivo e a mana viva

- **Status:** Implementada
- **Sprint:** 7
- **Relacionadas:** GRI-slots (mana pela variação), MAG-acoes, EXE-custo (EXE-049), GDD "Feitiços passivos"

## Contexto

Além dos 5 slots, o grimório tem um slot passivo que o jogo executa continuamente. Ele gasta mana por operação, então só compensa se for bem escrito (GDD). É o lugar natural dos feitiços que reagem ao mundo, porque roda de novo a cada ciclo com uma foto nova (ADR-001).

## Regras

1. O grimório tem **um slot passivo**, separado dos 5. No grimório, o botão **Passivo** equipa o feitiço selecionado (apertar de novo desequipa). Renomear acompanha; apagar esvazia. É salvo no arquivo do grimório no campo `"passivo"` (opcional; um nome que não existe vira vazio).
2. Com o mundo rodando, o passivo é executado **a cada 1 s**, com o estado real do mago, o alvo atual e as peças desbloqueadas, e a mana muda **pela variação**, igual a uma conjuração.
3. **Sem sobreposição:** se a execução anterior ainda não voltou, o ciclo é pulado.
4. Com o jogo pausado (grimório aberto), o passivo não roda.
5. **Erro desliga o passivo:** qualquer erro, exceto `ManaEsgotada` e `ExecutorIndisponivel`, desliga o passivo e avisa uma vez no registro. Ele volta a ligar quando o código do feitiço muda ou quando o passivo é equipado de novo.
6. `ManaEsgotada` **não** desliga (o passivo tenta de novo no próximo ciclo) e só aparece no registro na primeira vez seguida, para não poluir.
7. As ações do passivo tocam num **`ActionPlayer` próprio**, então não atrasam as conjurações dos slots.
8. Resultados sem erro do passivo **não** aparecem no registro (seria um a cada segundo).
9. O HUD mostra o passivo: `Passivo: <nome>`, `Passivo: <nome> (desligado)` ou `Passivo: —`.

## Critérios de aceite

### MAG-050 — Equipar o passivo

- **Quando** equipa "Recarregar" no passivo, renomeia para "Recarga" e depois apaga
- **Então** o passivo acompanha o nome e fica vazio ao apagar; salvar e carregar preserva o passivo; o botão do grimório equipa e desequipa

### MAG-051 — Roda a cada segundo

- **Dado** um passivo equipado e o mundo rodando
- **Então** o executor recebe o código do passivo com o estado real a cada 1 s, e a mana muda pela variação

### MAG-052 — Sem sobreposição

- **Dado** uma execução do passivo que demora mais de 1 s
- **Então** só há uma requisição em andamento por vez

### MAG-053 — Pausado não roda

- **Dado** o grimório aberto
- **Então** o passivo não é executado

### MAG-054 — Erro desliga e editar religa

- **Quando** o passivo dá `NameError`
- **Então** fica desligado, o registro avisa uma vez, o executor não é mais chamado; ao editar o código do feitiço, volta a rodar

### MAG-055 — Mana esgotada não desliga

- **Quando** o passivo dá `ManaEsgotada` duas vezes seguidas
- **Então** continua ligado e o registro mostra o aviso uma única vez

### MAG-056 — Não atrasa as conjurações

- **Dado** o passivo tocando ações
- **Quando** o jogador conjura um slot
- **Então** as ações da conjuração começam sem esperar as do passivo

### MAG-057 — HUD

- **Então** o HUD mostra `Passivo: —` sem passivo, o nome quando ligado e `(desligado)` depois de um erro

### MAG-058 — O passivo do GDD enche a mana (Python de verdade)

- **Dado** mana 0 e o passivo `while mana < mana_max:\n    absorver_mana()`
- **Então** em até 3 s a mana chega ao máximo

### MAG-059 — Checar antes economiza (Python de verdade)

- **Dado** mana cheia
- **Então** o passivo `if mana < mana_max:\n    absorver_mana()` custa 0 por ciclo, e o passivo `while True:\n    absorver_mana()` é desligado por `LimiteExcedido`
