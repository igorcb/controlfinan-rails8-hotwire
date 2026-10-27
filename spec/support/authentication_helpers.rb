# Signs in through the real login form, like a browser would.
module AuthenticationHelpers
  def sign_in(user, password: "secret123")
    post session_path, params: { email_address: user.email_address, password: password }
    user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
