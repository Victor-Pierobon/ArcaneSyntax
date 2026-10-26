# Jogo do Mago Programador — Documento de Design (GDD)

Oct 24, 2026 · @Victor Pierobon

## Visão geral

Um metroidvania em pixel art em que o jogador é um aprendiz de mago e cada feitiço é código real em Python, C ou C++. Preso dentro de um livro, ele sobe uma torre abandonada criando os próprios feitiços, e cada andar ensina novos conceitos de programação.

| Item | Definição |
| --- | --- |
| Gênero | Metroidvania 2D contínuo, com combate, puzzles e chefes |
| Estilo visual | Pixel art com atmosfera inspirada em Hollow Knight |
| Plataforma | PC, com lançamento planejado na Steam |
| Modo | Single player |
| Linguagens | Python, C e C++ |
| Público | Iniciantes em programação; escolas e faculdades como ferramenta de ensino |
| Equipe | Uma pessoa |
| Título | Em aberto |

**Pilares de design**

1. **Código real.** Tudo o que o jogador escreve é Python, C ou C++ válido e funciona fora do jogo.
2. **Liberdade de feitiços.** É o sistema principal: o jogador cria os feitiços, não escolhe de uma lista.
3. **Conhecimento e poder.** Saber programar não basta; o personagem precisa de mana para conjurar.
4. **O mapa é o currículo.** Áreas se abrem com conceitos dominados, não com chaves.
5. **Muitas soluções.** Puzzles validam o resultado no mundo, nunca comparam o código com um gabarito.

**Diferencial.** O CodeCombat já ensina Python e C++ com um herói de fantasia. Este jogo se separa dele por quatro pontos: ação contínua de metroidvania, feitiços criados livremente, C tratado como magia que manipula a memória e uma história que liga as três linguagens.

## História e mundo

O jogador lê um livro estranho que encontrou e é transportado para dentro dele. Acorda no ponto mais profundo da torre de um mago antigo, que abandonou o lugar mas deixou para trás criaturas mágicas, armadilhas e puzzles. Para voltar ao seu mundo, precisa aprender vários tipos de magia, chegar ao topo e usar um artefato.

**A torre.** Subir do subsolo ao topo é a própria curva de aprendizado. Cada andar tem um tema, uma magia e um mascote (o mapa completo está em Currículo):

- Fundações e Masmorra: magia Elemental, fundamentos.
- Biblioteca e Jardins: magia Elemental, estruturas de dados.
- Cripta dos Arquivos: magia Anciã, memória e ponteiros.
- Forja do Artífice: magia Artífice, objetos e classes.
- Topo: o artefato e o chefe final.

**O mago antigo.** Ausente durante todo o jogo, ele aparece por anotações, diários e feitiços quebrados que o jogador encontra e conserta. Esses fragmentos contam aos poucos quem ele era e por que partiu.

**Revelação do Ato III.** Ao chegar à Cripta, o jogador descobre que a magia Elemental sempre dependeu da magia Anciã. É a mesma relação do mundo real: o interpretador oficial do Python é escrito em C.

**Final.** No topo, o jogador usa o artefato para voltar ao seu mundo. O que o mago queria com a torre, e qual a ligação dele com o livro, são perguntas em aberto.

## Personagens

Cada linguagem tem um mascote animal que ensina seus conceitos e acompanha o jogador no ato correspondente.

| Personagem | Magia e linguagem | Personalidade | Papel |
| --- | --- | --- | --- |
| Serpente | Elemental · Python | Curiosa, falante, paciente | Primeira mentora; ensina os fundamentos e acompanha os Atos I e II |
| Kitsune | Anciã · C | Raposa mística de conhecimento ancestral; precisa e exigente | Ensina tipos, memória e ponteiros no Ato III |
| Corvo | Artífice · C++ | Engenhoso, colecionador de objetos, usa ferramentas | Ensina a construir e encantar artefatos (classes) no Ato IV |
| Mago antigo | Todas | Ausente; conhecido por escritos | Fonte da história, dos feitiços quebrados e do chefe final |
| Protagonista | Aprende as três | Pessoa comum que leu o livro | Personagem do jogador; nome e aparência em aberto |

**Ideia para a kitsune.** Nos mitos, a kitsune ganha caudas com a idade e a sabedoria. A cada conceito de C dominado, ela revela uma nova cauda, até nove. Isso dá ao Ato III um marcador visual de progresso.

**Os mascotes como sistema de dicas.** Quando o jogador trava, o mascote ajuda em três níveis: primeiro lembra o conceito, depois sugere a estrutura do código, e só por último mostra um exemplo parcial.

## As três magias

Cada linguagem é uma tradição de magia com fantasia, conceitos e riscos próprios. A ordem Python, C, C++ segue uma lógica de história: depois de dominar a magia moderna, o jogador descobre o que estava escondido por baixo dela.

| Magia | Linguagem | Fantasia | Conceitos centrais | Como o perigo aparece |
| --- | --- | --- | --- | --- |
| Elemental | Python | Comandar fogo, gelo, vento e raio | Lógica, estruturas de dados, funções | Indulgente: erros só fazem o feitiço falhar |
| Anciã | C | Manipular a mana diretamente, sem intermediários | Tipos, compilação, memória, ponteiros | Sem proteção: um segfault faz o feitiço ricochetear; mana não devolvida vaza e corrompe a sala |
| Artífice | C++ | Construir e encantar artefatos | Classes, objetos, herança, STL, gerenciamento de recursos | Artefatos mal construídos quebram; artefatos bem feitos se desfazem sozinhos quando não são mais usados |

**Dicionário de metáforas**

| Conceito | No jogo |
| --- | --- |
| Saída (`print`) | Manifestar: o feitiço mais básico, que faz algo aparecer no mundo |
| Variáveis | Reagentes guardados em frascos com rótulo |
| Condicionais | Runas condicionais (a porta só abre se a tocha estiver acesa) |
| Loops | Encantamentos repetidos (`while inimigo.vivo:`) |
| Funções | Feitiços próprios, escritos no grimório |
| Listas e arrays | A bolsa de itens |
| Dicionários | O bestiário (nome da criatura e sua fraqueza) |
| Recursão | Salas de espelhos |
| Ponteiros | Vínculos de alma: um fio que aponta para o objeto, em vez do objeto |
| `malloc` e `free` | Pegar mana emprestada da Fonte e devolvê-la |
| Classes e objetos | Moldes de artefatos e os artefatos encantados a partir deles |
| Herança | Um artefato que nasce de outro e herda seus encantamentos |

## Sistema de feitiços

O jogador carrega o grimório o tempo todo, escreve nele os próprios feitiços e leva 5 deles equipados para conjurar na hora. É o sistema principal do jogo e o lugar onde mora a liberdade do jogador.

**O grimório**

- Pode ser aberto em qualquer lugar. Abrir pausa o jogo, para ninguém aprender sob pressão.
- Modo Arquimago (opcional, para quem já programa): no combate, o tempo fica lento em vez de parar.
- Guarda todos os feitiços escritos, que podem ser reaproveitados em qualquer parte da torre.

**Os 5 slots.** Cinco feitiços ficam ligados a teclas e são conjurados instantaneamente no combate. Nos puzzles, o jogador escreve com calma direto no grimório.

**O primeiro feitiço: reunir mana.** O jogador começa sem mana, e o primeiro desafio do jogo é aprender a reuni-la. Meditar não custa nada: o mago para, se concentra e absorve a mana do ambiente. É a primeira linha de código do jogo.

```python
meditar()
```

**O feitiço que cresce com o jogador.** Esse mesmo feitiço evolui ao longo do Ato I, acompanhando cada conceito novo:

1. Chamada: `meditar()` enche a mana enquanto o mago fica parado.
2. Variáveis e condicionais: o mago só medita quando a mana está baixa.
3. Loops: um feitiço passivo absorve mana sozinho sempre que ela está abaixo do máximo, sem o mago precisar parar.

```python
# feitiço passivo, depois de aprender loops
while mana < mana_max:
    absorver_mana()
```

**Feitiços passivos.** Além dos 5 slots, o grimório tem um slot passivo, que o jogo executa continuamente em segundo plano. Ele também gasta mana por operação, então só compensa se for bem escrito: um feitiço que checa a mana antes de agir rende mais que um que absorve o tempo todo. Com a recarga automática, o combate flui sem pausas para meditar.

**As peças.** Feitiços são montados com peças que o jogo oferece e o jogador combina com código:

- Elementos: fogo, gelo, vento, raio, entre outros encontrados na torre.
- Formas: projétil, área, escudo, armadilha.
- Sentidos, que leem o mundo: `alvo.elemento`, `alvo.distancia`, `vida_atual`.
- Ações, que mudam o mundo: `lancar()`, `mover()`, `levitar()`.

**O feitiço que pensa.** Com inimigos de fraquezas diferentes e só 5 slots, o jogador descobre que pode escrever um feitiço que se adapta ao alvo. Um slot passa a valer por três, e ele aprende abstração porque ela resolve um problema dele. Este é o momento que o trailer deve mostrar.

```python
def feitico_adaptavel(alvo):
    if alvo.elemento == "fogo":
        lancar(gelo, projetil, alvo)
    elif alvo.elemento == "planta":
        lancar(fogo, projetil, alvo)
    else:
        lancar(raio, projetil, alvo)
```

**Mana como custo de execução.** Cada operação executada gasta um pouco de mana, e cada peça tem seu custo base. Consequências:

- Código mais eficiente custa menos, então habilidade compensa nível.
- Um loop infinito não trava o jogo: a mana acaba e o feitiço falha. O próprio mundo ensina o erro.
- O custo aparece no grimório antes de equipar, para o jogador planejar.

**Erros.** Cada erro aparece com a mensagem real da linguagem e uma tradução no mundo ("a runa da linha 4 está malformada"). O jogador precisa aprender a ler o erro de verdade, senão o aprendizado não sai do jogo.

## Progressão

O jogador evolui por dois caminhos que se compensam: o personagem ganha mana com níveis, e o jogador ganha eficiência ao programar melhor.

- **Experiência.** Vem de derrotar monstros e resolver puzzles. Soluções econômicas em mana dão bônus de XP.
- **Níveis.** Cada nível aumenta a mana máxima, permitindo feitiços maiores e mais complexos.
- **Recuperação de mana.** A mana vem de feitiços que o próprio jogador escreve: primeiro meditando, depois com um feitiço passivo que absorve a mana do ambiente. Melhorar esse feitiço faz parte da progressão.
- **Upgrades de metroidvania.** Novos elementos, formas, sentidos e ações são encontrados pela torre e ampliam o que dá para programar.
- **Novas magias.** Cada mascote libera uma linguagem e seus conceitos ao ser encontrado.

**Regra de equilíbrio.** Nenhuma porta depende só de nível. Um jogador fraco em combate pode passar escrevendo código melhor, e um jogador forte pode compensar código simples com mais mana. Isso evita o "eu sei fazer, mas o jogo não deixa".

## Exploração e puzzles

A torre é um mapa contínuo em que áreas se abrem por conceitos dominados, e os puzzles aceitam qualquer solução que deixe o mundo no estado certo.

**Bloqueio por conhecimento.** No lugar de pulo duplo ou dash, o jogador precisa de conceitos:

- uma ponte de 12 blocos que só se constrói com um loop;
- uma porta que muda de símbolo e exige uma condicional;
- um elevador que precisa de uma função com parâmetro, como `levitar(altura)`.

Voltar a áreas antigas com conceitos novos revela segredos, que é o prazer central do gênero.

**Segredos com mais de um caminho** (Victor, Sprint 14). O jogador é recompensado por resolver o problema de várias formas, não de uma forma específica: um baú só confere se o mago chegou até ele, seja com um feitiço, seja só com pulo e esquiva (MUN-segredos). Ideia para depois da Alpha: um baú que guarda uma página extra da Referência, com uma curiosidade de Python.

**Validação pelo estado do mundo.** O jogo nunca compara o código com um gabarito. Ele só verifica o resultado: todos os cristais estão acesos? A porta abriu? Assim, um jogador acende cristal por cristal, outro usa um loop, outro escreve uma função genérica e a reaproveita em três salas. Todos passam, e o orçamento de mana separa o "passou" do "passou bonito".

**Tipos de puzzle**

| Tipo | O que exige | Exemplo |
| --- | --- | --- |
| Construção | Repetição e cálculo | Montar uma ponte ou escada bloco a bloco |
| Lógica | Condicionais e sentidos | Portas que só abrem com a combinação certa |
| Padrões | Loops e listas | Acender cristais numa sequência que muda |
| Reparo | Ler e depurar código alheio | Consertar um feitiço quebrado do mago antigo |
| Otimização | Eficiência | Resolver gastando até certo limite de mana, por estrelas |

**Execução visível nos puzzles.** O feitiço roda passo a passo, com a linha atual destacada enquanto o mago age. Ver o loop girando ensina mais que qualquer explicação.

## Combate, inimigos e chefes

O combate é em tempo real e testa se o jogador se preparou bem: o que ele deixou equipado nos 5 slots decide a luta.

- **Ataque básico.** Golpe de cajado sem custo de mana. O jogador nunca fica indefeso.
- **Feitiços equipados.** Conjurados por tecla, gastam mana conforme o custo do código.
- **Movimento.** Pulo, esquiva e plataforma no estilo do gênero.

**Inimigos que pedem lógica, não só dano**

| Inimigo | Comportamento | O que ensina |
| --- | --- | --- |
| Elementais | Cada um tem uma fraqueza elemental | Condicionais e feitiços adaptáveis |
| Enxames | Muitos inimigos pequenos juntos | Loops sobre uma lista de alvos |
| Guardiões de escudo | Alternam o elemento do escudo | Ler sentidos antes de agir |
| Miméticos | Parecem itens até serem tocados | Verificar antes de confiar |

**Chefes.** Um por ato, cada um testando os conceitos daquele ato. Os chefes mudam de fase e de fraqueza durante a luta, o que obriga o jogador a ter feitiços que se adaptam. O chefe final, no topo, exige as três magias.

## Currículo

A torre tem quatro atos, e cada um ensina um bloco de conceitos com uma magia e um mascote. A versão Alpha cobre só o Ato I.

&#91;embedded content: a torre · 4 atos e o topo\]

Cada fase introduz um conceito novo, e a fase seguinte obriga a combiná-lo com os anteriores. Cada ato fecha com um chefe que exige tudo o que foi visto nele.

## Interface e feedback

O grimório é um editor de código completo disfarçado de livro, e tudo o que o feitiço faz precisa ser visível para o jogador.

- **Editor.** Realce de sintaxe, autocompletar das peças conhecidas e o custo de mana estimado de cada feitiço.
- **Páginas de referência.** Cada peça e cada conceito ganha uma página no grimório, escrita pelo mascote, que o jogador consulta quando quiser.
- **Execução passo a passo.** Nos puzzles, a linha atual fica destacada e a velocidade é ajustável.
- **Visões.** O `print` aparece como uma visão flutuante sobre o mago, usada para depurar.
- **Erros.** Mensagem real, linha marcada e uma explicação curta do mascote.
- **Acessibilidade.** Tamanho de fonte ajustável, pausa sempre disponível e textos em arquivos separados para tradução.

## Arte, som e estilo

Pixel art 2D com a atmosfera de Hollow Knight: um mundo sombrio e misterioso, mas acolhedor, com silhuetas sempre legíveis.

| Elemento | Direção |
| --- | --- |
| Andares | Cada um com paleta e ambientação próprias, para o jogador sentir a subida |
| Magia Elemental | Cores vivas e partículas naturais (chamas, gelo, folhas) |
| Magia Anciã | Runas, fogo de raposa e tons de azul e dourado |
| Magia Artífice | Engrenagens, latão e brilho de encantamento |
| Conjuração | As linhas de código brilham como runas ao serem executadas |
| Som | Trilha ambiente por andar; cada elemento e forma com som próprio |

**Escopo de arte para uma pessoa.** Personagens pequenos (em torno de 32 pixels de altura), tilesets reaproveitáveis por andar e poucas animações por inimigo. Assets prontos podem cobrir o início e ser trocados depois.

## Arquitetura técnica

O jogo é feito em Godot, para PC, e nunca executa o código do jogador diretamente: um executor isolado roda o feitiço e devolve só uma lista de ações para o jogo animar.

&#91;embedded content: como um feitiço roda · 4 etapas\]

O mesmo caminho serve para as três linguagens, mudando só o executor.

| Parte | Decisão |
| --- | --- |
| Motor | Godot, exportando para Windows, Linux e macOS |
| Python | Interpretador Python embutido no jogo, rodando num processo separado |
| C | Compilador de C pequeno embutido (o TCC é uma opção a testar) |
| C++ | Em aberto: compilador completo embutido ou interpretador |
| Comunicação | O jogo envia o código e o estado do mundo; o executor devolve ações, custo de mana e erros em JSON |
| Segurança | Executor sem acesso a arquivos ou rede e com limite de tempo, além do limite de mana |
| Textos | Todos em arquivos separados, para traduzir sem mexer no código |
| Saves | Um perfil de progresso por jogador |

## Mercado

O plano é vender o jogo na Steam como single player e oferecê-lo a escolas e faculdades como ferramenta de ensino diferente.

**Na Steam.** O público é principalmente internacional, então o jogo deve sair em português e inglês desde o lançamento.

**Para escolas e faculdades.** Itens a planejar desde cedo, mesmo que entrem só depois:

- Perfis de progresso separados, porque laboratórios dividem computadores.
- Um modo professor, com o andamento de cada aluno por conceito.
- Licenças para instituições, com preço e modelo em aberto.

**Concorrentes**

| Jogo | O que faz | Onde este jogo se diferencia |
| --- | --- | --- |
| [CodeCombat](https://www.lafourche.org/codecombat-gaming) | RPG de herói no navegador; ensina Python, JavaScript e C++; forte em escolas | Ação de metroidvania, feitiços livres, C com memória, história que liga as linguagens |
| Human Resource Machine | Puzzles de programação com linguagem visual própria | Código real, que funciona fora do jogo |
| The Farmer Was Replaced | Automação de fazenda com linguagem parecida com Python | Combate, exploração e três linguagens |

**Posição.** Nenhum dos concorrentes ensina C e memória como parte da fantasia, e nenhum é um metroidvania. Esses são os dois argumentos de venda.

## Riscos e questões em aberto

O maior risco é o escopo: um metroidvania com um executor de código por cima é grande para uma pessoa, por isso o projeto começa por uma versão Alpha pequena.

| Risco | Impacto | Como reduzir |
| --- | --- | --- |
| Escopo grande para uma pessoa | Projeto que nunca termina | Fatia vertical primeiro; só expandir o que for divertido |
| Rodar C e C++ dentro do jogo | Atraso no Ato III em diante | Python primeiro; testar o executor de C cedo, num protótipo separado |
| Ensinar demais e divertir de menos | Jogadores abandonam | Testes com iniciantes reais desde a Alpha |
| Código do jogador rodando no computador de quem comprou | Problemas de segurança | Executor isolado, sem acesso a arquivos ou rede |
| Arte e animação tomam muito tempo | Atraso geral | Assets prontos no início; arte final depois |

**Questões em aberto**

- [ ] Título do jogo
- [ ] Nome e aparência do protagonista
- [ ] Por que o mago antigo abandonou a torre e qual a ligação dele com o livro
- [ ] Público principal: ensino médio, faculdade ou os dois
- [ ] Como executar C++ (compilador completo embutido ou interpretador)
- [ ] Preço na Steam e modelo de licença para instituições
