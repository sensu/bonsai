FactoryBot.define do
  factory :extension do
    association :category
    association :owner, factory: :user
    sequence(:name) { |n| "redis-#{n}" }
    sequence(:owner_name) { |n| "owner#{n}" }
    source_url { 'http://example.com' }
    issues_url { 'http://example.com/issues' }
    deprecated { false }
    featured { false }
    github_url { "https://github.com/tester/testing" }

    transient do
      extension_versions_count { 2 }
    end

    before(:create) do |extension, evaluator|
      extension.extension_versions << create_list(:extension_version, evaluator.extension_versions_count, extension: nil)
    end
  end
end
