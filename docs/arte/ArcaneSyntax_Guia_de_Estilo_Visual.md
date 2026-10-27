# ArcaneSyntax — Guia de Estilo Visual
## Área 01: Foundations and Dungeon

**Tipo de jogo:** metroidvania 2D em pixel art  
**Resolução-base:** 640 × 360 px  
**Grade do cenário:** tiles de 16 × 16 px  
**Personagem principal:** aproximadamente 32 px de altura  
**Perspectiva:** visão lateral (*side-scrolling*)  
**Clima:** fantasia sombria, misteriosa e aconchegante

---

## 1. Identidade visual

A área **Foundations and Dungeon** é o nível mais profundo de uma torre de mago abandonada. O lugar deve parecer antigo, úmido e silencioso, mas ainda habitado por vestígios de magia. A arquitetura sugere uma instituição de conhecimento esquecida: inscrições nas paredes, cristais que continuam brilhando e mecanismos que ainda funcionam sem que ninguém saiba por quê.

A direção visual combina a atmosfera de fantasia melancólica de *Hollow Knight* com uma identidade própria, construída em torno de runas, cristais e magia que se comporta como código executável.

### Princípios centrais

- **Mistério sem confusão:** o cenário pode esconder histórias, mas não deve esconder perigos ou plataformas importantes.
- **Silhuetas legíveis:** personagens, inimigos, plataformas e projéteis devem ser reconhecíveis em tamanho nativo.
- **Luz com propósito:** tochas e cristais conduzem o olhar e destacam pontos de interesse.
- **Detalhes seletivos:** textura e decoração enriquecem a cena sem competir com a jogabilidade.
- **Magia com linguagem visual própria:** símbolos geométricos, colchetes, pontos conectados e padrões de sintaxe distinguem ArcaneSyntax de uma fantasia genérica.

## 2. Paleta de 27 cores

A paleta parte de sombras azuladas e pedra dessaturada, contrapostas por luz quente de tochas e cores específicas para cada escola de magia. Use os códigos hexadecimais como referência consistente entre personagens, cenário, efeitos e interface.

### A. Escuros — 4 cores

| Nome | Hex | Uso |
|---|---|---|
| Vazio de Tinta | `#10131F` | Contornos mais escuros, fendas e sombras profundas |
| Azul Profundo | `#1B2233` | Fundo, áreas sem luz e contornos internos |
| Sombra Fria | `#293647` | Sombras de pedra e transições escuras |
| Verde-azulado Escuro | `#263D3D` | Cavidades úmidas, musgo em sombra e recessos |

### B. Pedra e cenário — 5 cores

| Nome | Hex | Uso |
|---|---|---|
| Basalto | `#39434A` | Blocos de pedra escura e bordas ambientais |
| Pedra da Masmorra | `#505B60` | Cor-base das paredes e plataformas |
| Cinza Envelhecido | `#6C7778` | Planos iluminados e variação de alvenaria |
| Argamassa Antiga | `#90958A` | Juntas, rachaduras claras e desgaste |
| Pergaminho Desbotado | `#B8B29A` | Inscrições, ossos e detalhes muito claros |

### C. Fontes de luz — 3 cores

| Nome | Hex | Uso |
|---|---|---|
| Brasa | `#D65C38` | Bordas quentes da chama e brasas |
| Ouro de Tocha | `#F2A64A` | Chama principal e reflexos alaranjados |
| Núcleo Quente | `#FFE3A1` | Centro da chama e pontos de brilho máximo |

### D. Magia — 12 cores

#### Fogo

| Nome | Hex | Uso |
|---|---|---|
| Cinza de Brasa | `#B94336` | Contorno quente e partes externas |
| Chama | `#F07842` | Corpo do fogo e projéteis |
| Luz do Fogo | `#FFD071` | Núcleo luminoso e impacto |

#### Gelo

| Nome | Hex | Uso |
|---|---|---|
| Geleira | `#477FAD` | Sombra de gelo e base dos cristais |
| Geada | `#83CFE0` | Superfícies iluminadas e projéteis |
| Núcleo de Gelo | `#D8F6F2` | Facetas mais brilhantes e impacto |

#### Eletricidade

| Nome | Hex | Uso |
|---|---|---|
| Tempestade | `#6258B9` | Sombra violeta e base do efeito |
| Arco | `#A59BFF` | Descargas e trajetórias |
| Voltagem | `#F0E7FF` | Núcleo quase branco e pontos de impacto |

#### Natureza

| Nome | Hex | Uso |
|---|---|---|
| Musgo Profundo | `#436B4B` | Folhas em sombra e magia orgânica escura |
| Folha Arcana | `#78B86C` | Plantas e feitiços de natureza |
| Florescimento Vital | `#C3E69A` | Brotos, cura e brilho máximo |

### E. Materiais — 3 cores

Acrescentadas em 2026-10-27, quando o primeiro mago gerado mostrou que a paleta não tinha madeira nem um tecido que não fosse cor de magia.

| Nome | Hex | Uso |
|---|---|---|
| Índigo do Manto | `#5A4291` | Túnica e capuz do aprendiz (fora das cores da magia de raio) |
| Madeira Envelhecida | `#8A5530` | Cajado, baús, portas, cabos e suportes de madeira |
| Couro Escuro | `#4E2C24` | Sombra da madeira, couro do grimório, cintos |

### Proporção sugerida

Como ponto de partida visual, use aproximadamente:

- **70%:** escuros e tons de pedra;
- **20%:** variações ambientais, musgo e cores secundárias;
- **10%:** luzes intensas e magia.

Essas proporções não precisam ser medidas pixel a pixel. O objetivo é manter a masmorra predominantemente escura e reservar os acentos luminosos para pontos relevantes.

**Regras de uso da paleta:**

- Não use a cor mais clara em todos os objetos; ela perde impacto quando aparece em excesso.
- Pergaminho desbotado deve destacar inscrições importantes, não contornar todas as pedras.
- Cada escola de magia precisa manter cores e formas consistentes.
- Não dependa apenas da cor para distinguir feitiços: formato, trajetória e animação também devem comunicar o tipo de magia.

## 3. Iluminação

### Direção da luz

Cada sala deve ter uma fonte de luz dominante. Uma sala com tochas deve parecer quente perto das chamas; uma sala com cristais deve ter uma atmosfera mais fria. Quando as duas fontes estiverem presentes, uma deve dominar e a outra servir como contraste.

### Quatro níveis de iluminação

1. **Núcleo:** pixels mais brilhantes da chama, do cristal ou do feitiço.
2. **Superfície iluminada:** pequena faixa de pixels que recebe a luz.
3. **Meia-luz:** pedra em tons médios, sem brilho intenso.
4. **Sombra:** azul profundo, verde-azulado escuro e silhuetas quase negras.

Prefira faixas de valor discretas em vez de gradientes suaves. O brilho deve parecer construído com pixels: pequenos grupos de cor, facetas e partículas pontuais. Evite halos grandes que lavem o contraste do cenário.

### Comportamento das fontes

- **Tochas:** iluminam a pedra próxima com laranja e dourado; a luz perde força rapidamente.
- **Cristais:** iluminam as faces próximas com azul e ciano; os pontos mais claros ficam nas facetas voltadas para a luz.
- **Runas:** brilham com moderação. Muitas inscrições podem estar apagadas ou quase invisíveis.
- **Feitiços:** devem ter um núcleo bem definido e uma trajetória legível antes de receberem partículas e brilho adicional.
- **Áreas escuras:** podem criar mistério, mas nunca devem tornar invisíveis o personagem, os inimigos ou as bordas de plataformas essenciais.

## 4. Contornos e agrupamento de pixels

- Use `#10131F` para os contornos externos mais importantes de personagens, inimigos e objetos interativos.
- Use `#1B2233` em separações internas e áreas escuras.
- Use `#39434A` ou `#505B60` em bordas de arquitetura quando um contorno quase preto parecer pesado demais.
- Para o personagem principal, prefira contorno externo de aproximadamente 1 px na resolução nativa.
- Não contorne cada tijolo, folha, rachadura ou runa. Use detalhes seletivos para sugerir textura.
- Organize pixels em grupos coerentes, evitando pontos isolados sem função.
- Evite *pillow shading*: a iluminação deve seguir uma direção consistente, e não formar uma faixa clara ao redor de todas as bordas.
- Não use desfoque para simular brilho. Construa o efeito com pixels e clusters de cor.

## 5. Profundidade e contraste

### Fundo

**Contraste baixo, detalhe reduzido.**

Use arcos distantes, pilares, correntes, janelas quebradas e silhuetas da torre em azuis e cinzas dessaturados. O fundo deve sugerir profundidade sem disputar atenção com o caminho jogável. A sensação de névoa deve vir da redução de contraste, não de borrar os pixels.

### Camada jogável

**Contraste alto, formas claras.**

Plataformas, paredes sólidas, escadas, perigos e inimigos precisam ser distinguíveis. A borda superior das plataformas deve ser especialmente clara. Mantenha uma diferença visível entre a superfície onde o personagem pisa e o espaço atrás dela.

### Primeiro plano

**Enquadramento escuro e detalhes seletivos.**

Pilares próximos, raízes pendentes, arcos e correntes podem enquadrar a cena. Use-os com moderação, principalmente nas laterais da tela. Eles não devem cobrir o personagem, inimigos, perigos ou bordas de colisão.

### Teste de legibilidade

O personagem deve continuar separado do cenário imediatamente atrás dele. Se um inimigo escuro se misturar a uma parede escura, ajuste o valor local da parede ou acrescente poucos pixels de luz na silhueta do inimigo. Não tente resolver tudo adicionando mais textura.

## 6. Linguagem de formas dos personagens

### Aprendiz de mago — personagem jogável

**Formas principais:** compacto, afunilado e curioso.

- Capuz grande como principal elemento de reconhecimento.
- Ombros estreitos, túnica que se abre na parte inferior e pés pequenos.
- Abertura do rosto simples, com poucos pixels para olhos ou sombra facial.
- Pequena runa ciano, fecho de grimório ou marca luminosa como detalhe característico.
- A túnica pode oscilar alguns pixels durante a corrida.
- O capuz pode baixar levemente na aterrissagem e se inclinar durante a conjuração.

A silhueta precisa funcionar sem detalhes faciais. Se houver um cajado, mantenha-o curto o suficiente para não dominar o personagem. A cabeça e a túnica devem continuar reconhecíveis quando o mago olha para os dois lados.

**Animações recomendadas:** parado, caminhada, corrida, salto, queda, aterrissagem, conjuração, dano, morte e interação.

### Cobra mentora

**Formas principais:** curvas, espirais e postura erudita.

- Corpo em S, cabeça erguida e cauda enrolada.
- Cabeça separada do corpo por uma sombra inferior ou pequeno realce.
- Olho âmbar expressivo e focinho alongado.
- Marcas semelhantes a runas acompanhando a curva do corpo.
- Movimentos lentos e deliberados; inclinação da cabeça ao explicar algo e língua aparecendo brevemente quando está desconfiada.

A cobra deve parecer uma estudiosa antiga, não apenas um monstro. Sua silhueta curva contrasta com o capuz triangular e a túnica do aprendiz.

### Inimigos

**Formas principais:** angulares, assimétricas e fáceis de reconhecer.

- **Rastejantes de pedra:** baixos, largos e pesados, com patas grossas ou carapaça irregular.
- **Cobras da masmorra:** corpos sinuosos e cabeça bem definida; devem recuar ou se enrolar antes de atacar.
- **Sentinelas rúnicas:** corpos blocados, cantos duros e uma runa luminosa central.
- **Inimigos voadores:** corpo compacto e asas largas, com batidas claras e não excessivamente rápidas.
- **Inimigos de elite:** diferencie por uma coroa, membro extra, recorte de silhueta ou ataque característico — não apenas por mais cores.

Cada inimigo precisa de uma pose de antecipação, uma pose de ataque e uma recuperação legível. O jogador deve perceber o perigo antes de o golpe acertar.

## 7. Regras para sprites de 32 px

O personagem tem apenas cerca de 32 pixels de altura, então cada pixel precisa contribuir para a forma, o volume ou a leitura da ação.

### Faça

- Teste a silhueta em uma única cor antes de adicionar sombreamento.
- Use grupos de pixels intencionais para formar capuz, rosto, túnica e pés.
- Preserve contraste de valor entre o personagem e o fundo imediato.
- Mantenha o ponto de apoio dos pés consistente entre os quadros de animação.
- Use mudanças de poucos pixels para transmitir peso, antecipação e impacto.
- Dê às escolas de magia formas e trajetórias próprias.
- Teste sprites na escala nativa, sem ampliar a imagem para avaliá-los.
- Verifique a leitura em tons de cinza.

### Evite

- Depender de olhos ou detalhes de um único pixel para identificar o personagem.
- Espalhar pixels aleatórios para representar textura.
- Usar brilho para compensar uma silhueta pouco clara.
- Animar todas as partes do sprite ao mesmo tempo.
- Fazer tochas, cristais, runas e partículas piscarem continuamente.
- Usar a mesma textura visual em personagens, paredes e efeitos.
- Desenhar detalhes que desaparecem ou viram ruído quando vistos em tamanho real.
- Usar desfoque, antialiasing ou gradientes suaves no pixel art final.

## 8. Tiles e objetos do cenário

A grade principal do cenário é de **16 × 16 px**. Os tiles devem se encaixar sem lacunas, mas não devem produzir um padrão repetitivo excessivamente uniforme.

### Pedra e plataformas

- Use duas ou três massas de valor principais por tile.
- Alterne a posição das rachaduras e das juntas entre tiles vizinhos.
- Dê à borda superior da plataforma uma leitura mais clara que a parte inferior.
- Use uma faixa estreita de realce na superfície pisável e tons mais escuros na face vertical.
- Varie a alvenaria sem desenhar cada bloco com o mesmo contraste.

### Umidade e musgo

- Use manchas pontuais de verde-azulado escuro e pequenos realces frios.
- Concentre o musgo em fendas, beiradas, locais próximos a água e superfícies horizontais.
- Não cubra todas as paredes com ruído verde.
- Gotas e pequenas poças podem usar poucos pixels claros para sugerir umidade.

### Tochas e cristais

- **Tocha:** suporte de ferro escuro, chama compacta alaranjada e alguns pixels amarelos no núcleo.
- **Cristal:** silhueta angular, núcleo luminoso e uma ou duas facetas claras.
- Reserve cristais grandes para pontos de interesse, marcos de exploração ou áreas especiais.
- Mantenha partículas e animações de fundo discretas.

### Runas e identidade de ArcaneSyntax

Crie um vocabulário visual reutilizável de símbolos geométricos, colchetes, setas, pontos conectados e círculos. As runas podem parecer uma linguagem de programação antiga gravada em pedra.

- Runas decorativas podem estar incompletas ou desgastadas.
- Runas ligadas à jogabilidade devem manter forma e significado consistentes.
- Não dependa de texto minúsculo para transmitir informação.
- Integre símbolos a portas, mecanismos, cristais e margens arquitetônicas para reforçar a ideia de um mundo construído dentro de um livro.

## 9. Organização e especificações para Godot

### Dimensões de referência

| Recurso | Especificação |
|---|---|
| Resolução-base | 640 × 360 px |
| Tile do cenário | 16 × 16 px |
| Altura do aprendiz | Aproximadamente 32 px |
| Formato de imagem | PNG |
| Fundo de personagens e efeitos | Transparente |
| Escala de exibição | Pixel art sem suavização |
| Orientação | Visão lateral |

### Organização sugerida de arquivos

```text
ArcaneSyntax/
└── assets/
    ├── player/
    │   ├── idle/
    │   ├── walk/
    │   ├── run/
    │   ├── jump/
    │   ├── fall/
    │   ├── land/
    │   ├── cast_fire/
    │   ├── cast_ice/
    │   ├── cast_lightning/
    │   ├── cast_nature/
    │   ├── hurt/
    │   └── death/
    ├── enemies/
    ├── npc/
    │   └── snake_mentor/
    ├── tiles/
    ├── props/
    ├── effects/
    └── runes/
```

### Uso no Godot

Para o personagem, uma configuração comum é usar `CharacterBody2D` para movimentação e colisão, com `AnimatedSprite2D` como filho para exibir a animação. O recurso `SpriteFrames` organiza as sequências de quadros por nome, como `idle`, `walk` e `cast_fire`.

Sprites individuais ou folhas de sprites podem ser usados. Em uma folha, os quadros precisam ter células consistentes e limites bem definidos para serem recortados corretamente. Em arquivos individuais, cada quadro deve ter dimensões previsíveis e alinhamento coerente.

Configure a filtragem da textura para **Nearest** (*vizinho mais próximo*) e evite suavização para preservar os pixels. As dimensões exatas das células e o ponto de origem precisam ser conferidos nos arquivos finais; uma imagem conceitual de sprites não garante, por si só, uma folha pronta para importar.

## 10. Checklist de revisão de arte

Antes de aprovar um sprite, tile ou efeito, verifique:

- [ ] A silhueta é legível em escala 1×.
- [ ] O personagem se destaca da parede e do chão próximos.
- [ ] As bordas pisáveis são distintas da alvenaria decorativa.
- [ ] Os ataques têm uma antecipação visual clara.
- [ ] Cada escola de magia possui cor, forma e movimento próprios.
- [ ] Os pixels mais brilhantes têm uma função visual clara.
- [ ] Não há desfoque, ruído excessivo ou detalhes subpixel desnecessários.
- [ ] A animação mantém a identidade do personagem entre quadros.
- [ ] A decoração do primeiro plano não esconde colisões ou perigos.
- [ ] A cena continua legível em tons de cinza.

## 11. Direção final da área

**Foundations and Dungeon** deve parecer o começo de uma educação perigosa. O aprendiz é pequeno, a arquitetura é mais antiga que seu conhecimento e a magia sobreviveu a quem a criou.

Mantenha a maioria das salas silenciosas: pedra fria, sombras profundas, inscrições apagadas e tochas ocasionais. Introduza cristais e cores mágicas mais intensas em lugares importantes, como a descoberta de um feitiço, um encontro com a cobra mentora ou a apresentação de um novo inimigo.

> **Regra central de ArcaneSyntax:** a masmorra pode ser enigmática, mas a jogabilidade nunca deve ser confusa. A arquitetura conta a história, as silhuetas comunicam perigo e o código luminoso mostra onde a magia vive.
