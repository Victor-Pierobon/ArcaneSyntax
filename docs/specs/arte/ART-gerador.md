# ART-gerador — Gerador de sprites com o PixelLab

- **Status:** Rascunho
- **Sprint:** fora de sprint (ferramenta de apoio da Alpha 1.1, pedida pelo Victor em 2026-10-27)
- **Relacionadas:** ART-esteira (o contrato que os arquivos gerados seguem); `docs/arte/identidade-visual.md`

## Contexto

O Victor não desenha os sprites e tem uma cota de **40 gerações por mês** no PixelLab. A ferramenta `scripts/sprites/gerar.py` gera os sprites pela API do PixelLab, um por vez, na ordem de importância para o jogo, e entrega cada um já no formato do contrato (`game/assets/<pasta>/<animação>.png`). Quando a cota acaba, ela para e continua de onde parou no mês seguinte.

## Fora do escopo

- Cenário (`tiles.png`, fundos): vem de um pacote pronto (identidade visual, passo 2).
- Interface e fonte.
- Garantir qualidade artística: a IA erra; a ferramenta deixa revisar e refazer.

## Regras

### Fila

1. A fila fica em `scripts/sprites/fila.json`, **na ordem de prioridade**. Cada item tem um `id`. Um `id` com barra (`mago/andar`) é um arquivo do jogo e, pronto, vai para `game/assets/<id>.png`; um `id` sem barra (`mago_base`) é só uma base para outros itens.
2. Tipos de item:
   - `imagem`: uma imagem gerada do texto (`prompt`), no `tamanho` [largura, altura] (custa ~1 geração). Com `gerar` [largura, altura], o PixelLab desenha nesse tamanho e a ferramenta recorta o meio no `tamanho`: serve para quadros que a API não aceita, como o pilar do chefe (16×64; lado menor que 32 só vale em imagem quadrada).
   - `animacao`: anima a imagem do item `de` com a `acao` em `quadros` quadros (par, de 4 a 16; custa ~1 geração até 64 px, mais em quadros maiores: o item diz o `custo` estimado). Com `inverter: true`, os quadros ficam na ordem contrária: a animação sempre começa na imagem pronta, então o que **aparece** (o pilar que sobe do chão) é pedido sumindo e invertido.
   - `troca_cor`: copia o item `de` girando a cor para a `matiz` (0 a 360) e não custa geração. É assim que saem as variantes de elemento (`projetil_gelo` a partir do `projetil_fogo`).
3. Um item só roda quando o item `de` está **pronto** ou **aprovado**.
4. Item com `aprovar: true` para em **revisar** depois de gerado; os que dependem dele esperam o `aprovar <id>`. As bases dos personagens usam isso, para uma base ruim não estragar várias animações.
5. `refazer <id>` volta o item para pendente, e também todos os itens que dependem dele, direta ou indiretamente.

### Cota

6. Antes de cada item que custa geração, a ferramenta consulta o saldo (`GET /balance`). Se o saldo for menor que o custo estimado do item, ela para e diz quantas gerações faltam.
7. A geração cobrada de verdade (`usage.generations`) fica registrada no estado.
8. `--simular` mostra o que rodaria e o custo estimado, sem chamar a API.
9. Erro da API para a execução e marca o item com o erro; não tenta de novo sozinho. A exceção é a sobrecarga do PixelLab ("heavy load", não cobrada): o item fica com erro e a fila segue com os outros.

### Formato de saída

10. Todo pixel fica **opaco ou transparente**: alfa ≥ 128 vira 255, o resto vira 0.
11. **Alinhamento** pela imagem raiz (a primeira da cadeia `de`), com o mesmo deslocamento para todos os quadros e todas as animações da mesma raiz:
    - `pes` (padrão): o meio da caixa dos pixels opacos fica no centro horizontal e a base 2 px acima da borda de baixo.
    - `centro`: o meio da caixa fica no centro do quadro.
12. O arquivo final é uma **tira horizontal** com os quadros lado a lado. Antes de instalar, a ferramenta confere: altura igual ao quadro, largura múltipla do quadro e alfa só 0 ou 255.
13. Imagem menor que 32 px é centralizada numa tela de 32×32 para animar (o PixelLab anima a partir de 32 px) e recortada de volta ao tamanho original depois.
14. Cada item gerado também vira uma prévia ampliada em `art/ia/previa/`, para revisar sem abrir o jogo.
14a. Todo pixel opaco é trocado pela cor mais parecida da paleta do guia de estilo (sem pontilhado); `game/assets/paleta.png` tem as mesmas cores, e o teste de arte do jogo acusa cor fora dela.
14c. Imagem que volta com os quatro cantos opacos, ou cobrindo 80% do quadro, ou 40% da faixa de 2 px da borda, veio com cenário atrás: é recusada (erro, nada é instalado), a não ser que o item tenha `opaco: true` (um tile que preenche o quadro, como a porta).
14b. `relimpar <id>` refaz a limpeza (regras 10, 11 e 14a) a partir da imagem bruta, sem chamar a API: serve quando a paleta muda.

### Arquivos

15. A chave da API vem da variável de ambiente `PIXELLAB_API_TOKEN`; nunca fica em arquivo do projeto. No Windows, o valor gravado pelo `setx` (registro do usuário) vale mais que o herdado pelo processo, que pode ser de uma chave antiga.
16. Estado em `art/ia/estado.json`; imagens brutas (como vieram da API) em `art/ia/brutos/`.

## Critérios de aceite

### ART-100 — Próximo item respeita prioridade, dependência e aprovação

- **Dado** a fila `[base (aprovar), base/anim (de base), obj/a]`, com `base` em revisar
- **Então** o próximo item é `obj/a`; com `base` aprovada, é `base/anim`

### ART-101 — Refazer volta os dependentes

- **Dado** `base` → `x/anim` → `x/anim_gelo`, todos prontos
- **Quando** refaz `base`
- **Então** os três voltam a pendente; os outros itens não mudam

### ART-102 — Cota

- **Dado** saldo 1 e o próximo item com custo 2
- **Então** a execução para sem chamar a geração
- **E** `troca_cor` roda com saldo 0

### ART-103 — Pixel opaco ou transparente

- **Então** alfa 200 vira 255 e alfa 100 vira 0

### ART-104 — Alinhamento pelos pés e pelo centro

- **Dado** uma imagem 48×48 com um bloco opaco de x 10..19 e y 5..24
- **Então** com `pes` o bloco vai para x 19..28 e y 26..45 (base em y = 46)
- **E** com `centro` o bloco vai para x 19..28 e y 14..33

### ART-105 — Tira e conferência

- **Dado** 4 quadros de 16×16
- **Então** a tira tem 64×16 e passa na conferência
- **E** a conferência acusa altura errada, largura que não é múltipla do quadro e alfa parcial

### ART-106 — Tela de 32 para imagem pequena

- **Dado** uma imagem 16×16
- **Então** vai para a API numa tela 32×32 com a imagem no meio, e os quadros que voltam são recortados de volta no mesmo lugar

### ART-107 — Troca de cor

- **Dado** um pixel laranja (matiz ~30°) e um cinza
- **Quando** troca para a matiz 200
- **Então** o laranja fica com a matiz ~200 e o cinza não muda

### ART-108 — A fila do projeto é válida

- **Dado** `scripts/sprites/fila.json`
- **Então** os ids são únicos, todo `de` aponta para um item anterior, todo id com barra existe no `game/content/arte.json`, e nenhum item custa mais de 2 gerações (a fila pode passar de uma cota de 40; a regra 6 confere a cota item a item)

### ART-109 — Paleta

- **Então** cada pixel opaco vira a cor mais parecida da paleta; o transparente continua transparente

### ART-110 — Paleta igual à do guia

- **Então** a paleta da `fila.json` é a do `ArcaneSyntax_Guia_de_Estilo_Visual.md`, na mesma ordem, e cada rampa de escola usa só cores dela

### ART-111 — De ponta a ponta

- **Dado** uma API falsa
- **Então** a fila gera, limpa, instala e para na aprovação; `relimpar` não chama a API; `refazer` tira o arquivo do jogo
- **E** arte que já existe em `game/assets` e não foi feita pela ferramenta não é sobrescrita

### ART-112 — Imagem com fundo é recusada

- **Dado** uma imagem com os quatro cantos opacos, ou que cobre 80% do quadro ou 40% da borda
- **Então** o item vira erro e nada vai para `game/assets`; com `opaco: true`, passa
- Regressão: o primeiro elemental gerado veio com uma caverna atrás e aparecia como um quadrado no jogo.

### ART-114 — Sobrecarga não para a fila

- **Dado** uma animação que falha por "heavy load"
- **Então** ela fica com erro e o próximo item roda

### ART-115 — Gerar maior e recortar

- **Dado** um item `imagem` com `tamanho` [16, 64] e `gerar` [32, 64]
- **Quando** a fila roda
- **Então** a API recebe 32×64 e o arquivo instalado tem 16×64, com o meio da imagem gerada
- **E** `gerar` menor que o `tamanho` é erro na validação da fila

### ART-116 — Animação invertida

- **Dado** uma animação com `inverter: true`
- **Então** o último quadro instalado é o primeiro que a API devolveu (a imagem pronta)

### ART-117 — A chave nova do `setx` vale na hora

- **Dado** no Windows, o processo com `PIXELLAB_API_TOKEN` antigo e o registro do usuário com outro valor
- **Então** a ferramenta usa o do registro; sem nada no registro, usa a do processo
- Regressão (2026-10-27): o `setx` não muda processos já abertos (o Claude Code e os comandos que ele abre), e a ferramenta seguia com a chave antiga.

## Decisões

- 2026-10-27: o primeiro mago mostrou que a paleta de 24 cores não tinha madeira nem tecido fora das cores de magia (o cajado virava vermelho-brasa). O Victor escolheu acrescentar 3 cores de materiais ao guia (27 no total).
