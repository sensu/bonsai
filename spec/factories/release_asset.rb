FactoryBot.define do
  factory :release_asset do
    association :extension_version
    platform { 'debian' }
    arch { 'amd64' }
    viable { true }
    commit_sha { '130e25a20533582729f69e8b8be60b0fc7f6ebdddcbc7' }
    trait :with_asset_file do
      after :create do |release_asset, evaluator|
        release_asset.asset_file.attach(io: StringIO.new(""), filename: 'io')
      end
    end
  end
end