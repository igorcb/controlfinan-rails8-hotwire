# ControlFinan

🇺🇸 **Read this in English:** [README.en.md](README.en.md)

![Ruby](https://img.shields.io/badge/Ruby-2.5-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-4.2-CC0000?logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-11-4169E1?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)

Aplicação web para controle financeiro pessoal. Cada usuário registra suas entradas (créditos) e saídas (débitos) em contas como dinheiro, bancos e carteiras de aplicativos, e acompanha o saldo por dia, por conta e por mês.

As categorias de despesa vêm prontas para quem trabalha como motorista de aplicativo: corridas, combustível, lavagem, aluguel de carro, estacionamento, multas e manutenção, entre outras.

## Sumário

- [Para que serve](#para-que-serve)
- [Funcionalidades](#funcionalidades)
- [Tecnologias](#tecnologias)
- [Como rodar com Docker](#como-rodar-com-docker)
- [Como usar](#como-usar)
- [Estrutura](#estrutura)
- [Limitações conhecidas](#limitações-conhecidas)

## Para que serve

- Registrar o dia a dia do dinheiro: quanto entrou, quanto saiu, de qual conta e em qual categoria.
- Saber o saldo de um dia específico ou o saldo total.
- Ver o resultado do mês no dashboard, com os totais das corridas descontados de combustível, lavagem e telefone.
- Manter os dados separados por usuário: cada pessoa só enxerga os próprios lançamentos.

## Funcionalidades

| Tela | Rota | O que faz |
|---|---|---|
| Conta Corrente | `/` | Lista os lançamentos do usuário, do mais recente para o mais antigo, com paginação e o saldo total |
| Novo lançamento | `/current_accounts/new` | Cadastra um crédito ou débito |
| Detalhe, edição e exclusão | `/current_accounts/:id` | Mostra, altera ou remove um lançamento |
| Consulta de saldo diário | `/search_account` | Informa uma data e mostra os lançamentos e o saldo daquele dia |
| Dashboard | `/dashboard` | Formulário de consulta de saldo por data e quatro abas do mês corrente: Saldo Diário, Por Conta, Corridas e Saldo Mensal |
| Moviment | `/moviments` | Resumo por grupos de gastos |
| Lançamentos em JSON | `/current_accounts.json` | Mesma listagem da tela principal, para integrações |

### Campos de um lançamento

- **Conta:** Dinheiro, Itaú, Santander, CEF Poupança, PagSeguro, Uber, Platinum Itaú, Banco do Brasil ou 99Pop.
- **Categoria:** Combustível, Central, Aluguel Carro, Almoço, Lanche, Diversos, Corridas, Telefone, Lavagem, Transferência, Depósitos, Estacionamento, Impostos, Multas, Manutenção ou Viagens Uber.
- **Tipo:** Crédito (soma ao saldo) ou Débito (subtrai do saldo).
- **Data**, em `dd/mm/aaaa`.
- **Valor**, positivo, por exemplo `150.00`. O sinal vem do tipo.
- **Histórico:** texto livre opcional.

O saldo é a soma de `valor × tipo`, ou seja, créditos menos débitos.

## Tecnologias

Ruby 2.5, Rails 4.2, PostgreSQL, Devise (autenticação), Bootstrap 3, bootstrap-datepicker e will_paginate. O ambiente de desenvolvimento roda em Docker.

## Como rodar com Docker

Pré-requisitos: Docker e Docker Compose.

1. Crie o arquivo `config/database.yml`, que não é versionado:

   ```yaml
   default: &default
     adapter: postgresql
     encoding: unicode
     pool: 5
     host: <%= ENV.fetch("DB_HOST", "localhost") %>
     username: <%= ENV.fetch("DB_USER", "controlfinan") %>
     password: <%= ENV.fetch("DB_PASSWORD", "controlfinan") %>

   development:
     <<: *default
     database: controlfinan_development

   test:
     <<: *default
     database: controlfinan_test
   ```

2. Suba os containers:

   ```
   docker compose up -d
   ```

   Na primeira vez a imagem é construída e as gems são instaladas, o que leva alguns minutos. O container cria o banco e roda as migrations sozinho.

3. Abra http://localhost:3000. A partir de outra máquina, use o IP ou o hostname do computador onde o app está rodando, na porta 3000.

### Criar o primeiro usuário

Não há usuário padrão. Escolha uma das opções:

- Pela tela: acesse `/users/sign_up` e informe e-mail e senha (mínimo de 8 caracteres).
- Pelo console:

  ```
  docker compose exec web bundle exec rails c
  User.create!(email: "voce@email.com", password: "suasenha123", password_confirmation: "suasenha123")
  ```

### Comandos úteis

| Ação | Comando |
|---|---|
| Ver logs | `docker compose logs -f web` |
| Console Rails | `docker compose exec web bundle exec rails c` |
| Rodar migrations | `docker compose exec web bundle exec rake db:migrate` |
| Parar | `docker compose down` |
| Parar e apagar o banco | `docker compose down -v` |

Os avisos `PGconn, PGresult, and PGError constants are deprecated` nos logs são normais: vêm da gem `pg` 0.x usada pelo Rails 4.2 e não indicam problema.

## Como usar

1. Entre com seu e-mail e senha.
2. Em **Conta Corrente**, clique em **New Current account**.
3. Escolha a conta, a categoria e se é crédito ou débito. Informe a data, o valor e, se quiser, um histórico. Clique em **Salvar**.
4. Na listagem, use **Show** e **Edit** para consultar ou corrigir um lançamento.
5. Para saber o saldo de um dia, use a consulta de saldo diário e informe a data.
6. No **Dashboard**, acompanhe o mês: saldo por dia, totais por conta, corridas e saldo mensal.

## Estrutura

- `app/models/current_account.rb`: lançamento, com as contas, categorias, validações e os cálculos de saldo.
- `app/models/user.rb`: usuário (Devise); possui vários lançamentos.
- `app/controllers/current_accounts_controller.rb`: CRUD dos lançamentos e consulta de saldo diário.
- `app/controllers/static_pages_controller.rb`: dashboard e moviment.
- `Dockerfile`, `docker-compose.yml` e `docker-entrypoint.sh`: ambiente de desenvolvimento.

## Limitações conhecidas

- As contas e categorias estão fixas no código, e não em tabelas editáveis.
- Os cálculos do dashboard usam o mês corrente; não há seleção de outro mês.
- O Rails 4.2 não recebe mais atualizações de segurança. Não exponha este app na internet sem antes atualizá-lo.
