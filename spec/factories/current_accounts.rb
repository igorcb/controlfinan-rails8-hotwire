FactoryBot.define do
  factory :current_account do
    user
    cash_account_id { 5 }
    cost_id { 6 }
    type_launche { :credito }
    date_ocurrence { Date.new(2026, 10, 27) }
    price { 150 }
    historic { "Corridas" }

    trait :debit do
      type_launche { :debito }
      cost_id { 0 }
    end
  end
end
