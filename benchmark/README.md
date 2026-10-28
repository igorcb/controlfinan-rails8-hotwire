# Benchmark: ControlFinan em nove linguagens

O mesmo app, o ControlFinan, foi escrito nove vezes com **paridade de telas e regras**: este repositório (Rails 8 + Hotwire) e as versões em [Django](https://github.com/igorcb/controlfinan-django), [Laravel](https://github.com/igorcb/controlfinan-laravel), [Go](https://github.com/igorcb/controlfinan-go), [Java](https://github.com/igorcb/controlfinan-java), [Rust](https://github.com/igorcb/controlfinan-rust), [C#](https://github.com/igorcb/controlfinan-csharp), [Node.js](https://github.com/igorcb/controlfinan-node) e [Elixir](https://github.com/igorcb/controlfinan-elixir).

As nove versões usam o mesmo esquema de banco. Elas geram o mesmo HTML (idêntico pixel a pixel no computador e no celular) e o mesmo JSON (idêntico byte a byte), e aceitam as mesmas senhas. Este benchmark mede as nove com os mesmos dados e os mesmos limites.

## Como foi medido

| | |
|---|---|
| Apps | Rails 8.1 + Hotwire (Puma, Ruby 3.4 + YJIT) · Django 5.2 (Gunicorn) · Laravel 12 + Octane (FrankenPHP) · Go 1.25 (`net/http` + pgx) · Java 21 + Spring Boot 3.5 (Tomcat) · Rust + Axum 0.8 (Tokio) · C# + ASP.NET Core 9 (Kestrel) · Node.js 22 + Fastify 5 · Elixir 1.18 + Phoenix 1.8 |
| Concorrência | Puma e Gunicorn com 2 processos × 5 threads; Octane e Node.js com 2 processos (um por CPU); Go, Java, Rust, C# e Elixir com os padrões de cada um (uso das 2 CPUs); todos com até 10 conexões com o banco |
| Limites | Cada app com **2 CPUs e 1 GB de RAM** e o seu próprio Postgres 16 (2 CPUs, 1 GB) |
| Dados | Os mesmos 7.292 lançamentos, carregados e analisados (`ANALYZE`) antes de medir |
| Carga | k6, com 20 usuários simultâneos logados pelo formulário de login de verdade |
| Aquecimento | 20 s de carga em cada tela antes de medir, fora da conta (para YJIT e JVM estabilizarem). Depois, os lançamentos criados no aquecimento são apagados e a tabela passa por `VACUUM FULL ANALYZE` |
| Medição | Por tela, 10 s de aquecimento e 30 s medidos |

## Requisições por segundo (mais é melhor)

| Tela | Rails | Django | Laravel | Go | Java | Rust | C# | Node.js | Elixir |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Conta Corrente (30 itens + saldo) | 120 | 96 | 128 | **137** | 98 | 104 | 103 | 103 | 125 |
| Saldo do dia (filtro) | 247 | 188 | 254 | 2.509 | 211 | 2.763 | **3.070** | 2.597 | 1.459 |
| Dashboard do mês | 186 | 152 | 251 | **2.074** | 225 | 787 | 1.042 | 1.544 | 711 |
| API JSON (30 itens) | 304 | 267 | 238 | **4.934** | 837 | 2.956 | 1.814 | 2.456 | 1.779 |
| Criar lançamento (POST) | 372 | 320 | 351 | **5.584** | 4.107 | 3.811 | 3.928 | 3.116 | 2.145 |

Nenhuma requisição falhou. As latências (p50, p95 e p99), a CPU do app, a CPU do banco e a memória de cada tela estão em [results/RESULTS.md](results/RESULTS.md).

## Recursos

| | Rails | Django | Laravel | Go | Java | Rust | C# | Node.js | Elixir |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Subir até responder `/up` (inclui migrations) | 5,9 s | 3,3 s | 2,5 s | **0,9 s** | 5,0 s | **0,9 s** | 1,6 s |
| Memória parado | 127 MiB | 83 MiB | 81 MiB | 3 MiB | 125 MiB | **2 MiB** | 31 MiB |
| Tamanho da imagem Docker | 519 MB | 168 MB | 224 MB | **13 MB** | 233 MB | 81 MB | 228 MB |
| Linhas de código do app | **787** | 1.039 | 1.116 | 1.658 | 1.617 | 2.229 | 1.237 |

## O que os números mostram

- **Go, Rust, C#, Node.js e Elixir estão em outra faixa nas telas leves.** Nelas, a latência mediana fica entre 2 e 25 ms, contra 40 a 110 ms em Rails, Django e Laravel. Go venceu 4 das 5 telas e C# venceu o filtro por dia, à frente de Rust e Node.js. O Node.js, com 2 processos, ficou perto do Rust; o Elixir ficou abaixo dos dois, mas bem acima de Rails, Django e Laravel. O Java chega nessa faixa no POST e no JSON, mas nesta rodada ficou junto de Rails, Django e Laravel no filtro e no dashboard (veja "Variação do Java").
- **Nas versões rápidas, quem limita muitas vezes é o Postgres, não a linguagem.** O banco ficou perto do limite (190% a 200% de 200%) enquanto o app ainda tinha folga. A lista é o caso extremo: ela soma os ~7.300 lançamentos em `numeric` a cada requisição, e por isso **as nove versões ficam entre 96 e 137 req/s nessa tela**.
- **Rust usa mais CPU do banco por requisição que Go.** Com o mesmo SQL, o Go faz quase o dobro de requisições com o banco no limite. A diferença está no caminho até o Postgres (SQLx contra pgx), não no código Rust do app, que usou pouca CPU.
- **Rails, Django e Laravel ficam próximos entre si.** O Laravel com Octane foi o melhor dos três em 3 telas e o Rails nas outras 2. Os três gastam a CPU do app antes de o banco virar gargalo.
- **Go e Rust quase não usam memória** (2 a 3 MiB parados) e sobem em menos de 1 s. O C# fica no meio (31 MiB e 1,6 s); Node.js e Elixir ficam perto de Rails e Java em memória (87 e 146 MiB).
- **O preço da velocidade é código:** o Rails tem 787 linhas; o C#, 1.237; o Rust, 2.229. Sessão, CSRF, flash, limite de tentativas e validações vêm prontos no Rails e foram escritos à mão nas outras versões.

## Variação do Java

O Java oscilou muito de uma rodada para outra, mais que os outros. Na rodada anterior, com o mesmo método, ele fez 825 req/s no filtro por dia, 700 no dashboard e 2.763 no JSON. Nesta, fez 211, 225 e 837.

A JVM otimiza o código enquanto roda (JIT), e o momento em que isso estabiliza muda de uma execução para outra, ainda mais com só 2 CPUs. Os números da tabela são os desta rodada. O resultado do Java aqui deve ser lido como uma faixa, não como um valor exato.

## Lições de medição

Cada resultado errado abaixo foi descoberto, explicado e corrigido antes da publicação:

1. **Token CSRF errado no script** (Django). O primeiro resultado do Rails falhava no POST porque o script pegava o token do botão "Sair".
2. **Conexão nova com o banco a cada requisição** (Laravel com PHP-FPM). A autenticação do Postgres custava ~15 ms por requisição. A correção foi usar conexões persistentes.
3. **Workers demais para a CPU** (Laravel). Com 10 workers PHP em 2 CPUs, o app ficou 4 vezes mais lento por estrangulamento de CPU. Agora são 2 workers, um por CPU. No Ruby e no Python isso não acontece, porque o GVL/GIL já deixa só 2 requisições usarem CPU ao mesmo tempo.
4. **Tabela sem estatísticas** (Go). A primeira tela era medida logo depois da carga dos dados, antes do `ANALYZE`.
5. **Aquecimento curto** (Java). Com 10 s de aquecimento, a JVM ainda estava fria. A mesma tela foi de 26 para 168 req/s em 6 rodadas seguidas. Agora há uma fase de aquecimento em todas as telas.
6. **Linhas mortas do aquecimento** (Go, Java e Rust). Os POSTs do aquecimento criavam dezenas de milhares de lançamentos nos apps rápidos. Apagá-los sem `VACUUM` deixava a tabela inchada só para eles.
7. **Máquina ocupada durante a medição** (Java e Rust). Uma limpeza de imagens Docker rodou junto com o teste e derrubou os números. Os dois apps foram medidos de novo.
8. **Configuração padrão do driver do banco** (C# e Node.js). Por padrão, o Npgsql limpa a sessão (`DISCARD ALL`) a cada vez que a conexão volta ao pool e não prepara as consultas. Com o banco no limite, o C# fez 928 req/s no POST. Com `No Reset On Close` e `Max Auto Prepare`, que deixam o Npgsql igual ao pgx (Go) e ao SQLx (Rust) nesse ponto, fez 3.928. No Node.js, o driver `pg` também não prepara as consultas: dando um nome a cada consulta, o filtro por dia foi de 1.156 para 2.597 req/s. O Postgrex (Elixir) já prepara por padrão.

**Meça, desconfie e confira.**

## Como reproduzir

Requisitos:
- Este repositório, com o banco de desenvolvimento no ar (`docker compose up db`). Ele fornece os dados compartilhados (`benchmark@exemplo.com` e os lançamentos).
- As outras versões clonadas ao lado: `../controlfinan-django`, `../controlfinan-laravel`, `../controlfinan-go`, `../controlfinan-java`, `../controlfinan-rust`, `../controlfinan-csharp`, `../controlfinan-node` e `../controlfinan-elixir`.

```bash
./benchmark/run.sh             # os nove: rails django laravel go java rust csharp node elixir
./benchmark/run.sh go rust     # só alguns; os resultados dos outros são mantidos
```

O relatório é gravado em `benchmark/results/RESULTS.md`. A rodada completa leva cerca de 1 hora e 30 minutos.
