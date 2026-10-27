# Identidade visual — roteiro passo a passo (Alpha 1.1)

Para o Victor, enquanto o assistente melhora as salas e o chefe. Combinado em 2026-10-26: **arte mista**. O **cenário** (tiles e fundo) vem de um pacote pronto, recolorido para a paleta do jogo. É **própria** a arte que dá identidade: mago, serpente, inimigos, chefe, efeitos de magia e interface.

Os prompts de IA estão em `guia-de-arte.md`, seção 6. Este roteiro diz **em que ordem** fazer, **o que entregar** e **onde pôr cada arquivo** para entrar no jogo sem retrabalho.

## Como a arte entra no jogo

Na Sprint 16 o jogo passa a procurar a arte por **nome de arquivo**. Se o arquivo existe em `game/assets/`, o jogo usa. Se não existe, mostra a forma provisória, que nessa sprint também fica melhor que os quadrados de hoje. Por isso:

- Você pode entregar **aos poucos, em qualquer ordem**. Cada PNG que entra já aparece no jogo.
- Um teste automático confere cada arquivo entregue: tamanho do quadro, quantidade de quadros e se a pasta está certa. Se algo vier fora do combinado, o teste diz o quê.
- **Não precisa abrir o Godot.** Você exporta o PNG para a pasta certa e me avisa. Eu ajusto o que precisar (colisor, posição, velocidade da animação).

## Passo 0 — Ferramentas (1 dia)

1. **Aseprite**, para desenhar e animar. Pode compilar de graça a partir do código, ou comprar na Steam ou no itch.io.
2. **Lospec** (lospec.com/palette-list), para escolher a paleta.
3. **Um gerador de imagem** (ChatGPT ou outro), só para **conceito**. Nada gerado vai direto para o jogo (`guia-de-arte.md`, seção 8).
4. Crie as pastas:
   ```
   art/
   ├─ conceitos/      (imagens de IA, rascunhos, moodboard)
   ├─ fontes/         (arquivos .aseprite)
   ├─ pacotes/        (pacotes comprados ou baixados, como vieram)
   ├─ paleta.png      (a paleta escolhida, 1 px por cor)
   ├─ estilo.md       (a ficha de estilo do passo 1)
   └─ CREDITOS.md     (licença e crédito de cada pacote e fonte)
   ```

## Passo 1 — Direção de arte (1 semana, antes de desenhar qualquer sprite)

Tudo o que vem depois depende disto. Pode ser rápido, mas não pule.

1. **Moodboard.** Use o prompt 6.2. Junte também 10 a 15 capturas de jogos de referência (Hollow Knight, Blasphemous, Dead Cells, Celeste, Noita) em `art/conceitos/moodboard/`. Anote o que você gosta em cada uma.
2. **Paleta.** Escolha uma paleta de **24 a 32 cores** no Lospec e salve em `art/paleta.png`. Sugestões para começar: *Resurrect 64* (corte para ~32 cores), *Apollo* ou *Endesga 32*. Confira se ela tem:
   - 4 ou 5 escuros frios, para o fundo e as sombras;
   - uma rampa de pedra com 4 tons;
   - uma rampa de musgo;
   - uma rampa quente para as tochas e o fogo;
   - uma rampa fria para os cristais e o gelo;
   - um amarelo forte para o raio;
   - o azul e o amarelo da serpente, que é um aceno ao Python.
3. **Ficha de estilo** em `art/estilo.md`. Responda numa página, usando o prompt 6.1 como ajuda:
   - **Luz:** vem de cima e um pouco da esquerda. Quanto o cenário é escuro, e o que brilha (tochas, cristais, feitiços, runas)?
   - **Contorno:** sim ou não. Se sim, de que cor? Recomendação: contorno escuro colorido (não preto puro) nos personagens e **sem contorno no cenário**. Assim o que se mexe se destaca do fundo.
   - **Três planos:** o fundo escuro e com pouco contraste; o plano do jogo com o maior contraste; a frente (raízes, correntes) quase preta.
   - **Formas:** o mago com formas redondas e simples; inimigos com pontas; a serpente com curvas; o chefe grande e pesado.
   - **Regra de leitura:** cada personagem precisa ser reconhecível **só pela silhueta preta**, com 32 px de altura.
4. **Teste da paleta:** pinte, só com a paleta, uma cena de 640×360 com um pedaço de chão, uma tocha, um cristal e um retângulo no lugar do mago. Se ficar bonito em tamanho real (com zoom inteiro, sem borrar), a paleta serve.

**Entregue:** `art/paleta.png`, `art/estilo.md` e o teste de cena. Com isso eu ajusto a luz do jogo, o fundo provisório e a cor de cada elemento para combinar.

## Passo 2 — Pacote de cenário (2 a 4 dias)

Procure no itch.io (buscas: "dungeon tileset 16x16", "metroidvania tileset", "cave tileset parallax").

**O pacote precisa ter:**

| Critério | Por quê |
| --- | --- |
| Tiles de **16×16** | É a grade do jogo |
| Paredes com **bordas e cantos**: 3×3 por fora e os 4 cantos internos, ou um conjunto de autotile | O jogo monta as bordas sozinho (*terrain* do Godot). Só com o bloco do meio, tudo volta a parecer quadrado |
| Plataforma fina (de atravessar por baixo) e espinhos | São elementos que o layout já usa (`=` e `^`) |
| **Fundo em 2 ou 3 camadas** | Para o paralaxe |
| Decoração solta: tochas, correntes, musgo, ossos, pedras, raízes | É o que deixa as salas parecendo lugares |
| **Licença que permite uso comercial** | O jogo pode ir para a Steam. Anote o crédito exigido em `art/CREDITOS.md` |

**O que fazer com ele:**

1. Copie o pacote, como veio, para `art/pacotes/<nome>/`.
2. **Recolora para a sua paleta** no Aseprite (Sprite → Color Mode → Indexed, com a sua paleta). É isso que faz um pacote pronto parecer do seu jogo.
3. Exporte para `game/assets/cenario/` (os nomes estão no contrato, abaixo) e me avise qual é o pacote. **O TileSet com as bordas automáticas sou eu que monto**, porque cada pacote organiza os tiles de um jeito.

## Passo 3 — O mago (1 a 2 semanas; é o sprite que define o estilo)

Comece pelo mago, porque ele fixa a escala, o contorno e o jeito de animar de todo o resto.

1. Conceito com o prompt 6.3. Escolha um e anote o que fica: silhueta, cores e o detalhe que marca o personagem (o cajado, o grimório que brilha no quadril).
2. No Aseprite, num quadro de **48×48**, desenhe o mago com **cerca de 32 px de altura** e os pés na linha **y = 46**, no centro (x = 24). A folga é para o cajado e os braços na conjuração.
3. Ordem para desenhar: silhueta em uma cor → cores base → sombra → brilho → contorno. Use o prompt 6.8 para pedir um plano das poses.
4. Anime primeiro **parado, andar e pular**. Coloque no jogo, jogue e só então faça o resto. É barato corrigir a escala nessa hora; depois de 10 animações, não é.

## Passo 4 — O resto, na ordem em que o jogo precisa

| Ordem | O quê | Por que nessa ordem |
| --- | --- | --- |
| 1 | Efeitos de magia: projéteis, escudo, faísca, meditação (prompt 6.7) | Aparecem o tempo todo; é onde a "magia de código" fica bonita |
| 2 | Objetos de puzzle: cristal, runa, cadeado, porta, ponte, placa, baú, fonte, tocha (prompt 6.6) | Ficam no centro da tela em 6 salas |
| 3 | Serpente e retrato (prompt 6.4) | É a mentora; o retrato aparece em toda fala |
| 4 | Inimigos: elemental, enxame, guardião (prompt 6.5) | |
| 5 | **Chefe** (prompt 6.9, abaixo) | A Sprint 17 refaz o chefe; desenhe depois de ver os ataques novos funcionando |
| 6 | Interface: fonte, moldura do grimório, HUD, caixa de diálogo, logo | Por último, porque depende de tudo ter a mesma cara |

### Prompt 6.9 — Chefe da Masmorra (novo)

```
Boss concept sheet for a pixel art metroidvania, side view: the guardian of the deepest
dungeon of a wizard's tower, a large floating stone-and-crystal construct about 64 to 80
pixels tall, with a glowing elemental core that changes between three phases: fire (orange),
ice (cyan) and plant (green). It slams the ground to raise stone pillars and fires orbs.
Show: idle, moving, ground-slam windup, orb attack, phase change, defeated. Same palette
family as a dark mossy dungeon with blue crystals. Readable silhouette, no anti-aliasing,
flat background, no text.
```

## Contrato dos arquivos (o que o jogo procura)

Regras para todos os arquivos:

- PNG com transparência, sem suavização, cores só da paleta.
- **Uma tira horizontal por animação**: quadros **quadrados**, lado a lado, sem espaço entre eles. O jogo conta os quadros pela largura (largura ÷ altura).
  - No Aseprite: File → Export Sprite Sheet, com Layout *Horizontal Strip*, Split by *Tags* e um arquivo por tag.
- Nome do arquivo = nome da animação, em minúsculas e sem acento: `game/assets/<pasta>/<animacao>.png`.
- Os pés (ou a base) ficam centralizados, 2 px acima da borda de baixo do quadro.
- Personagens desenhados **olhando para a direita**; o jogo espelha para a esquerda.
- A paleta vai para `game/assets/paleta.png` (1 px por cor). Com ela lá, o teste acusa qualquer cor fora da paleta e qualquer pixel semitransparente (o erro mais comum de imagem gerada por IA), dizendo o arquivo e a posição do pixel.
- O contrato também está em `game/content/arte.json`, que é o que o jogo e o teste leem; a tabela abaixo é o resumo.
- Elementos com cor própria (fogo, gelo, raio, planta) têm **um arquivo por elemento**, feito por troca de paleta: `projetil_fogo.png`, `projetil_gelo.png`…

| Pasta | Quadro | Animações (quadros sugeridos · laço?) |
| --- | --- | --- |
| `mago/` | 48×48 | `parado` (4 · sim), `andar` (6–8 · sim), `pular` (2), `cair` (2 · sim), `esquivar` (4), `conjurar` (5), `meditar` (4 · sim), `cajado` (4), `dano` (2), `morrer` (6) |
| `serpente/` | 32×32 | `parada` (4 · sim), `falando` (4 · sim); `retrato.png` de **64×64**, um quadro só |
| `elemental/` | 32×32 | `andar_<elemento>` (4–6 · sim) e `morrer_<elemento>` (4), para fogo, gelo e planta |
| `enxame/` | 16×16 | `voar` (2–4 · sim), `mergulhar` (2) |
| `guardiao/` | 48×48 | `andar` (4 · sim), `morrer` (5); `escudo_<elemento>` (32×32, 2–4 · sim) para fogo, planta e gelo (os do escudo do guardião no jogo) |
| `chefe/` | 96×96 | `parado_<fase>` (4 · sim), `mover_<fase>` (4 · sim), `golpe_<fase>` (preparar e bater no chão, 6), `orbe_<fase>` (4), `troca` (6), `morrer` (8); `<fase>` = fogo, gelo, planta. Também `pilar.png` (16×64, subir em 4 quadros), `aviso.png` (16×16, 2 · sim) e `orbe_voando_<elemento>.png` (16×16, 4 · sim) |
| `magia/` | 16×16 | `projetil_<elemento>` (4 · sim), `faisca_<elemento>` (3), `impacto_<elemento>` (4); `escudo_<elemento>` de **48×48** (4 · sim); `meditar` de 48×48 (6 · sim); `runa` de 8×8 (4) |
| `objetos/` | 16×16 | `cristal_apagado`, `cristal_aceso_<elemento>` (4 · sim), `runa_<n>` (n = 0 a 9), `cadeado`, `porta` (1 tile que se repete na vertical), `porta_abrindo` (4), `ponte`, `placa`, `placa_pisada`, `tocha` (4 · sim); `bau_fechado` e `bau_abrindo` (32×32, 4); `fonte` (32×32, 4 · sim) |
| `cenario/` | — | `tiles.png` (64×80: as 16 formas de pedra e mais uma linha, explicado abaixo), `fundo_1.png`, `fundo_2.png`, `fundo_3.png` (640×360, do mais longe para o mais perto, emendando nas bordas esquerda e direita), `decoracao.png` (peças soltas, 16×16 ou 32×32) |
| `ui/` | — | `fonte.ttf` ou `fonte.png` (fonte em pixel; sugestão: m5x7 ou Pixel Operator, ambas gratuitas; confira a licença), `moldura.png` (9-slice, 48×48, para o grimório, os menus e a caixa de diálogo), `vida.png` e `mana.png` (16×16, cheio e vazio lado a lado), `slot.png` (24×24), `logo.png` (até 320×120) |

### O `tiles.png` (16 formas de pedra)

Cada pedra escolhe o desenho pelos vizinhos: some 1 se há pedra **em cima**, 2 se há **à direita**, 4 se há **embaixo** e 8 se há **à esquerda**. O número (0 a 15) diz onde o tile fica: coluna = número % 4, linha = número ÷ 4. A quinta linha tem a plataforma (coluna 0, só os 4 px de cima contam como chão) e os espinhos (coluna 1).

```
linha 0:  0 isolada        1 só em cima      2 só à direita     3 em cima+direita
linha 1:  4 só embaixo     5 cima+baixo      6 direita+baixo    7 cima+direita+baixo
linha 2:  8 só à esquerda  9 cima+esquerda  10 esquerda+direita 11 sem embaixo
linha 3: 12 baixo+esquerda 13 sem à direita 14 sem em cima (chão) 15 cercada (miolo)
linha 4: plataforma        espinhos          (livre)            (livre)
```

O lado **sem** vizinho é o que ganha borda: o 14 é o chão visto de cima (borda só no topo, com musgo), o 15 é o miolo da parede. O provisório (`game/assets/placeholder/tiles_bordas.png`) segue esse formato e serve de molde. Se o pacote vier em outro formato, eu reorganizo.

Não precisa entregar tudo. Comece pelo mago (`parado`, `andar`, `pular`), pelo `tiles.png` e pelo `fundo_1.png`: com esses três o jogo já deixa de parecer quadrados.

## O que eu faço do meu lado (para a arte brilhar)

Isto não depende da sua arte e entra antes dela (Sprints 16 e 20):

- A esteira que lê os arquivos acima, com a forma provisória quando falta algum.
- Paredes com bordas automáticas (terrain) e fundo com paralaxe.
- **Luz:** a sala fica escura, e tochas, cristais, feitiços e a serpente acendem luz ao redor. Com pouca arte, é o que mais muda a cara do jogo.
- Partículas por elemento: brasas, flocos de gelo, faíscas e folhas.
- Tremida de câmera e um congelamento curto do quadro nos golpes do chefe.
- As runas do código que brilham ao conjurar.

## Checklist de pronto (identidade visual da 1.1)

- [ ] Paleta, ficha de estilo e teste de cena aprovados por você
- [ ] Pacote de cenário recolorido e creditado em `art/CREDITOS.md`
- [ ] Mago com as 10 animações
- [ ] Efeitos dos três elementos, mais o escudo e a meditação
- [ ] Objetos de puzzle, serpente e retrato
- [ ] Inimigos e chefe com as três fases
- [ ] Interface: fonte, moldura, HUD e logo
- [ ] Captura de cada sala; em todas, o mago e os inimigos se destacam do fundo (teste da silhueta)
