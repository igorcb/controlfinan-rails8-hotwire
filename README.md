# ControlFinan

![Ruby](https://img.shields.io/badge/Ruby-3.4-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1-CC0000?logo=rubyonrails&logoColor=white)
![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-FFE801)
![Tailwind](https://img.shields.io/badge/Tailwind-4-06B6D4?logo=tailwindcss&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)

Aplicação web para controle financeiro pessoal, pensada para quem trabalha como motorista de aplicativo. Cada usuário registra entradas (créditos) e saídas (débitos) em contas como dinheiro, bancos e carteiras de aplicativos, e acompanha o saldo por dia e por mês.

O layout é responsivo: dá para fazer os lançamentos pelo celular, durante o dia.

Esta versão reescreve em Rails 8 + Hotwire o ControlFinan original (Rails 4.2). O material do sistema antigo está em [`docs/legado-referencia/`](docs/legado-referencia/).

## Funcionalidades

| Tela | Rota | O que faz |
|---|---|---|
| Conta Corrente | `/` | Lista os lançamentos, do mais recente para o mais antigo, 30 por página, com o saldo total |
| Saldo do dia | `/?date=AAAA-MM-DD` | Filtra a listagem por um dia e mostra o saldo daquele dia |
| Novo lançamento | `/current_accounts/new` | Cadastra um crédito ou um débito |
| Detalhe, edição e exclusão | `/current_accounts/:id` | Mostra, altera ou remove um lançamento |
| Dashboard | `/dashboard` | Abas **Saldo Diário** (saldo de cada dia do mês) e **Saldo Mensal** (corridas menos combustível, lavagem e telefone). As setas navegam entre os meses |
| JSON | `/current_accounts.json` e `/current_accounts/:id.json` | Os mesmos dados, para integrações |
| Cadastro, login e senha | `/registration/new`, `/session/new`, `/passwords/new` | Conta de usuário, com senha de no mínimo 6 caracteres |

Cada usuário só enxerga os próprios lançamentos.

### Campos de um lançamento

- **Tipo:** Crédito (soma ao saldo) ou Débito (subtrai do saldo).
- **Valor:** positivo, por exemplo `150.00`. O sinal vem do tipo.
- **Data.**
- **Categoria:** Combustível, Central, Aluguel Carro, Almoço, Lanche, Diversos, Corridas, Telefone, Lavagem, Transferência, Depósitos, Estacionamento, Impostos, Multas, Manutenção ou Viagens Uber.
- **Conta:** Conta Dinheiro, Itaú, Santander, CEF Poupança, PagSeguro, Uber, Platinum Itaú, Banco do Brasil ou 99Pop.
- **Histórico:** texto livre, opcional.

O saldo é a soma de `valor × tipo`, ou seja, créditos menos débitos.

## Tecnologias

- Ruby 3.4 e Rails 8.1, com a autenticação nativa do Rails 8 (`has_secure_password`)
- PostgreSQL 16
- Hotwire (Turbo e Stimulus), esbuild e Tailwind CSS 4
- Solid Cache, Solid Queue e Solid Cable
- Docker Compose para o ambiente de desenvolvimento

## Como rodar com Docker

Pré-requisitos: Docker e Docker Compose.

```bash
docker compose up -d
```

Na primeira vez a imagem é construída e as gems e os pacotes JS são instalados, o que leva alguns minutos. O container cria o banco, roda as migrations e sobe três processos pelo `bin/dev`: o servidor Rails, o build de JS e o build de CSS.

Abra http://localhost:3001. Pelo celular ou por outra máquina na mesma rede, use o IP do computador onde o app está rodando, também na porta 3001.

O container roda com o UID/GID 1000, para que os arquivos gerados dentro dele pertençam ao seu usuário. Se o seu UID for outro, ajuste os `ARG` do `Dockerfile.dev`.

### Criar o primeiro usuário

Não há usuário padrão. Acesse `/registration/new`, ou crie pelo console:

```bash
docker compose exec web bin/rails runner 'User.create!(email_address: "voce@email.com", password: "suasenha")'
```

### Comandos úteis

| Ação | Comando |
|---|---|
| Ver logs | `docker compose logs -f web` |
| Console Rails | `docker compose exec web bin/rails console` |
| Rodar migrations | `docker compose exec web bin/rails db:migrate` |
| Rubocop | `docker compose exec web bin/rubocop` |
| Parar | `docker compose down` |
| Parar e apagar o banco | `docker compose down -v` |

## Testes

46 testes com **RSpec** e **FactoryBot** cobrindo os modelos (validações em pt-BR, saldo, saldo por dia, totais por categoria e token de redefinição de senha), as requisições (login, limite de 10 tentativas a cada 3 minutos, cadastro, redefinição de senha, lançamentos com filtro, paginação, JSON e isolamento entre usuários, e Dashboard) e o e-mail de redefinição de senha.

```bash
docker compose exec -e RAILS_ENV=test web bin/rails db:create db:schema:load   # só na primeira vez
docker compose exec web bundle exec rspec
```

## Estrutura

- `app/models/current_account.rb`: o lançamento, com as contas, as categorias, as validações e os cálculos de saldo.
- `app/models/user.rb`: o usuário, que possui vários lançamentos.
- `app/controllers/current_accounts_controller.rb`: CRUD dos lançamentos e filtro de saldo por dia.
- `app/controllers/dashboards_controller.rb`: Dashboard do mês.
- `app/controllers/registrations_controller.rb`: cadastro de usuário. Login e senha usam os controllers gerados pelo Rails 8.
- `app/javascript/controllers/tabs_controller.js`: abas do Dashboard (Stimulus).
- `Dockerfile.dev` e `docker-compose.yml`: ambiente de desenvolvimento. O `Dockerfile` é o de produção.

## Diferenças em relação ao legado

- A autenticação usa a do Rails 8, no lugar do Devise. A senha exige no mínimo 6 caracteres.
- A consulta de saldo diário (`/search_account`) virou um filtro na listagem. A rota antiga redireciona para ele.
- O Dashboard permite escolher o mês e mantém só as abas Saldo Diário e Saldo Mensal.
- A tela Moviment, com a lista de locais de Fortaleza, foi removida.
- Os nomes das colunas de `current_accounts` são os mesmos do legado, para facilitar uma importação de dados.

## Limitações conhecidas

- Contas e categorias continuam fixas no código, e não em tabelas editáveis.
- O e-mail de redefinição de senha só funciona com o envio de e-mails configurado (Action Mailer).
- Os dados do legado ainda não foram importados. Os usuários vindos do Devise precisariam redefinir a senha.

## Benchmark

O mesmo app foi escrito em sete linguagens, com paridade de telas e regras: Rails (este repositório), [Django](https://github.com/igorcb/controlfinan-django), [Laravel](https://github.com/igorcb/controlfinan-laravel), [Go](https://github.com/igorcb/controlfinan-go), [Java](https://github.com/igorcb/controlfinan-java), [Rust](https://github.com/igorcb/controlfinan-rust) e [C#](https://github.com/igorcb/controlfinan-csharp). As sete foram medidas com os mesmos dados e os mesmos limites (2 CPUs e 1 GB de RAM por app, 20 usuários simultâneos).

| Requisições por segundo | Rails | Django | Laravel | Go | Java | Rust | C# |
|---|---:|---:|---:|---:|---:|---:|---:|
| Conta Corrente (30 itens + saldo) | 120 | 96 | 128 | **137** | 98 | 104 | 103 |
| Saldo do dia (filtro) | 247 | 188 | 254 | 2.509 | 211 | 2.763 | **3.070** |
| Dashboard do mês | 186 | 152 | 251 | **2.074** | 225 | 787 | 1.042 |
| API JSON (30 itens) | 304 | 267 | 238 | **4.934** | 837 | 2.956 | 1.814 |
| Criar lançamento (POST) | 372 | 320 | 351 | **5.584** | 4.107 | 3.811 | 3.928 |

O método, os recursos (memória, imagem e boot), as conclusões e as lições de medição estão em [benchmark/README.md](benchmark/README.md).

## Licença

Distribuído sob a licença [MIT](LICENSE): você pode usar este código como base para o seu próprio app, alterar e distribuir à vontade.

> Existe uma versão com recursos adicionais para motoristas de aplicativo (relatórios, importação de dados e outros), mantida **à parte** e **não** incluída neste repositório.
