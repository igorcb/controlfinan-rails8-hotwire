FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "driver#{n}@example.com" }
    password { "secret123" }
    password_confirmation { password }
  end
end
