FactoryBot.define do
  factory :coupon do
    sequence(:name) { |n| "Coupon #{n}" }
    sequence(:code) { |n| "CODE#{n}" }
    value { 10 }
    value_type { "dollar" }
    active { true }
    association :merchant
  end
end