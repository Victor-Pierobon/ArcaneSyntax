# Feitiços de exemplo

Feitiços prontos para copiar e testar. Todos rodam no executor atual (Sprint 6).

## Onde testar

- **No jogo (Sprint 5):** **Tab** abre o grimório → **Novo** → cole o código → botões **1–5** equipam no slot → **Esc** fecha → teclas **1–5** conjuram. O resultado aparece no registro, no canto superior direito; a mana do HUD muda de verdade. **Testar** no grimório executa sem gastar mana e marca a linha do erro. Desde a Sprint 6 as ações **acontecem no mundo**: o projétil voa até o alvo (o boneco mostra `Fraco!`, `Resistiu` ou `Acertou`), o escudo aparece em volta do mago, `mover` e `levitar` movem o mago e as visões (`print`) flutuam sobre ele. **J** dá um golpe de cajado, sem mana.
  - **Alvos na sala_01:** um boneco de **fogo** perto do início, um de **planta** um pouco à frente e um de **raio** depois dos espinhos. O alvo do feitiço é o boneco mais próximo num raio de 12 tiles; ande até um deles para mudar o alvo.
  - O jogo começa com **mana 0**: conjure primeiro um feitiço de recarga (1.1 ou 2.1).
- **Console de feitiços** (mana e alvo escolhidos à mão): `godot --path game res://src/nodes/dev/spell_console.tscn`, ou abra `src/nodes/dev/spell_console.tscn` no editor e aperte **F6**. Cole o código, escolha a mana inicial e o alvo no topo, e aperte **Ctrl+Enter**. O console usa `mana_max` 10 e um alvo a 3 tiles de distância.

Cada feitiço diz a **mana inicial** e o **alvo** sugeridos e o resultado esperado.

## Custos para ter em mente

| O quê | Custo |
| --- | --- |
| Cada instrução simples (`x = 1`, `print(...)`, `meditar()`) | 0,1 |
| `while`, `if`, `for`, `def` por si | 0 |
| `lancar` / `mover` / `levitar` | 3 / 1 / 2 (mais 0,1 da instrução) |
| `meditar()` / `absorver_mana()` | grátis; dão +5 / +1 de mana |

---

## 1. Primeiros passos

### 1.1 O primeiro feitiço do jogo

Mana inicial **0**, qualquer alvo.

```python
meditar()
```

Esperado: uma ação `meditar`, mana final **4.9** (ganhou 5, a instrução custou 0,1).

### 1.2 Visões (print)

Mana inicial **2**.

```python
print("olá, torre")
print("minha mana:", mana, "de", mana_max)
```

Esperado: duas visões; a segunda mostra `1.9 de 10` (a primeira instrução já custou 0,1).

### 1.3 Variáveis

Mana inicial **5**.

```python
passos = 3
altura = passos - 1
mover(passos)
levitar(altura)
print("andei", passos, "e subi", altura)
```

Esperado: ações `mover` (3) e `levitar` (2); custo 3,5.

---

## 2. Mana

### 2.1 Feitiço passivo do GDD

Mana inicial **0**.

```python
while mana < mana_max:
    absorver_mana()
print("mana cheia:", mana)
```

Esperado: 12 ações `absorver_mana` (cada volta rende +0,9), visão `mana cheia: 10`, mana final 9.9 (o `print` custou 0,1).

### 2.2 Só medita quando precisa

Teste com mana inicial **2** e depois com **9**.

```python
if mana < 5:
    meditar()
    print("meditei")
else:
    print("mana suficiente")
```

Esperado: com 2, medita (mana final 6.8); com 9, só mostra a visão (custo 0,1).

### 2.3 Checar antes economiza

Mana inicial **10** (cheia). Rode os dois e compare o custo no console.

```python
if mana < mana_max:
    absorver_mana()
```

```python
absorver_mana()
```

Esperado: o primeiro custa **0** (nada rodou dentro do `if`); o segundo custa **0.1**.

---

## 3. Combate

### 3.1 Bola de fogo

Mana inicial **5**, alvo **gelo**.

```python
lancar(fogo, projetil, alvo)
```

Esperado: uma ação `lancar` com elemento `fogo` no alvo `alvo_1`; custo 3.1.

### 3.2 O feitiço adaptável (o momento do trailer)

Mana inicial **5**. Troque o alvo entre **fogo**, **planta** e **raio** e veja o elemento mudar.

```python
def feitico_adaptavel(alvo):
    if alvo.elemento == "fogo":
        lancar(gelo, projetil, alvo)
    elif alvo.elemento == "planta":
        lancar(fogo, projetil, alvo)
    else:
        lancar(raio, projetil, alvo)

feitico_adaptavel(alvo)
```

Esperado: alvo fogo → `gelo`; planta → `fogo`; qualquer outro → `raio`.

### 3.3 Fraquezas num dicionário (o bestiário)

Mana inicial **5**, alvo **planta**.

```python
fraquezas = {"fogo": gelo, "planta": fogo, "gelo": raio}

if alvo is None:
    print("nada para mirar")
else:
    elemento = fraquezas.get(alvo.elemento, raio)
    lancar(elemento, projetil, alvo)
    print("lancei", elemento, "em", alvo.elemento)
```

Esperado: lança `fogo`; com alvo "(nenhum)", só a visão `nada para mirar`.

### 3.4 Escudo se o inimigo está perto

Mana inicial **5**, alvo **raio** (o console põe o alvo a 3 tiles).

```python
if alvo is not None and alvo.distancia < 4:
    lancar(raio, escudo)
    print("escudo erguido")
else:
    print("longe demais, guardando mana")
```

Esperado: ação `lancar` com forma `escudo` e alvo `null`.

### 3.5 Rajada

Mana inicial **10**, alvo **gelo**.

```python
for i in range(3):
    lancar(fogo, projetil, alvo)
print("rajada pronta")
```

Esperado: 3 ações `lancar`; custo 9.4. Com mana 8 o terceiro lançamento falha com `ManaEsgotada`, e os dois primeiros continuam valendo.

---

## 4. Movimento e funções

### 4.1 Elevador com função (o puzzle 5 do plano)

Mana inicial **10**.

```python
def subir(andares):
    levitar(andares * 2)

subir(1)
subir(2)
```

Esperado: ações `levitar` com alturas 2 e 4; custo 4.4 (o `def` não custa).

### 4.2 Patrulha

Mana inicial **10**.

```python
for lado in [1, -1, 1, -1]:
    mover(lado * 2)
```

Esperado: 4 ações `mover` (2, −2, 2, −2); custo 4.4.

### 4.3 Usando math

Mana inicial **5**.

```python
import math

distancia = 7
passos = math.ceil(distancia / 3)
print("vou dar", passos, "passos")
mover(passos)
```

Esperado: visão `vou dar 3 passos` e ação `mover` (3).

---

## 5. Erros de propósito (para ver as mensagens)

### 5.1 Esqueci os dois-pontos

```python
if mana < 5
    meditar()
```

Esperado: `SyntaxError` na linha 1, nada roda.

### 5.2 Indentação errada

```python
for i in range(3):
meditar()
```

Esperado: `IndentationError` na linha 2.

### 5.3 Variável que não existe

```python
meditar()
lancar(agua, projetil)
```

Esperado: `NameError: name 'agua' is not defined` na linha 2; o `meditar()` da linha 1 continua valendo.

### 5.4 Elemento desconhecido

```python
lancar("agua", projetil)
```

Esperado: `ValueError` dizendo que os elementos válidos são fogo, gelo e raio.

### 5.5 Mana insuficiente

Mana inicial **2**.

```python
mover(1)
lancar(fogo, projetil)
```

Esperado: `mover` acontece; `ManaEsgotada` na linha 2 ("lancar() custava 3 e restavam 0.9").

### 5.6 Loop infinito

Mana inicial **5**.

```python
while True:
    pass
```

Esperado: `ManaEsgotada` na linha 2, rápido. O jogo nunca trava.

### 5.7 Tentando trapacear

```python
mana = 999
print(mana)
```

Esperado: a visão mostra a mana real, não 999.

### 5.8 Coisas proibidas

Teste uma linha por vez:

```python
import os
```

```python
open("segredo.txt")
```

```python
print(alvo.__class__)
```

Esperado: `FeiticoProibido` para o `import os` e para o `__class__`; `NameError` para o `open` (ele nem existe no feitiço).
