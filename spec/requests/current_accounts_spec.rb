require "rails_helper"

RSpec.describe "CurrentAccounts" do
  let(:user) { sign_in(create(:user)) }
  let(:valid_params) do
    { current_account: { type_launche: "credito", price: "150", date_ocurrence: "2026-10-27",
                         cost_id: "6", cash_account_id: "5", historic: "Corridas do dia" } }
  end

  describe "GET /current_accounts" do
    it "lists the entries with the total balance" do
      create(:current_account, user: user, price: 150)
      create(:current_account, :debit, user: user, price: 40)

      get current_accounts_path

      expect(response.body).to include("Saldo total", "R$ 110,00", "-R$ 40,00")
    end

    it "filters by day" do
      create(:current_account, user: user, date_ocurrence: "2026-10-26", price: 10)
      create(:current_account, user: user, date_ocurrence: "2026-10-27", price: 20)

      get current_accounts_path(date: "2026-10-26")

      expect(response.body).to include("Saldo do dia 26/10/2026", "R$ 10,00")
      expect(response.body).not_to include("R$ 20,00")
    end

    it "paginates 30 entries per page" do
      31.times { |n| create(:current_account, user: user, historic: "entry #{n + 1}") }

      get current_accounts_path
      expect(response.body).to include("Mais antigos →")
      expect(response.body).not_to include("← Mais recentes")

      get current_accounts_path(page: 2)
      expect(response.body).to include("← Mais recentes")
      expect(response.body).not_to include("Mais antigos →")
    end

    it "renders the JSON with the jbuilder fields" do
      entry = create(:current_account, user: user, historic: "Café/Almoço")

      get current_accounts_path(format: :json)

      expect(response.parsed_body).to eq([ {
        "id" => entry.id, "cash_account_id" => 5, "cost_id" => 6, "date_ocurrence" => "2026-10-27",
        "price" => "150.0", "historic" => "Café/Almoço", "user_id" => user.id, "type_launche" => 1,
        "url" => "http://www.example.com/current_accounts/#{entry.id}.json"
      } ])
    end
  end

  describe "access to other users' entries" do
    it "returns not found" do
      other = create(:current_account, user: create(:user))
      user

      get current_account_path(other)
      expect(response).to have_http_status(:not_found)

      expect { delete current_account_path(other) }.not_to change(CurrentAccount, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /current_accounts" do
    it "creates an entry for the signed in user" do
      user

      expect { post current_accounts_path, params: valid_params }.to change(user.current_accounts, :count).by(1)
      expect(response).to redirect_to(current_accounts_path)
      expect(flash[:notice]).to eq("Lançamento cadastrado.")
      expect(user.current_accounts.last).to have_attributes(type_launche: "credito", price: 150)
    end

    it "ignores a user_id sent in the form" do
      user
      other = create(:user)

      post current_accounts_path, params: { current_account: valid_params[:current_account].merge(user_id: other.id) }

      expect(CurrentAccount.last.user).to eq(user)
    end

    it "shows the validation messages" do
      user

      post current_accounts_path, params: { current_account: { price: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Valor não pode ficar em branco", "Tipo não está incluído na lista")
    end
  end

  describe "PATCH /current_accounts/:id" do
    it "updates the entry" do
      entry = create(:current_account, user: user)

      patch current_account_path(entry), params: { current_account: valid_params[:current_account].merge(price: "12.5") }

      expect(response).to redirect_to(current_account_path(entry))
      expect(flash[:notice]).to eq("Lançamento atualizado.")
      expect(entry.reload.price).to eq(12.5)
    end
  end

  describe "DELETE /current_accounts/:id" do
    it "deletes the entry" do
      entry = create(:current_account, user: user)

      expect { delete current_account_path(entry) }.to change(CurrentAccount, :count).by(-1)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq("Lançamento removido.")
    end
  end

  it "redirects the legacy daily search to the filter" do
    get "/search_account", params: { date_calendar_now: "2026-10-27" }

    expect(response).to redirect_to("/current_accounts?date=2026-10-27")
  end
end
