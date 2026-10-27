require "rails_helper"

RSpec.describe "Sessions" do
  let!(:user) { create(:user, email_address: "driver@example.com", password: "secret123") }

  it "shows the login form" do
    get new_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Esqueceu a senha?")
  end

  it "redirects guests to the login and back to the page they asked for" do
    get dashboard_path
    expect(response).to redirect_to(new_session_path)

    post session_path, params: { email_address: "driver@example.com", password: "secret123" }

    expect(response).to redirect_to(dashboard_url)
    expect(cookies[:session_id]).to be_present
    expect(user.sessions.count).to eq(1)
  end

  it "rejects a wrong password" do
    post session_path, params: { email_address: "driver@example.com", password: "wrong" }

    expect(response).to redirect_to(new_session_path)
    expect(flash[:alert]).to eq("E-mail ou senha inválidos.")
  end

  it "limits login attempts to 10 every 3 minutes" do
    10.times { post session_path, params: { email_address: "x@example.com", password: "x" } }
    post session_path, params: { email_address: "x@example.com", password: "x" }

    expect(flash[:alert]).to eq("Tente novamente mais tarde.")
  end

  it "signs out and deletes the session" do
    sign_in user

    expect { delete session_path }.to change(Session, :count).by(-1)
    expect(response).to redirect_to(new_session_path)
    expect(response).to have_http_status(:see_other)
  end
end
