require "rails_helper"

RSpec.describe CurrentAccount do
  describe "validations" do
    it "is valid with the factory attributes" do
      expect(build(:current_account)).to be_valid
    end

    it "returns the pt-BR messages for an empty entry" do
      entry = described_class.new(user: create(:user))

      expect(validation_errors(entry)).to contain_exactly(
        "Tipo não está incluído na lista",
        "Conta não está incluído na lista",
        "Categoria não está incluído na lista",
        "Data não pode ficar em branco",
        "Valor não pode ficar em branco",
        "Valor não é um número"
      )
    end

    it "requires a positive price" do
      expect(validation_errors(build(:current_account, price: 0))).to eq([ "Valor deve ser maior que 0" ])
    end

    it "rejects unknown accounts and categories" do
      entry = build(:current_account, cash_account_id: 99, cost_id: 99)

      expect(validation_errors(entry)).to contain_exactly(
        "Conta não está incluído na lista", "Categoria não está incluído na lista"
      )
    end
  end

  describe ".balance" do
    it "is credits minus debits" do
      user = create(:user)
      create(:current_account, user: user, price: 150)
      create(:current_account, :debit, user: user, price: 40.5)

      expect(user.current_accounts.balance).to eq(109.5)
    end
  end

  describe ".balance_by_day" do
    it "groups the balance by day, most recent first" do
      user = create(:user)
      create(:current_account, user: user, date_ocurrence: "2026-10-01", price: 10)
      create(:current_account, user: user, date_ocurrence: "2026-10-02", price: 20)
      create(:current_account, :debit, user: user, date_ocurrence: "2026-10-02", price: 5)

      expect(user.current_accounts.balance_by_day).to eq(Date.new(2026, 10, 2) => 15, Date.new(2026, 10, 1) => 10)
    end
  end

  describe ".total_by_cost" do
    it "sums the price of the given categories" do
      user = create(:user)
      create(:current_account, :debit, user: user, cost_id: 0, price: 50)
      create(:current_account, :debit, user: user, cost_id: 8, price: 20)
      create(:current_account, user: user, cost_id: 6, price: 200)

      expect(user.current_accounts.total_by_cost([ 0, 8 ])).to eq(0 => 50, 8 => 20)
    end
  end

  describe ".in_month" do
    it "keeps only the entries of the month" do
      user = create(:user)
      create(:current_account, user: user, date_ocurrence: "2026-09-30")
      inside = create(:current_account, user: user, date_ocurrence: "2026-10-31")

      expect(user.current_accounts.in_month(Date.new(2026, 10, 1))).to eq([ inside ])
    end
  end

  describe "names and signed price" do
    it "names the account, the category and the type" do
      entry = build(:current_account, :debit, cash_account_id: 1, price: 10)

      expect([ entry.name_account, entry.name_cost, entry.type_launche_name, entry.signed_price ])
        .to eq([ "Itaú", "Combustível", "Débito", -10 ])
    end

    it "falls back to 'Não definido' for unknown ids" do
      entry = build(:current_account, cash_account_id: 99, cost_id: 99)

      expect([ entry.name_account, entry.name_cost ]).to eq([ "Não definido", "Não definido" ])
    end
  end
end
