# Playtest do núcleo (fecha o marco M2)

O objetivo é descobrir se o ciclo **escrever → equipar → conjurar → ver acontecer** é entendível e divertido para alguém que não acompanhou o desenvolvimento. Não é teste de bugs; é teste de compreensão.

## Quem

1 ou 2 pessoas, idealmente:
- alguém que está **começando** a programar (o público do jogo);
- se der, alguém que já programa (para comparar).

## Preparação (10 min)

1. Guarde o seu grimório antes, para começar do zero: renomeie `%APPDATA%\Godot\app_userdata\ArcaneSyntax\grimorio.json` para `grimorio.meu.json` (desfaça depois).
2. Abra o jogo (`godot --path game` ou F5 no editor) na sala_01.
3. Imprima ou deixe aberta a **ficha do jogador** (abaixo). Ela substitui, por enquanto, a serpente e as páginas de referência, que chegam nas Sprints 12–13.
4. Tenha papel para anotar e, se a pessoa deixar, grave a tela.

## Regras para quem observa

- **Não ajude.** Se a pessoa travar por mais de 3 minutos, anote onde travou e só então dê **uma** dica, anotando qual.
- Peça para ela **pensar em voz alta** ("o que você está tentando fazer agora?").
- Não explique o que o jogo "quis dizer". Se ela entendeu errado, isso é o dado mais valioso.

## Ficha do jogador (entregar)

> Você é um aprendiz de mago. Seus feitiços são código Python.
>
> - **A/D** andam, **Espaço** pula, **Shift** esquiva, **J** golpeia com o cajado.
> - **Tab** abre o grimório (o jogo pausa). Lá você escreve feitiços, **equipa** nos botões **1–5** (ou **Passivo**) e fecha com **Esc**.
> - Teclas **1–5** conjuram o feitiço do slot.
> - Peças que você conhece: `meditar()`, `absorver_mana()`, `lancar(elemento, forma, alvo)`, `mover(passos)`, `levitar(altura)`.
>   Elementos: `fogo`, `gelo`, `raio`. Formas: `projetil`, `escudo`.
>   Você enxerga: `mana`, `mana_max`, `vida_atual`, `alvo` (com `alvo.elemento` e `alvo.distancia`).
> - Cada linha de código gasta um pouco de mana. Você começa **sem mana**.
>
> **Desafios**
> 1. Consiga mana.
> 2. Acerte o boneco de **fogo** com um projétil.
> 3. Descubra qual elemento funciona melhor contra cada boneco.
> 4. Faça a mana se recuperar sozinha, sem você apertar nada.
> 5. Escreva **um só** feitiço que acerte cada boneco com o elemento certo.

## O que observar (anotar com o horário)

| Momento | Pergunta |
| --- | --- |
| Primeiros 2 min | Achou o grimório sozinho? Entendeu que precisa equipar antes de conjurar? |
| Desafio 1 | Escreveu `meditar()`? Leu o registro no canto? Percebeu a mana subindo no HUD? |
| Erros | Leu a frase no mundo? Leu o erro do Python? Usou a linha marcada para corrigir? Usou o **Testar**? |
| Desafio 2 | Entendeu `alvo`? Percebeu que o alvo é o boneco mais perto? |
| Desafio 3 | Notou `Fraco!` / `Resistiu`? Experimentou elementos diferentes? |
| Desafio 4 | Entendeu o **Passivo**? Escreveu um loop? Entendeu por que o passivo foi desligado, se aconteceu? |
| Desafio 5 | Chegou no `if`/`elif` com `alvo.elemento`? Quanto tempo levou? Gostou de ver o mesmo feitiço servir para os três? |
| Sempre | Momentos de "ahá!" (sorriso, comentário) e de frustração (suspiro, silêncio longo) |

## Perguntas no fim (5 min)

1. O que foi mais divertido? E o mais chato?
2. Teve alguma hora em que você não sabia o que fazer?
3. A mana fez sentido? Você pensou em escrever código mais curto por causa dela?
4. As mensagens de erro ajudaram?
5. Você jogaria mais? O que gostaria de fazer em seguida?

## Depois

- Registre as anotações em `docs/playtest/AAAA-MM-DD-nucleo.md` (o que viu, sem interpretar), e uma lista curta de **problemas por frequência**.
- Cada problema vira uma tarefa ou uma pergunta para a próxima sprint; ideias novas vão para o GDD.
- Restaure o seu grimório (`grimorio.meu.json` → `grimorio.json`).

**Critério do M2:** a pessoa completa os desafios 1–3 sem ajuda e entende o que cada parte da tela mostra. Os desafios 4 e 5 medem o quanto o jogo já ensina; não precisam ser completados para fechar o marco.
