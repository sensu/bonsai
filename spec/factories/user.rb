FactoryBot.define do
  factory :user do
    first_name { 'John' }
    last_name { 'Doe' }
    public_key { File.read('spec/support/key_fixtures/valid_public_key.pub') }

    sequence(:email) { |n| "johndoe#{n}@example.com" }

    transient do
      create_chef_account { true }
      sequence(:username) { |n| "github_account#{n}" }
    end

    after(:create) do |user, evaluator|
      if evaluator.create_chef_account
        create(:account, provider: 'github', user: user, username: evaluator.username)
      end
    end

    factory :admin, class: User do
      first_name { 'Admin' }
      last_name { 'User' }
      roles_mask { 1 }
    end
  end
end
