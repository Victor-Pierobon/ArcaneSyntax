# EXE-desbloqueio — Peças que o jogador ainda não conhece

- **Status:** Implementada
- **Sprint:** 5
- **Relacionadas:** EXE-pecas, EXE-sandbox, GRI-autocompletar
- **Decisão (2026-10-25):** o executor recusa peças bloqueadas (opção recomendada; o Victor não se opôs). Esconder só no autocompletar furaria a progressão do metroidvania.

## Contexto

Novos elementos, formas e ações são encontrados pela torre e funcionam como os upgrades do gênero (GDD, Progressão). Um feitiço não pode usar o que o jogador ainda não encontrou, nem se o código vier colado de fora.

## Regras

1. A requisição pode trazer `"pecas"`: a lista de peças desbloqueadas. **Sem o campo, tudo está desbloqueado** (compatível com o protocolo v1 e com os testes antigos).
2. Peças sujeitas a desbloqueio: `lancar`, `mover`, `levitar`, `meditar`, `absorver_mana`, `fogo`, `gelo`, `raio`, `projetil`, `escudo` e, desde a Sprint 9, `inscrever` e `construir_bloco`. Os sentidos (`mana`, `mana_max`, `vida_atual`, `alvo`, `ler_runa`) estão sempre disponíveis.
3. Um nome desconhecido em `pecas` torna a requisição inválida (`RequisicaoInvalida`).
4. **Antes de executar:** usar o nome de uma peça bloqueada gera o erro `PecaBloqueada` com linha e coluna, e **nada roda** (como o `FeiticoProibido`).
5. **Durante a execução:** `lancar` recusa elemento ou forma bloqueados que chegam como texto (`lancar("raio", ...)` ou `lancar(alvo.elemento, ...)`) com `PecaBloqueada` na linha; a ação não é registrada nem cobrada.
6. Mensagem: `você ainda não conhece <peça>`.
7. **Limitação conhecida:** uma função do próprio jogador com o mesmo nome de uma peça bloqueada (ex.: `def meditar():`) também é recusada.

## Critérios de aceite

### EXE-080 — Sem lista, tudo liberado

- **Dado** uma requisição sem `pecas`
- **Então** `lancar(raio, escudo)` funciona

### EXE-081 — Peça bloqueada antes de executar

- **Dado** `pecas` sem `raio`
- **Quando** o feitiço é `meditar()\nlancar(raio, projetil)`
- **Então** `erro.tipo` é `"PecaBloqueada"` na linha 2, com coluna, a mensagem cita `raio`, e não há ações

### EXE-082 — Ação bloqueada

- **Dado** `pecas` sem `levitar`
- **Quando** o feitiço usa `levitar(2)`
- **Então** `PecaBloqueada`

### EXE-083 — Texto com elemento bloqueado

- **Dado** `pecas` sem `raio` e um alvo de elemento `"raio"`
- **Quando** o feitiço é `mover(1)\nlancar(alvo.elemento, projetil, alvo)`
- **Então** a ação `mover` fica, `PecaBloqueada` na linha 2, e o `lancar` não é cobrado

### EXE-084 — Sentidos sempre disponíveis

- **Dado** `pecas` vazia
- **Então** `print(mana, mana_max, vida_atual, alvo)` funciona

### EXE-085 — Nome desconhecido na lista

- **Dado** `pecas` com `"bola_de_fogo"`
- **Então** `RequisicaoInvalida`
