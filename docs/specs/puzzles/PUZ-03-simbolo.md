# PUZ-03-simbolo — Puzzle 3: o cristal que muda de símbolo

- **Status:** Implementada
- **Sprint:** 9
- **Relacionadas:** PUZ-validacao (regra 8), MAG-elementos, ADR-001, GDD "uma porta que muda de símbolo e exige uma condicional"
- **Conceito:** condicionais

## Desenho

Na porta há um cristal mutável com **3 cargas**. Ele mostra um símbolo (`planta`, `fogo` ou `gelo`) e só aceita o elemento que vence esse símbolo. A cada acerto o símbolo muda, e nunca repete o anterior. Um erro zera as cargas. Um feitiço fixo, que sempre lança o mesmo elemento, nunca acerta três seguidos: o feitiço precisa **olhar o símbolo e decidir**.

- Sala: `sala_p03`, ligada à `sala_p02`
- Puzzle: `{"id": "p03_simbolo", "condicoes": [{"tipo": "cristais_acesos"}]}`
- Cristal: um dígito `cristal:mutavel`. É o único alvo da sala.
- **Efeito do ADR-001:** o feitiço vê o mundo como ele estava no momento da conjuração. Por isso, um mesmo feitiço não consegue acertar duas vezes seguidas: depois do primeiro acerto, ele continua vendo o símbolo antigo. Cada acerto é uma conjuração (ou uma rodada do passivo).

## Soluções que devem passar

O teste fixa a semente, enche a mana antes de cada conjuração e espera o projétil atingir o cristal antes da próxima.

| # | Estilo | Código (conjurado 3 vezes, salvo onde indicado) |
| --- | --- | --- |
| A | `if`/`elif`/`else` | `if alvo.elemento == "planta":` / `    lancar(fogo, projetil, alvo)` / `elif alvo.elemento == "fogo":` / `    lancar(gelo, projetil, alvo)` / `else:` / `    lancar(raio, projetil, alvo)` |
| B | Dicionário | `vence = {"planta": fogo, "fogo": gelo, "gelo": raio}` / `lancar(vence[alvo.elemento], projetil, alvo)` |
| C | Função com `return` | `def contra(simbolo):` / `    if simbolo == "planta":` / `        return fogo` / `    if simbolo == "fogo":` / `        return gelo` / `    return raio` / `lancar(contra(alvo.elemento), projetil, alvo)` |
| D | Passivo | a solução A no slot passivo, sem conjurar nada; o teste espera até 6 s |

## Soluções que devem falhar

| # | Por quê | Código |
| --- | --- | --- |
| X | Sempre o mesmo elemento: o símbolo nunca repete, então o segundo acerto falha | `lancar(fogo, projetil, alvo)`, conjurado 3 vezes |
| Y | O próprio elemento do símbolo: ele resiste | `lancar(alvo.elemento, projetil, alvo)`, conjurado 3 vezes |
| Z | Três lançamentos num feitiço só: o segundo usa o símbolo antigo | `for i in range(3):` + o corpo da solução A, conjurado uma vez |

## Critérios de aceite

### PUZ-040 — Soluções válidas acendem o cristal

- **Dado** a sala_p03 com a semente fixa
- **Quando** cada solução A, B, C e D é conjurada como descrito, cada uma num mundo novo
- **Então** o puzzle `p03_simbolo` fica resolvido e a porta abre

### PUZ-041 — Soluções erradas não acendem

- **Quando** X, Y ou Z são conjuradas como descrito
- **Então** o cristal não acende e a porta continua fechada

## Perguntas em aberto

- [ ] A solução Z (um loop que lança três vezes) parece certa e falha por causa do ADR-001. Isso pode frustrar. Proposta: a serpente explica, na Sprint 13, que "o feitiço vê o mundo como ele era quando você o conjurou". Outra saída seria o executor receber o mundo de novo depois de cada ação, mas isso muda o ADR-001 e não vale para a Alpha.
- [ ] `planta` não é um nome pronto como `fogo`: o jogador escreve `"planta"`, com aspas. Criar o nome `planta` ajudaria, mas planta não é elemento do mago. Fica como está, e o autocompletar sugere a string.
