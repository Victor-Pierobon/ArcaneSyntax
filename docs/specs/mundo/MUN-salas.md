# MUN-salas — Salas, layout e transições

- **Status:** Implementada
- **Sprint:** 3
- **Relacionadas:** MUN-vida, MUN-movimento; Sprint 14 (mapa completo)

## Contexto

A torre é um mapa contínuo dividido em salas. Enquanto não há arte definitiva, as salas são descritas em texto (um caractere por tile de 16 px), o que deixa o mapa fácil de revisar no git e de testar. Quando o tileset definitivo chegar, a mesma `Room` aceita tiles pintados no editor (decidir na hora).

## Regras

1. **Legenda do layout:**

   | Caractere | Significado |
   | --- | --- |
   | `#` | pedra (sólido) |
   | `=` | plataforma (atravessável por baixo) |
   | `^` | espinhos |
   | `*` | marcador de ponto seguro (invisível) |
   | `A`–`Z` | entrada: o mago aparece com os pés no fundo desta célula |
   | `a`–`z` | saída: tocar leva a outra sala |
   | `1`–`9` | boneco de treino ou cristal (elemento em `targets`; MUN-alvos, PUZ-validacao) |
   | `\|` | porta de runas: sólida até o puzzle da sala ser resolvido (PUZ-validacao) |
   | `.` ou espaço | vazio |

2. Cada sala é uma cena em `res://content/rooms/<id>.tscn` com o script `Room`: `layout` (texto), `exits` (mapa letra → `"sala:Entrada"`, ex.: `{"b": "sala_02:A"}`).
3. Os limites da sala são o retângulo do layout (largura da maior linha × número de linhas, em tiles). A câmera fica presa a esses limites.
4. **Transição:** tocar uma saída troca a sala atual pela sala de destino, põe o mago na entrada indicada, parado, e atualiza câmera e ponto seguro.
5. Erros de autoria (caractere desconhecido, saída sem destino, entrada inexistente) são reportados com `push_error` e não travam o jogo: a entrada inexistente cai na primeira entrada da sala.
6. Uma entrada deve ficar a pelo menos 2 tiles da saída que leva de volta, para o mago não voltar sem querer.
7. As áreas da sala (saídas, espinhos, pontos seguros) só passam a detectar o mago **depois do primeiro quadro de física** da sala. No quadro em que a sala entra, o servidor de física ainda pode ter o mago na posição antiga e disparar uma área por engano (bug encontrado pelo MUN-027 na Sprint 3).
8. **Física do level design:** o pulo alcança 3 tiles (48 px) quase no limite; degraus que o jogador precisa subir devem ter **no máximo 2 tiles** de altura. Toda sala precisa permitir voltar para a entrada.

## Critérios de aceite

### MUN-030 — Leitura do layout

- **Dado** o layout `"A..b\n#=^#"` com `*` em algum lugar
- **Então** largura 4, altura 2, pedra em (0,1) e (3,1), plataforma em (1,1), espinho em (2,1), entrada A em (0,0), saída b em (3,0), e a posição dos pés da entrada é (8, 16)

### MUN-031 — Erros de autoria

- **Dado** um layout com caractere desconhecido
- **Então** `errors` lista a linha e a coluna, e o resto é lido normalmente

### MUN-032 — Tiles e colisão (cena)

- **Dado** uma sala com chão de pedra
- **Então** o mago pousa no chão; numa plataforma, pousa vindo de cima e atravessa vindo de baixo

### MUN-033 — Transição (cena)

- **Dado** o mago na sala 1, andando para a saída `b` que leva a `sala_2:A`
- **Quando** toca a saída
- **Então** a sala atual é `sala_2`, o mago está na entrada A, parado, e os limites da câmera são os da sala 2

### MUN-034 — Ida e volta (cena)

- **Dado** o mago foi da sala 1 para a sala 2
- **Quando** toca a saída que leva de volta para `sala_1:B`
- **Então** está na sala 1, na entrada B, e só existe uma sala carregada

### MUN-035 — Entrada inexistente não trava

- **Quando** uma saída aponta para uma entrada que não existe na sala de destino
- **Então** o mago aparece na primeira entrada da sala, com um erro registrado

### MUN-036 — Salas do jogo são consistentes

- **Dado** todas as cenas em `res://content/rooms/`
- **Então** cada uma tem layout sem erros, ao menos uma entrada, e toda saída aponta para uma sala e uma entrada que existem
