# MAG-acoes — As ações do feitiço acontecem no mundo

- **Status:** Implementada
- **Sprint:** 6
- **Relacionadas:** MAG-formas, MAG-elementos, GRI-slots, EXE-pecas, MUN-movimento (MUN-015)
- **Decisão do Victor (2026-10-25):** quando o feitiço dá erro, as ações anteriores ao erro **acontecem** no mundo.

## Contexto

O executor devolve a fila de ações do feitiço, cada uma com a linha que a gerou (ADR-001). Esta sprint faz a fila acontecer: o projétil voa, o escudo aparece, o mago anda e levita.

## Regras

1. O `ActionPlayer` toca as ações **em ordem**, uma depois da outra. Cada ação tem uma duração antes da próxima começar:

   | Ação | O que acontece | Próxima ação começa |
   | --- | --- | --- |
   | `lancar` | cria o projétil ou o escudo (MAG-formas) | depois de 0,15 s (o projétil segue voando sozinho) |
   | `mover(passos)` | o mago anda `passos` tiles (sinal = direção), respeitando paredes | quando chega, ou quando fica 0,3 s sem avançar (parede), ou em até 3 s |
   | `levitar(altura)` | o mago sobe `altura` tiles sem gravidade (MUN-015), paira 0,3 s e solta | depois de pairar |
   | `meditar` | o mago fica parado, com aura | depois de 0,5 s |
   | `absorver_mana` | brilho rápido | depois de 0,08 s |

2. Enquanto o feitiço move o mago (`mover`, `levitar`, `meditar`), o teclado não controla o movimento; ao terminar, o controle volta.
3. Se outra conjuração termina enquanto a fila anterior ainda toca, as novas ações **esperam na fila** e tocam em seguida.
4. Ação desconhecida: é pulada com um aviso (`push_warning`), sem travar a fila.
5. **Ações parciais:** se o feitiço deu erro, as ações anteriores ao erro tocam normalmente.
6. Com o jogo pausado (grimório aberto), a fila e tudo que ela criou **param** e continuam ao despausar.
7. As visões (`print`) aparecem flutuando sobre o mago (até 3, as últimas) por 2 s, além do registro.
8. A mana continua sendo aplicada quando o resultado chega (GRI-slots), não aos poucos durante as ações.

## Critérios de aceite

### MAG-001 — Ordem

- **Dado** a fila `meditar`, `lancar`, `mover`
- **Então** o mundo recebe as três, nessa ordem, cada uma só depois da anterior terminar

### MAG-002 — Ação desconhecida

- **Dado** a fila `dancar`, `meditar`
- **Então** `dancar` é pulada e `meditar` acontece

### MAG-003 — Fila de conjurações

- **Quando** uma segunda fila chega com a primeira ainda tocando
- **Então** a segunda começa só quando a primeira termina

### MAG-004 — Mover

- **Dado** o mago no chão, com espaço livre
- **Quando** toca `mover(3)`
- **Então** o mago anda 48 px (tolerância de 4 px) para a direita; com `mover(-2)`, 32 px para a esquerda

### MAG-005 — Mover contra a parede termina

- **Dado** uma parede a 1 tile
- **Quando** toca `mover(5)`
- **Então** a ação termina em menos de 1 s e o controle volta ao jogador

### MAG-006 — Levitar

- **Quando** toca `levitar(2)`
- **Então** o mago sobe cerca de 32 px (tolerância de 4 px) e depois volta ao chão

### MAG-007 — Meditar segura o mago parado

- **Dado** o teclado pedindo para andar
- **Quando** toca `meditar`
- **Então** o mago não sai do lugar durante a meditação e volta a andar depois

### MAG-008 — Ações parciais (cena)

- **Dado** um resultado com erro e a ação `mover(2)` antes dele
- **Quando** a conjuração termina
- **Então** o mago anda os 2 tiles

### MAG-009 — Pausa congela

- **Dado** um projétil voando
- **Quando** o jogo pausa
- **Então** o projétil não se move até despausar

### MAG-019 — Visões sobre o mago

- **Quando** o resultado traz as visões "a", "b", "c" e "d"
- **Então** aparecem sobre o mago "b", "c" e "d"
