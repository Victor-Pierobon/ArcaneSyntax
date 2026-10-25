# PUZ-validacao — Puzzles validados pelo estado do mundo

- **Status:** Implementada
- **Sprint:** 8, 9
- **Relacionadas:** PUZ-01 a PUZ-06, PUZ-passo-a-passo, MUN-salas, MAG-formas, MAG-elementos, EXE-pecas, GDD "Validação pelo estado do mundo"

## Contexto

O jogo **nunca compara o código com um gabarito**: só verifica o resultado no mundo (GDD, pilar 5). Um jogador acende cristal por cristal, outro usa um loop, outro escreve uma função; todos passam.

## Regras

1. **Cristal:** um alvo especial (`alvo.elemento == "cristal"`) que acende quando um **feitiço** o atinge. O cajado não acende. Um cristal pode exigir um elemento (`cristal:fogo`); com outro elemento, ele só pisca.
2. **Porta de runas:** bloqueia a passagem até o puzzle da sala ser resolvido; então abre (deixa de colidir).
3. **No layout** (MUN-salas): `|` é uma célula de porta; cristais usam os dígitos de alvo com `targets = {"5": "cristal"}` ou `{"5": "cristal:fogo"}`.
4. **Puzzle da sala:** `puzzle = {"id": "p01_meditar", "condicoes": [...]}`. Condições (avaliadas pelo `PuzzleValidator` sobre uma foto do estado da sala):

   | Condição | Verdadeira quando |
   | --- | --- |
   | `{"tipo": "cristais_acesos"}` | todos os cristais da sala estão acesos |
   | `{"tipo": "cristais_acesos", "ids": ["5", "6"]}` | os cristais com esses dígitos estão acesos |

   Todas as condições precisam ser verdadeiras. Um tipo desconhecido é falso e vira erro de autoria.
5. O puzzle é avaliado sempre que algo na sala muda (um cristal acende). Resolvido, abre as portas e avisa o `World` (`puzzle_solved`).
6. O `World` guarda os puzzles resolvidos: ao voltar à sala, cristais acesos e portas abertas. (Gravar em disco é da Sprint 13.)
7. Um puzzle resolvido não "desresolve".

### Mecanismos da Sprint 9

8. **Cristal mutável** (`targets = {"5": "cristal:mutavel"}`, ou `cristal:mutavel:<cargas>`; padrão 3 cargas). Mostra um símbolo, `planta`, `fogo` ou `gelo`, que é o `alvo.elemento` que o feitiço lê. Só aceita o elemento que **vence** o símbolo (MAG-elementos: fogo vence planta, gelo vence fogo, raio vence gelo). Acerto certo: ganha uma carga, e o símbolo muda para um dos outros dois. Acerto errado: perde todas as cargas, e o símbolo também muda. Com todas as cargas, o cristal acende e fica aceso. O cajado não conta. O sorteio usa o gerador do `World`, que os testes fixam com uma semente.
9. **Runa** (`targets = {"6": "runa:4"}`, ou `runa:?` para um valor sorteado de 1 a 9 ao entrar na sala). Mostra o número. Não é alvo: projéteis passam por ela e ela não entra na escolha do `alvo`. As runas da sala, da esquerda para a direita (empate: de cima para baixo), formam `mundo.sala.runas` (EXE-protocolo, regra 7).
10. **Cadeado** (`targets = {"7": "cadeado:soma"}`). Recebe as ações `inscrever(valor)` quando o mago está a até 3 tiles dele; mais longe, a inscrição se perde, com o aviso "o cadeado está longe demais". Abre quando o valor é igual à **soma das runas da sala**. Valor errado: pisca e continua fechado, sem limite de tentativas. Aberto, continua aberto. O cadeado também não é alvo.
11. **Vão de ponte** (`~` no layout). Começa vazio. Cada `construir_bloco()` preenche a próxima célula `~` que ainda está vazia, da esquerda para a direita (empate: de baixo para cima). O bloco é sólido, como a pedra. Sem célula vazia, a ação não faz nada e avisa "a ponte já está pronta".
12. **Placa** (`_` no layout). Uma placa fina no fundo da célula, que fica **pisada** quando o mago está no chão dentro dela. Uma vez pisada, continua pisada. As placas são numeradas na mesma ordem das runas, da esquerda para a direita, e não na ordem de leitura do layout (bug corrigido na Sprint 9).
13. **Condições novas:**

    | Condição | Verdadeira quando |
    | --- | --- |
    | `{"tipo": "cadeados_abertos"}` | todos os cadeados da sala estão abertos (sem cadeados: falsa) |
    | `{"tipo": "ponte_completa"}` | todas as células `~` têm bloco (sem `~`: falsa) |
    | `{"tipo": "placas_pisadas"}` | todas as placas foram pisadas (sem placas: falsa) |

    A foto do estado passa a ser `{"cristais": {...}, "cadeados": {"7": true}, "ponte": {"feitos": 5, "total": 12}, "placas": [true, false]}`.
14. **Estrelas** (opcional): `puzzle = {..., "estrelas": [3.0, 5.0]}`. A sala soma o `custo_mana` das conjurações que terminam ali, dos slots e do passivo, desde a entrada até o puzzle ser resolvido. **Ficam de fora as conjurações que só recuperam mana**, isto é, as que não têm ação nenhuma além de `meditar` e `absorver_mana`. Sem isso, o passivo de absorver mana pioraria as estrelas só pelo tempo parado na sala, e reunir mana nunca deve ser punido. Ao resolver, dá 3 estrelas se a soma for até o primeiro número, 2 se for até o segundo e 1 caso contrário. As estrelas nunca impedem a solução: só medem a economia. Sair da sala sem resolver zera a soma.
15. O `World` guarda, para cada puzzle resolvido, a **melhor** quantidade de estrelas. Hoje isso fica só na memória; o disco é da Sprint 13. Um puzzle já resolvido não volta a contar mana. Para melhorar as estrelas, o jogador joga a sala de revisão de novo, mas isso fica para depois da Alpha.
16. **Gravura** (`targets = {"1": "gravura:5"}`): um texto pintado na parede, sem efeito no jogo. Serve para dar ao jogador uma informação que o puzzle pede, como as alturas do elevador. Achado por captura de tela na Sprint 9: sem as gravuras, as alturas do Puzzle 5 eram só adivinhação.

## Critérios de aceite

### PUZ-001 — Todos os cristais acesos

- **Dado** a foto `{"cristais": {"5": true, "6": true}}`
- **Então** `cristais_acesos` é verdadeira; com `"6": false`, falsa; sem cristais, falsa

### PUZ-002 — Cristais escolhidos

- **Dado** `{"cristais": {"5": true, "6": false}}`
- **Então** `cristais_acesos` com `ids ["5"]` é verdadeira, e com `["6"]` é falsa

### PUZ-003 — Condição desconhecida

- **Então** `{"tipo": "dancar"}` torna o puzzle falso e gera um erro de autoria

### PUZ-004 — Cristal acende com feitiço, não com cajado (cena)

- **Quando** um projétil atinge o cristal
- **Então** ele acende; um golpe de cajado não acende; um cristal `cristal:fogo` atingido por gelo não acende, e por fogo acende

### PUZ-005 — Porta bloqueia até resolver (cena)

- **Dado** a porta fechada
- **Quando** o mago anda contra ela
- **Então** não passa; ao acender o cristal, a porta abre e ele passa

### PUZ-006 — Resolvido continua resolvido (cena)

- **Quando** o mago sai da sala e volta
- **Então** o cristal está aceso e a porta aberta

### PUZ-007 — Condições novas

- **Dado** a foto `{"cadeados": {"7": true}, "ponte": {"feitos": 12, "total": 12}, "placas": [true, true]}`
- **Então** `cadeados_abertos`, `ponte_completa` e `placas_pisadas` são verdadeiras; com um cadeado fechado, `feitos` 11 ou uma placa `false`, a condição correspondente é falsa; sem cadeados, sem ponte (`total` 0) ou sem placas, também é falsa

### PUZ-008 — Cristal mutável (unidade)

- **Dado** um cristal mutável com 3 cargas, mostrando `planta`
- **Quando** é atingido por fogo, depois pelo elemento que vence o novo símbolo, e depois pelo errado
- **Então** fica com 1 carga, depois 2, depois 0; o símbolo muda a cada acerto e nunca repete o anterior; três acertos certos seguidos acendem o cristal; o cajado não muda nada

### PUZ-009 — Runas e cadeado (cena)

- **Dado** uma sala com `runa:4`, `runa:7`, `runa:2` e `cadeado:soma`
- **Então** `World.spell_context()` traz `sala.runas` `[4, 7, 2]`, e as runas e o cadeado não viram `alvo`
- **Quando** toca `inscrever(12)` perto do cadeado
- **Então** ele continua fechado; com `inscrever(13)`, abre; com o mago a mais de 3 tiles, `inscrever(13)` não abre

### PUZ-015 — Ponte (cena)

- **Dado** uma sala com 4 células `~`
- **Quando** toca `construir_bloco()` 4 vezes
- **Então** as 4 células ficam sólidas, da esquerda para a direita, o mago consegue andar por cima e a quinta ação só avisa

### PUZ-016 — Placa (cena)

- **Quando** o mago para sobre uma placa
- **Então** ela fica pisada e continua pisada depois que ele sai

### PUZ-017 — Estrelas

- **Dado** `estrelas` `[3.0, 5.0]`
- **Então** um gasto de 3.0 dá 3 estrelas, 3.1 dá 2, 5.0 dá 2, e 5.1 dá 1; sem `estrelas` no puzzle, não há estrelas

### PUZ-018 — Mana gasta na sala (cena)

- **Dado** uma sala com estrelas
- **Quando** o mago conjura `meditar()` (custo 0.2), depois dois feitiços com ações de custo 1.2 e 2.0, e então resolve o puzzle
- **Então** a soma é 3.2, porque o `meditar()` não conta, e o `World` guarda as estrelas; ao sair sem resolver e voltar, a soma recomeça do zero

### PUZ-019 — Runa sorteada

- **Dado** uma sala com `runa:?` e o `World` com a semente fixa
- **Então** o valor fica entre 1 e 9, é o mesmo em `sala.runas` e na runa desenhada, e é sorteado de novo a cada entrada na sala enquanto o puzzle não for resolvido
