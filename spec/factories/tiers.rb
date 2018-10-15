FactoryBot.define do
  factory :tier do
    sequence(:name)      {|n| "tier#{n}"}
    sequence(:rank)      {|n| n}
    sequence(:icon_name) {|n| "icon_name#{n}"}
  end
end
