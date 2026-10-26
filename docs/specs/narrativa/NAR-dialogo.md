# NAR-dialogo — Sistema de diálogo

- **Status:** Implementada
- **Sprint:** 12
- **Relacionadas:** GDD (Personagens, mascotes como sistema de dicas), NAR-serpente e NAR-dicas (Sprint 13), MUN-alvos, MUN-salas

## Contexto

A serpente ensina conversando (GDD). Esta sprint entrega o **sistema**: cenas de diálogo em arquivo, com falas, escolhas e erros claros, e uma serpente na sala que conversa. O conteúdo de verdade (apresentação, um ensinamento por conceito, dicas) é da Sprint 13.

## Fora do escopo

Conteúdo final das falas (Sprint 13). Retrato, animação e voz. Condições nas falas (ex.: só se o puzzle foi resolvido) e variáveis no texto. Lembrar em disco quais cenas o jogador viu (Sprint 13).

## Regras

1. As cenas ficam em `game/content/dialogos.json`: `{"<cena>": {"inicio": "<fala>", "falas": {"<fala>": {...}}}}`. Cada fala tem:
   - `quem`: quem fala (`serpente` ou `mago`); padrão `serpente`;
   - `texto`: **chave** do `textos.csv` (para traduzir depois da Alpha);
   - e então **uma** destas: `proxima` (id da próxima fala), `opcoes` (lista de `{"texto": chave, "proxima": id}`, de 1 a 3), ou nada (a fala encerra a cena).
2. **Erros de autoria** (`DialogueBook.validate`) com mensagem clara, que diz cena e fala: arquivo ilegível; cena sem `inicio`; `inicio` ou `proxima` apontando para fala que não existe; `texto` cuja chave não está no `textos.csv`; fala com `proxima` e `opcoes` juntas; opção sem `proxima`; mais de 3 opções. Exemplo: `diálogo serpente_ola, fala b: texto "SERPENTE_X" não existe em textos.csv`.
3. Cena com erro não toca: o jogo registra o erro e segue. O arquivo do jogo não tem erros (teste de conteúdo).
4. **Leitura** (`DialogueRun`, regra pura): começa na fala `inicio`; `current()` devolve `{quem, texto, opcoes}` (textos já traduzidos); `advance()` vai para a `proxima` (não faz nada numa fala com opções); `choose(n)` (a partir de 1) segue a opção; na fala sem continuação, `advance()` termina a cena.
5. **Na sala**: em `targets`, `serpente:<cena>` põe a serpente. Com o mago a até **2 tiles**, aparece `E: falar` sobre ela; apertar **E** (ação `talk`) abre a cena.
6. **Caixa de diálogo** (`DialogueBox`): no alto da tela, abaixo do HUD (embaixo ela cobria o mago e a serpente, que ficam no chão), com o nome de quem fala e o texto; as opções numeradas. Enquanto aberta, **o jogo pausa** e o grimório não abre. **Espaço**, **Enter** ou **E** avançam; **1–3** escolhem a opção. Ao terminar, a caixa fecha e o jogo despausa.
7. Na Sprint 12, a sala_01 tinha uma cena de teste (`serpente_ola`); desde a Sprint 13 as cenas são as lições da serpente (NAR-serpente).

## Critérios de aceite

### NAR-001 — Ler uma cena linear

- **Dado** a cena `a → b → fim`
- **Então** `current()` é a fala `a`; `advance()` vai para `b`; `advance()` termina (`is_finished()`)

### NAR-002 — Ramificar

- **Dado** a fala `a` com opções `1 → b` e `2 → c`
- **Então** `advance()` não sai de `a`; `choose(2)` vai para `c`; `choose(5)` não faz nada

### NAR-003 — Erros de autoria claros

- **Dado** uma cena cuja `proxima` aponta para `z`, que não existe, e outra com texto `NAO_EXISTE`
- **Então** `validate` devolve `diálogo x, fala a: próxima fala "z" não existe` e `diálogo y, fala a: texto "NAO_EXISTE" não existe em textos.csv`
- **E** também acusa: cena sem `inicio`, `proxima` com `opcoes`, opção sem `proxima`, 4 opções, arquivo ilegível

### NAR-004 — O conteúdo do jogo é válido

- **Então** `res://content/dialogos.json` não tem erros, e toda cena é alcançável até um fim (nenhuma fala sem saída além das finais)

### NAR-005 — Falar com a serpente (cena)

- **Dado** uma sala com `serpente:serpente_ola` e o mago longe dela
- **Quando** aperta E
- **Então** nada abre
- **Quando** chega a 2 tiles e aperta E
- **Então** a caixa abre com a primeira fala, o jogo pausa, e avançando e escolhendo a cena termina, a caixa fecha e o jogo despausa

### NAR-006 — Cena com erro não trava (cena)

- **Dado** uma serpente com uma cena que não existe
- **Quando** o mago aperta E perto dela
- **Então** a caixa não abre, o jogo não pausa e o erro é registrado

## Exemplos

```json
{
  "serpente_ola": {
    "inicio": "a",
    "falas": {
      "a": {"quem": "serpente", "texto": "SERPENTE_OLA_1", "proxima": "b"},
      "b": {"texto": "SERPENTE_OLA_2", "opcoes": [
        {"texto": "SERPENTE_OLA_OPCAO_QUEM", "proxima": "c"},
        {"texto": "SERPENTE_OLA_OPCAO_SAIR", "proxima": "d"}
      ]},
      "c": {"texto": "SERPENTE_OLA_3"},
      "d": {"texto": "SERPENTE_OLA_4"}
    }
  }
}
```

## Perguntas em aberto

- [ ] A serpente deveria puxar conversa sozinha em momentos-chave (primeira vez na sala, depois de errar)? (Sprint 13, com o conteúdo)
