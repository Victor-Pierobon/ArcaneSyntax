# MAG-feixe — O feixe

- **Status:** Implementada
- **Sprint:** 21
- **Relacionadas:** MAG-formas, MAG-acoes, EXE-pecas, EXE-custo, EXE-desbloqueio, COM-dano, COM-chefe, NAR-serpente, GRI-referencia, BAL-valores

## Contexto

O Victor pediu (2026-10-27) uma forma mais forte que o projétil, "um raio tipo kamehameha ou o Zoltraak de Frieren". Ele escolheu: o mago **carrega e dispara** um feixe reto que atravessa todos os inimigos no caminho, liberado **antes do chefe** por uma lição da serpente. É a primeira peça que começa bloqueada (EXE-desbloqueio já existia, mas tudo começava liberado). O nome no código é `feixe` (`raio` já é um elemento).

## Fora do escopo

Feixe contínuo (dano por tempo), feixe que reflete ou faz curva, feixe sem alvo mirando o mouse, arte definitiva (entra pelo contrato `magia/feixe_<elemento>` quando chegar), som próprio.

## Regras

### No executor

1. `feixe` é uma forma, como `projetil`, `escudo` e `faisca`: `lancar(fogo, feixe, alvo)` registra `{"tipo": "lancar", "elemento", "forma": "feixe", "alvo"}` e custa **`custo_feixe` = 8** (em vez dos 4 do `lancar`; Sprint 21), mais as instruções de sempre (EXE-custo).
2. `feixe` é uma peça desbloqueável (EXE-desbloqueio): fora de `pecas`, usar o nome `feixe` (num `lancar` ou até num `print`) falha com `PecaBloqueada` ("você ainda não conhece feixe"), como as outras peças bloqueadas.

### No mundo

3. **Carregar:** o mago para no lugar por **0,5 s** (perde o controle, como no `meditar`), com uma bola de luz na cor do elemento crescendo na mão: é o aviso de que o feixe vem. Durante a carga ele pode ser atingido.
4. **Disparar:** sai um feixe reto da mão do mago **na direção do centro do alvo** (o `alvo` passado, pelo id) ou, sem alvo, para onde o mago olha. Ele vai até a primeira **pedra ou porta fechada** (atravessa plataformas `=`, `-`, `>`), no máximo **40 tiles**.
5. **Acerta todos** os alvos (bonecos, cristais, inimigos, o chefe) cuja área encosta no feixe (largura **8 px**), cada um uma vez, com o elemento e a forma `feixe` (COM-dano). O feixe fica visível **0,3 s**, com luz na cor do elemento, e some.
6. **Dano:** base **6** (`dano.feixe`; o projétil é 3), vezes o multiplicador do elemento (COM-dano). Contra o chefe vale o limite de fase (COM-chefe, regra 3).
7. A geometria é regra pura (`BeamRule`): onde o feixe termina (dado o que bloqueia) e quais retângulos ele encosta.

### Aprender

8. Na `sala_c03`, uma serpente com a cena `ensino_feixe` ensina o feixe. Quando a fala `licao` aparece (NAR-serpente, regra 2), `feixe` entra nas peças do mago e o registro mostra "Você aprendeu o feixe!". Vale no save (pela lição vista) e não volta a bloquear.
9. A página **Feixe** da Referência (GRI-referencia) só aparece depois de aprender.
10. O autocompletar e o realce do grimório conhecem `feixe`.

## Critérios de aceite

### MAG-080 — Feixe no executor (pytest)

- **Dado** `lancar(fogo, feixe, alvo)` com mana 10
- **Então** a ação é `{"tipo": "lancar", "linha": 1, "elemento": "fogo", "forma": "feixe", "alvo": <id>}` e o custo é 8,2 (8 do feixe, 0,1 da instrução e 0,1 da inscrição da linha)
- **E** com `pecas` sem `feixe`, o erro é `PecaBloqueada` e nenhuma ação sai; `print(feixe)` também dá `PecaBloqueada`

### MAG-081 — Custo no balanceamento

- **Então** `custo_feixe` está na seção `executor` do `balanceamento.json` e em `REGRAS_PADRAO` (iguais), e `dano.feixe` é 6

### MAG-082 — Onde o feixe termina (regra pura)

- **Dado** uma origem, uma direção e o que bloqueia (pedra e porta fechada)
- **Então** o fim é o ponto antes da primeira célula que bloqueia; plataformas não bloqueiam; sem nada, o fim fica a 40 tiles

### MAG-083 — Quem o feixe acerta (regra pura)

- **Dado** o segmento do feixe com largura 8 e retângulos em volta
- **Então** acerta os que encostam (inclusive os que só tocam a borda da largura), não os de trás da origem nem os depois do fim

### MAG-084 — Carregar e disparar (cena)

- **Dado** o mago e dois bonecos de fogo em linha, um atrás do outro, e um terceiro fora da linha
- **Quando** o feitiço `lancar(gelo, feixe, alvo)` toca
- **Então** o mago fica parado 0,5 s (não anda mesmo com a tecla), depois os dois bonecos da linha levam o golpe de gelo e o terceiro não
- **E** um elemental de fogo na linha leva 12 (6 × 2)

### MAG-085 — O feixe para na parede (cena)

- **Dado** um boneco atrás de uma parede, na linha do feixe
- **Então** o boneco não é atingido

### MAG-086 — Aprender com a serpente (cena)

- **Dado** o mundo novo
- **Então** `feixe` não está nas peças do mago e a página Feixe não aparece
- **Quando** o mago ouve a serpente `ensino_feixe` até a fala `licao`
- **Então** `feixe` está nas peças, o registro mostra o aviso, a página aparece, e o save guarda (ao carregar, continua liberado)

### MAG-087 — Contra o chefe (aceitação, Python real)

- **Dado** a arena e o mago com o feixe
- **Quando** conjura `vence = {...}` e `lancar(vence[alvo.elemento], feixe, alvo)`
- **Então** o chefe leva 12 por golpe (cortado no limite de fase quando passaria) e cai em menos conjurações que com o projétil

## Exemplos

```python
# Aprendido na sala_c03: o mesmo feitiço de sempre, com outra forma.
vence = {"fogo": gelo, "gelo": raio, "planta": fogo}
lancar(vence[alvo.elemento], feixe, alvo)
```

Custo: 8 + 0,4 (duas linhas com inscrição) = 8,4. Dano por mana parecido com o do projétil (12 por 8,4 contra 6 por 4,4); o ganho é atravessar vários inimigos e acabar a luta em menos conjurações, ao preço de ficar 0,5 s parado.

## Perguntas em aberto

- [ ] Custo 8 e dano 6 (o dobro do projétil) estão bons? (playtest; os dois estão no balanceamento)
- [ ] 0,5 s de carga é o bastante para ser arriscado contra o chefe sem ser frustrante?
