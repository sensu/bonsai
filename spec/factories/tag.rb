FactoryBot.define do

  factory :tag do
    sequence(:name) { |n| "name-#{n}" }
  end

end