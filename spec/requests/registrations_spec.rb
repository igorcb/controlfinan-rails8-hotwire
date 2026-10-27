require "rails_helper"

RSpec.describe "Registrations" do
  it "creates an account and signs in" do
    expect {
      post registration_path, params: { user: { email_address: " New@Example.com ", password: "secret123", password_confirmation: "secret123" } }
    }.to change(User, :count).by(1)

    expect(response).to redirect_to(root_path)
    expect(flash[:notice]).to eq("Conta criada.")
    expect(User.last.email_address).to eq("new@example.com")
    expect(cookies[:session_id]).to be_present
  end

  it "shows the validation messages" do
    post registration_path, params: { user: { email_address: "bad", password: "1", password_confirmation: "2" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Confirmação da senha não é igual a Senha", "E-mail não é válido")
  end
end
