require "rails_helper"

RSpec.describe "Passwords" do
  include ActiveJob::TestHelper

  let(:notice) { "Se o e-mail estiver cadastrado, enviamos as instruções para redefinir a senha." }

  it "sends the reset e-mail without revealing whether the address exists" do
    create(:user, email_address: "driver@example.com")

    perform_enqueued_jobs do
      post passwords_path, params: { email_address: "driver@example.com" }
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq(notice)

      post passwords_path, params: { email_address: "missing@example.com" }
      expect(flash[:notice]).to eq(notice)
    end

    expect(ActionMailer::Base.deliveries.map(&:to)).to eq([ [ "driver@example.com" ] ])
  end

  it "resets the password and ends every session" do
    user = sign_in(create(:user, password: "old-secret"), password: "old-secret")
    token = user.password_reset_token

    get edit_password_path(token)
    expect(response.body).to include("Defina sua nova senha")

    put password_path(token), params: { password: "new-secret", password_confirmation: "new-secret" }

    expect(response).to redirect_to(new_session_path)
    expect(flash[:notice]).to eq("Senha redefinida.")
    expect(user.reload.authenticate("new-secret")).to be_truthy
    expect(user.sessions.count).to eq(0)
  end

  it "rejects passwords that do not match" do
    token = create(:user).password_reset_token

    put password_path(token), params: { password: "new-secret", password_confirmation: "other" }

    expect(response).to redirect_to(edit_password_path(token))
    expect(flash[:alert]).to eq("As senhas não conferem ou têm menos de 6 caracteres.")
  end

  it "rejects an invalid token" do
    get edit_password_path("invalid")

    expect(response).to redirect_to(new_password_path)
    expect(flash[:alert]).to eq("O link de redefinição é inválido ou expirou.")
  end
end
