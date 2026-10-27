require "rails_helper"

RSpec.describe "Dashboards" do
  let(:user) { sign_in(create(:user)) }

  it "shows the daily and monthly balances of the month" do
    create(:current_account, user: user, date_ocurrence: "2026-10-02", cost_id: 6, price: 200)
    create(:current_account, :debit, user: user, date_ocurrence: "2026-10-02", cost_id: 0, price: 50)
    create(:current_account, :debit, user: user, date_ocurrence: "2026-10-05", cost_id: 8, price: 20)
    create(:current_account, user: user, date_ocurrence: "2026-09-30", price: 999)

    get dashboard_path(month: "2026-10")

    body = response.body
    expect(body).to include("Outubro de 2026", "Saldo Diário", "Saldo Mensal")
    expect(body).to match(/05\/10\/2026.*-R\$ 20,00.*02\/10\/2026.*R\$ 150,00.*Total do mês.*R\$ 130,00/m)
    expect(body).to match(/Corridas.*R\$ 200,00.*Combustível.*-R\$ 50,00.*Lavagem.*-R\$ 20,00.*Telefone.*R\$ 0,00.*Saldo do mês.*R\$ 130,00/m)
    expect(body).not_to include("999")
  end

  it "links to the previous and next months" do
    user

    get dashboard_path(month: "2026-01")

    expect(response.body).to include("/dashboard?month=2025-12", "/dashboard?month=2026-02")
  end

  it "falls back to the current month for an invalid month" do
    user

    travel_to Date.new(2026, 3, 15) do
      get dashboard_path(month: "bad")
    end

    expect(response.body).to include("Março de 2026")
  end
end
