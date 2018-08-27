FactoryBot.define do
  factory :extension_follower do
    association :extension
    association :user
  end
end
