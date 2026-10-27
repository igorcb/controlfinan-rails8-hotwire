# Benchmark: ControlFinan em Rails x Django x Laravel x Go x Java x Rust x C#

Mesmo app (paridade de telas e regras), mesmos dados, modo produção.
Puma e Gunicorn: 2 processos × 5 threads (com GVL/GIL, até 2 requisições usam CPU ao mesmo tempo); Laravel Octane: 2 workers, um por CPU; Go: goroutines em 2 threads (GOMAXPROCS = limite de CPU); Java: Tomcat com o pool padrão de threads; Rust: Tokio com uma thread por CPU; C#: Kestrel com o pool padrão de threads.
Cada app limitado a 2 CPUs e 1 GB de RAM, com o seu Postgres 16 (2 CPUs, 1 GB).
Carga: k6 com 20 usuários simultâneos, logado de verdade. Antes de medir, cada app passa por 20 s de carga em cada tela (aquecimento, fora da conta); depois, por tela, 10 s de aquecimento + 30 s medidos.
Os dados são carregados e analisados (`ANALYZE`) antes da medição.

Versões: Rails 8.1 + Hotwire (Puma); Django 5.2 (Gunicorn); Laravel 12 + Octane (FrankenPHP); Go 1.25 (net/http + pgx); Java 21 + Spring Boot 3.5 (Tomcat); Rust + Axum 0.8 (Tokio); C# + ASP.NET Core 9 (Kestrel).

## Requisições por segundo e latência

| Tela | App | req/s | p50 (ms) | p95 (ms) | p99 (ms) | erros | CPU média | memória pico | CPU do banco |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Conta Corrente (30 itens + saldo) | Rails | 120 | 166.7 | 214.7 | 286.3 | 0.0% | 186% | 319 MiB | 59% |
| Conta Corrente (30 itens + saldo) | Django | 96 | 45.1 | 497.5 | 537.1 | 0.0% | 190% | 107 MiB | 47% |
| Conta Corrente (30 itens + saldo) | Laravel | 128 | 154.9 | 173.3 | 191.3 | 0.0% | 148% | 103 MiB | 48% |
| Conta Corrente (30 itens + saldo) | Go | 137 | 156.3 | 282.9 | 317.2 | 0.0% | 89% | 12 MiB | 191% |
| Conta Corrente (30 itens + saldo) | Java | 98 | 198.4 | 394.9 | 493.5 | 0.0% | 192% | 179 MiB | 144% |
| Conta Corrente (30 itens + saldo) | Rust | 104 | 210.6 | 292.8 | 303.4 | 0.0% | 24% | 6 MiB | 192% |
| Conta Corrente (30 itens + saldo) | C# | 103 | 205.6 | 291.7 | 304.3 | 0.0% | 41% | 82 MiB | 195% |
| Saldo do dia (filtro) | Rails | 247 | 80.4 | 98.2 | 108.2 | 0.0% | 191% | 317 MiB | 18% |
| Saldo do dia (filtro) | Django | 188 | 106.1 | 147.8 | 167.8 | 0.0% | 141% | 107 MiB | 17% |
| Saldo do dia (filtro) | Laravel | 254 | 78.2 | 89.1 | 94.4 | 0.0% | 169% | 104 MiB | 27% |
| Saldo do dia (filtro) | Go | 2509 | 7.7 | 11.1 | 12.8 | 0.0% | 198% | 11 MiB | 103% |
| Saldo do dia (filtro) | Java | 211 | 95.4 | 187.8 | 205.0 | 0.0% | 191% | 179 MiB | 40% |
| Saldo do dia (filtro) | Rust | 2763 | 4.5 | 30.4 | 37.3 | 0.0% | 131% | 6 MiB | 193% |
| Saldo do dia (filtro) | C# | 3070 | 4.7 | 17.9 | 38.5 | 0.0% | 198% | 74 MiB | 154% |
| Dashboard do mês | Rails | 186 | 106.1 | 138.9 | 152.1 | 0.0% | 190% | 315 MiB | 32% |
| Dashboard do mês | Django | 152 | 113.0 | 266.9 | 348.6 | 0.0% | 194% | 107 MiB | 37% |
| Dashboard do mês | Laravel | 251 | 79.2 | 89.8 | 95.8 | 0.0% | 151% | 104 MiB | 42% |
| Dashboard do mês | Go | 2074 | 9.2 | 13.1 | 17.4 | 0.0% | 188% | 11 MiB | 195% |
| Dashboard do mês | Java | 225 | 92.7 | 181.9 | 200.7 | 0.0% | 198% | 196 MiB | 78% |
| Dashboard do mês | Rust | 787 | 14.6 | 68.3 | 75.0 | 0.0% | 101% | 5 MiB | 199% |
| Dashboard do mês | C# | 1042 | 9.2 | 60.5 | 67.1 | 0.0% | 185% | 78 MiB | 196% |
| API JSON (30 itens) | Rails | 304 | 65.4 | 83.4 | 92.2 | 0.0% | 186% | 317 MiB | 156% |
| API JSON (30 itens) | Django | 267 | 38.2 | 288.3 | 458.4 | 0.0% | 194% | 107 MiB | 27% |
| API JSON (30 itens) | Laravel | 238 | 83.2 | 95.2 | 102.2 | 0.0% | 178% | 104 MiB | 19% |
| API JSON (30 itens) | Go | 4934 | 3.4 | 7.1 | 12.8 | 0.0% | 178% | 11 MiB | 195% |
| API JSON (30 itens) | Java | 837 | 12.7 | 70.2 | 80.2 | 0.0% | 192% | 197 MiB | 107% |
| API JSON (30 itens) | Rust | 2956 | 4.4 | 27.7 | 33.0 | 0.0% | 139% | 6 MiB | 197% |
| API JSON (30 itens) | C# | 1814 | 5.9 | 42.0 | 54.3 | 0.0% | 196% | 78 MiB | 164% |
| Criar lançamento (POST) | Rails | 372 | 51.5 | 69.3 | 79.1 | 0.0% | 192% | 317 MiB | 32% |
| Criar lançamento (POST) | Django | 320 | 55.3 | 188.2 | 235.0 | 0.0% | 196% | 107 MiB | 42% |
| Criar lançamento (POST) | Laravel | 351 | 56.2 | 64.7 | 77.4 | 0.0% | 172% | 104 MiB | 26% |
| Criar lançamento (POST) | Go | 5584 | 2.3 | 8.2 | 24.7 | 0.0% | 142% | 11 MiB | 202% |
| Criar lançamento (POST) | Java | 4107 | 3.0 | 14.8 | 31.8 | 0.0% | 190% | 192 MiB | 154% |
| Criar lançamento (POST) | Rust | 3811 | 3.1 | 18.9 | 32.7 | 0.0% | 125% | 6 MiB | 195% |
| Criar lançamento (POST) | C# | 3928 | 3.0 | 16.8 | 35.6 | 0.0% | 202% | 69 MiB | 165% |

## Quem foi mais rápido (req/s)

| Tela | Mais rápido | Ordem |
|---|---|---|
| Conta Corrente (30 itens + saldo) | Go (1.1x Laravel, 1.1x Rails, 1.3x Rust, 1.3x C#, 1.4x Java, 1.4x Django) | Go > Laravel > Rails > Rust > C# > Java > Django |
| Saldo do dia (filtro) | C# (1.1x Rust, 1.2x Go, 12.1x Laravel, 12.4x Rails, 14.6x Java, 16.3x Django) | C# > Rust > Go > Laravel > Rails > Java > Django |
| Dashboard do mês | Go (2.0x C#, 2.6x Rust, 8.3x Laravel, 9.2x Java, 11.1x Rails, 13.6x Django) | Go > C# > Rust > Laravel > Java > Rails > Django |
| API JSON (30 itens) | Go (1.7x Rust, 2.7x C#, 5.9x Java, 16.3x Rails, 18.5x Django, 20.7x Laravel) | Go > Rust > C# > Java > Rails > Django > Laravel |
| Criar lançamento (POST) | Go (1.4x Java, 1.4x C#, 1.5x Rust, 15.0x Rails, 15.9x Laravel, 17.5x Django) | Go > Java > C# > Rust > Rails > Laravel > Django |

Vitórias: Rails 0, Django 0, Laravel 0, Go 4, Java 0, Rust 0, C# 1.

## Boot, memória e imagem

| | Rails | Django | Laravel | Go | Java | Rust | C# |
|---|---:|---:|---:|---:|---:|---:|---:|
| Subir até responder `/up` (inclui migrations) | 5.9 s | 3.3 s | 2.5 s | 0.9 s | 5.0 s | 0.9 s | 1.6 s |
| Memória parado | 127 MiB | 83 MiB | 81 MiB | 3 MiB | 125 MiB | 2 MiB | 31 MiB |
| Tamanho da imagem Docker | 519 MB | 168 MB | 224 MB | 13 MB | 233 MB | 81 MB | 228 MB |

## Código

| | Rails | Django | Laravel | Go | Java | Rust | C# |
|---|---:|---:|---:|---:|---:|---:|---:|
| Linhas de código do app (sem linhas em branco) | 787 | 1039 | 1116 | 1658 | 1617 | 2229 | 1237 |
| Linhas de teste | 549 | 392 | 338 | 579 | 521 | 783 | 386 |
