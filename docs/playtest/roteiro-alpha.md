# Playtest da Alpha com iniciantes (fecha a Alpha)

**Pergunta que o teste responde:** um iniciante em programação joga do início ao fim **sem ajuda externa** e **quer continuar**? (critério de sucesso do plano)

Diferente do playtest do núcleo (`roteiro-nucleo.md`), aqui **não há ficha de desafios**: quem ensina é o jogo (a serpente, as dicas e a Referência). Se a pessoa precisar de você, isso é o dado.

## Quem

3 a 5 pessoas que estão **começando** a programar (nunca escreveram um programa, ou só fizeram um curso introdutório). Uma por sessão, de 60 a 90 minutos.

## Preparação (10 min)

1. Use o build: descompacte `ArcaneSyntax-alpha.zip` (`scripts/build_windows.ps1`) e abra `ArcaneSyntax.exe`. O computador não precisa de Godot nem de Python.
2. **Perfil limpo:** antes de cada pessoa, renomeie `%APPDATA%\Godot\app_userdata\ArcaneSyntax\perfis\padrao` para `padrao-<nome>` (assim cada sessão guarda o save e o grimório dela, para você ler depois). Se testar no seu computador, faça isso também com o seu perfil e desfaça no fim. **No seu computador, renomeie também o grimório antigo** `ArcaneSyntax\grimorio.json` (de antes da Sprint 13): sem isso, o jogo copia os seus feitiços para o perfil novo.
3. Entregue só isto, de boca ou num papel: *"É um jogo em que os feitiços são programas em Python. Jogue como quiser; eu só vou observar. Pense em voz alta."* Nada de teclas: elas estão no rodapé da tela e no `LEIA-ME.txt`.
4. Papel para anotar com o horário e, se a pessoa deixar, gravação da tela.

## Regras para quem observa

- **Não ajude.** Se a pessoa travar por **5 minutos** sem progresso, pergunte "o que você está tentando fazer?". Se continuar travada por mais 3, dê **uma** dica e anote qual, onde e quando. Cada ajuda conta contra o critério.
- Não explique o que o jogo "quis dizer". Entender errado é o dado mais valioso.
- Se a pessoa quiser parar, deixe. Anote onde e por quê.

## O que anotar, sala por sala

Anote o **horário de entrada** em cada sala. Para cada uma: travou? Por quanto tempo? Falou com a serpente? Pediu dica (quantas)? Abriu a Referência? Errou o Python (qual erro)? Momentos de "ahá!" e de frustração.

| Sala | O que observar |
| --- | --- |
| `sala_01` (P1: sequência) | Achou a serpente e o **E**? Achou o grimório (Tab)? Entendeu equipar (botões 1–5) antes de conjurar? Começar sem mana confundiu? |
| `sala_02`, `sala_03` (corredores) | Viu os baús? Tentou pegar? Com feitiço ou pulando? Desistiu? |
| `sala_p02` (P2: variáveis) | Entendeu `ler_runa(n)` e o cadeado de soma? Usou variáveis ou somou de cabeça? |
| `sala_p03` (P3: condicionais) | Percebeu que o cristal muda? Chegou no `if`/`elif`? Tentou um loop (e entendeu por que não serve)? |
| `sala_p04` (P4: loops) | Escreveu `for`? Copiou 12 linhas? Viu as estrelas? Quis refazer para ganhar mais? |
| `sala_p05` (P5: funções) | Leu as alturas gravadas? Escreveu `def` com parâmetro? |
| `sala_p06` (revisão) | Reaproveitou feitiços das salas anteriores? |
| `sala_c01`–`c03` (combate) | Equipou feitiços antes de lutar? Usou `alvo.elemento`, `inimigos`, o escudo? Morreu quantas vezes? Achou o atalho? Usou a fonte? |
| `sala_c04` (chefe) | Percebeu a troca de fase? Adaptou o feitiço? Quanto tempo levou? |
| Fim | Chegou? Leu o resumo? O que disse? |
| Sempre | Usou a pausa (Esc)? Mexeu no tamanho do texto? Leu as mensagens de erro? Usou o **Testar** do grimório? |

## Perguntas no fim (10 min)

1. O que foi mais divertido? E o mais chato?
2. Teve alguma hora em que você não sabia o que fazer? Onde?
3. A serpente ajudou? As dicas vieram na hora certa?
4. A mana fez você pensar em escrever código mais curto?
5. Você sente que aprendeu alguma coisa de programação? O quê?
6. **Você jogaria o próximo andar?** (de 1 a 5, e por quê)

## Depois de cada sessão

- Copie `perfis\padrao-<nome>\save.json` e `grimorio.json` para a pasta da sessão: o save diz até onde a pessoa chegou, os puzzles e as estrelas, as lições vistas e quantas dicas usou em cada puzzle; o grimório mostra os feitiços que ela escreveu.
- Registre em `docs/playtest/AAAA-MM-DD-alpha-<nome>.md`, usando o modelo abaixo, **o que viu, sem interpretar**.

### Modelo do registro

```markdown
# Playtest Alpha — <nome ou apelido>, AAAA-MM-DD

- Experiência com programação: ...
- Duração: ... · Chegou até: ... · Ajudas dadas: N (onde e qual)
- Do save: puzzles ..., estrelas ..., lições .../6, dicas por puzzle ..., segredos .../2

## Linha do tempo
| Horário | Sala | O que aconteceu |
| --- | --- | --- |

## Respostas
1. ...

## Problemas vistos (sem solução ainda)
- ...
```

## Fechando os testes

- Junte os problemas de todas as sessões numa lista **por frequência** (quantas pessoas tiveram) em `docs/playtest/AAAA-MM-DD-alpha-resumo.md`.
- Cada problema vira uma tarefa de ajuste (bugs com teste de regressão antes); ideias novas vão para o GDD.
- **Critério para fechar a Alpha:** a maioria (3 de 5, ou 2 de 3) chega ao fim **sem nenhuma ajuda** e responde 4 ou 5 na pergunta 6.
