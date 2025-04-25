FactoryBot.define do
  factory :customer do
    sequence(:first_name) { |n| "Customer#{n}" }
    sequence(:last_name) { |n| "Last#{n}" }
  end
end