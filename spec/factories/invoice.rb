FactoryBot.define do
  factory :invoice do
    customer
    merchant
    status { "shipped" } # or "pending"
    coupon { nil }
  end
end