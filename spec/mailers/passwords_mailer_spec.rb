require "rails_helper"

RSpec.describe PasswordsMailer do
  describe "#reset" do
    it "sends the reset link with the 15 minutes expiration" do
      user = create(:user, email_address: "driver@example.com")

      mail = described_class.reset(user)

      expect(mail.subject).to eq("Redefinição de senha")
      expect(mail.to).to eq([ "driver@example.com" ])
      expect(mail.text_part.body.to_s).to include("/passwords/", "/edit", "15 minutos")
    end
  end
end
