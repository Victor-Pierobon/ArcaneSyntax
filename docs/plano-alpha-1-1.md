# Plano da Alpha 1.1

- **Combinado em:** 2026-10-26, depois de o Victor jogar a Alpha 1.0 inteira (editor e `.exe`), com tudo funcionando.
- **Pedido do Victor:** o visual ainda são quadrados; as salas e os níveis estão simples demais; o chefe está fácil demais.

## Objetivo

A mesma Alpha (Ato I, 13 salas, 6 puzzles, só Python), mas que **pareça um jogo** e que **desafie um pouco**. Depois do 1.1, o Victor entrega o build a algumas pessoas para testar (os testes com iniciantes da Sprint 15 passam para o fim do 1.1).

## Decisões do Victor

| Pergunta | Resposta |
| --- | --- |
| Quem faz a arte | **Misto:** cenário (tiles e fundo) de um pacote pronto, recolorido para a paleta; arte própria para o mago, a serpente, os inimigos, o chefe, os efeitos e a interface. Roteiro em `docs/arte/identidade-visual.md` |
| Salas | **Refazer as 13 salas**, mantendo o caminho e os conceitos: altura, plataformas, perigos, inimigos no caminho, áreas opcionais |
| Chefe | Hoje, quem só repete magia mata o chefe sem que ele reaja, e ele fica parado. Ele precisa **se mover**, ter **mais padrões de ataque** (por exemplo, **pilares que saem do chão**) e **bem mais vida**. Tem que ser "minimamente desafiador sem ser difícil demais" |
| Testes com iniciantes | Até agora quem testou foi o Victor, com sucesso. Algumas pessoas testam **depois do 1.1** |

## Decisões por recomendação (para o Victor revisar)

| Decisão | Por quê |
| --- | --- |
| Chefe com **três fases**: fogo (fraco a gelo) → gelo (fraco a raio) → planta (fraco a fogo) | O feitiço do dicionário que o jogo ensina (`vence[alvo.elemento]`) já cobre os três, então a fase 3 recompensa quem escreveu o feitiço adaptável. Quem fixou dois elementos à mão precisa adaptar |
| Vida do chefe **~90** (3×), calibrada para uma luta de **2 a 4 minutos** com o feitiço de referência | "Bem mais vida" sem virar esponja. O número fica no `balanceamento.json` |
| Contra o spam: o chefe **se move e ataca de forma que ficar parado conjurando faz perder**. Toda conjuração e toda meditação deixam o mago parado | Não pune quem conjura, pune quem não se protege. Vira um critério testável: "conjurar parado do começo ao fim perde; com esquiva e escudo, vence" |
| **Todo ataque tem aviso** antes (brilho, marca no chão) | Desafiador, mas justo: quem presta atenção sempre consegue fugir |
| Arena do chefe do tamanho da tela (40×22 tiles), com plataformas e a câmera fixa | Os pilares e o movimento pedem espaço; hoje a sala tem 30×8 |
| As salas refeitas ficam **pelo menos do tamanho da tela** e usam a altura | Hoje 7 das 13 salas têm 8 a 10 tiles de altura (a tela tem 22) |
| No máximo **2 elementos de mundo novos** para as salas: plataforma que se move e plataforma que cai | Variedade de travessia sem abrir escopo. O resto das ideias vai para o GDD |
| Os puzzles continuam os mesmos (mesmo conceito, mesmo validador); muda a sala ao redor e o caminho até eles | A aceitação com Python real de cada puzzle continua valendo, e o currículo não muda |
| Mais segredos (de 2 para ~5), cada um com um caminho com feitiço e um só com movimento | Regra do Victor da Sprint 14, aplicada às salas maiores |
| Arte provisória **melhor**, gerada por script, já na Sprint 16 | O jogo não fica esperando a arte; cada PNG do Victor substitui uma peça provisória |

## Sprints

O assistente segue uma sprint por vez, como antes (spec → teste → código, sem commit). O Victor faz a arte **em paralelo**, seguindo `docs/arte/identidade-visual.md`.

| Sprint | Nome | O que entrega | Horas | Depende de |
| --- | --- | --- | --- | --- |
| 16 | Esteira de arte e visual provisório | Arte lida por nome de arquivo (`game/assets/<pasta>/<animação>.png`), com o provisório quando falta; teste que confere o contrato dos arquivos; animações do mago guiadas por uma regra pura (parado, andar, pular, cair, esquivar, conjurar, meditar, cajado, dano, morrer); paredes com bordas automáticas (terrain); fundo com paralaxe; provisório gerado por script com bordas, sombra e cor por elemento | 14–20 | — |
| 17 | Chefe 2.0 | Spec COM-chefe revista: arena nova, 3 fases, vida ~90, movimento entre pontos da arena, ataques com aviso (orbes em leque, pilares do chão, investida), aceitação "parado perde, com esquiva vence" | 16–24 | 16 (animações e efeitos) |
| 18 | Salas I: começo e puzzles | `sala_01` a `03` e `p02` a `p06` refeitas: altura, plataformas, perigos, inimigos no caminho, segredos novos; plataforma que se move e plataforma que cai (se entrarem) | 18–26 | 16 (terrain) |
| 19 | Salas II: combate e fim | `c01` a `c03` refeitas (mais inimigos, ondas mistas, travessia), arena do chefe montada no mapa, `sala_fim`; mapa e Alpha inteira de novo | 14–20 | 17, 18 |
| 20 | Integração da arte e brilho | Luz (sala escura, tochas, cristais e feitiços que iluminam), partículas por elemento, tremida de câmera, runas do código, interface com a moldura e a fonte do Victor, logo no menu; ligar o que chegou de arte | 12–20 | arte do Victor |
| 21 | Feixe, chefe mais rápido e magia mais cara (pedido do Victor, 2026-10-27) | A forma `feixe` (carrega e dispara, atravessa os inimigos), aprendida com a serpente antes do chefe; o chefe mais rápido, com mais pressão e avisos mais curtos; `lancar` a 4, faísca a 1,5, meditar de 1 s | 10–16 | 20 |
| 22 | Fechamento da 1.1 | Captura de todas as salas, ajuste de valores, build `ArcaneSyntax-alpha-1.1.zip`, roteiro de teste para as pessoas que o Victor escolher | 8–12 | 20 |
| | **Total** | | **~82–122 h** | |

A Sprint 20 é a única que depende do ritmo da arte. Se a arte atrasar, ela entra com o que houver, e o resto entra numa 1.2 sem segurar o build.

## Como cada sprint verifica o que entrega

- **Chefe:** dois testes de aceitação com Python real. Um mago parado, que só conjura e medita, **perde** (com a vida de jogo, 5). Um mago que esquiva dos avisos e usa o escudo **vence com vida sobrando**. Mais as regras puras de cada ataque (aviso, tempo e dano) com TDD.
- **Salas:** `test_area_map.gd` (volta, portas e ordem dos conceitos), a aceitação de cada puzzle, os dois caminhos de cada segredo e a Alpha inteira (MUN-085), refeita para as salas novas.
- **Arte:** o teste do contrato dos arquivos, capturas de tela por script e o checklist de sensação (não dá para testar beleza).

## Fora do 1.1 (vai para o GDD se aparecer)

Sons e música definitivos, andares novos, peças novas de Python (exceto o `feixe`, pedido pelo Victor na Sprint 21), mais conceitos, ícone e assinatura do `.exe`.
