FactoryBot.define do
  factory :extension_collection do
    association :extension
    association :collection
    association :user
  end
end