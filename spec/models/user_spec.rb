require "rails_helper"

RSpec.describe User do
  describe "validations" do
    it "is valid with an e-mail and a password of at least 6 characters" do
      expect(build(:user)).to be_valid
    end

    it "normalizes the e-mail" do
      expect(create(:user, email_address: "  Driver@Example.COM ").email_address).to eq("driver@example.com")
    end

    it "requires a valid and unique e-mail" do
      create(:user, email_address: "taken@example.com")

      expect(validation_errors(build(:user, email_address: "bad"))).to include("E-mail não é válido")
      expect(validation_errors(build(:user, email_address: "TAKEN@example.com"))).to include("E-mail já está em uso")
    end

    it "requires a password of at least 6 characters that matches the confirmation" do
      user = build(:user, password: "123", password_confirmation: "456")

      expect(validation_errors(user)).to include(
        "Confirmação da senha não é igual a Senha", "Senha é muito curto (mínimo: 6 caracteres)"
      )
    end
  end

  describe "password digest" do
    it "uses the bcrypt $2a$ format" do
      expect(create(:user).password_digest).to start_with("$2a$")
    end

    it "authenticates by e-mail and password" do
      user = create(:user, email_address: "driver@example.com", password: "secret123")

      expect(User.authenticate_by(email_address: "driver@example.com", password: "secret123")).to eq(user)
      expect(User.authenticate_by(email_address: "driver@example.com", password: "wrong")).to be_nil
    end
  end

  describe "password reset token" do
    it "finds the user by a valid token" do
      user = create(:user)

      expect(User.find_by_password_reset_token(user.password_reset_token)).to eq(user)
    end

    it "expires after 15 minutes" do
      user = create(:user)
      token = user.password_reset_token

      travel 16.minutes do
        expect(User.find_by_password_reset_token(token)).to be_nil
      end
    end

    it "stops working after the password changes" do
      user = create(:user)
      token = user.password_reset_token
      user.update!(password: "another123", password_confirmation: "another123")

      expect(User.find_by_password_reset_token(token)).to be_nil
    end
  end

  describe "associations" do
    it "removes sessions and entries with the user" do
      user = create(:user)
      user.sessions.create!
      create(:current_account, user: user)

      expect { user.destroy }.to change(Session, :count).by(-1).and change(CurrentAccount, :count).by(-1)
    end
  end
end
