FactoryBot.define do

  factory :extension_version do
    association :extension, extension_versions_count: 0
    description { 'An awesome extension!' }
    license { 'MIT' }
    sequence(:version) { |n| "1.2.#{n}" }
    readme { '# redis extension' }
    readme_extension { 'md' }
    foodcritic_failure { false }
    last_commit_sha { SecureRandom.hex(10) }
    last_commit_at { DateTime.now }

    trait :with_source_file do
      after :create do |version, evaluator|
        version.source_file.attach(io: StringIO.new(''), filename: 'io')
      end
    end
  end

  factory :extension_version_with_config, class: ExtensionVersion, parent: :extension_version do
    config {
      { builds: [
        { arch: 'amd64',
          viable: true,
          platform: 'debian',
          asset_sha: '130e25a20533582729f69e8b8be60b0fc7f6ebdddcbc7c62faaaacd1f792dbf465277224f9b5e87bbbaaa815104350b193bfcc3cab0d12fb97a1253496d2883c',
          asset_url: 'https://github.com/jspaleta/sensu-plugins-influxdb/releases/download/1.4.1-pre/sensu-plugins-influxdb_1.4.1-pre_debian_linux_amd64.tar.gz',
          sha_filename: '#{repo}_#{version}_sha512-checksums.txt',
          base_filename: 'sensu-plugins-influxdb_1.4.1-pre_debian_linux_amd64.tar.gz',
          asset_filename: '#{repo}_#{version}_debian_linux_amd64.tar.gz',
        },
        { arch: 'amd64',
          viable: true,
          platform: 'centos',
          asset_sha: '2533e2511b76a2035e08b9c7f7a2b7922fcc4bce3c4882a2e0ac0ec56fc7c30b3b3a25a4e08c8038017122f5be8a54ab4ab1c960747ecf19a5868996993f7088',
          asset_url: 'https://github.com/jspaleta/sensu-plugins-influxdb/releases/download/1.4.1-pre/sensu-plugins-influxdb_1.4.1-pre_centos_linux_amd64.tar.gz',
          sha_filename: '#{repo}_#{version}_sha512-checksums.txt',
          base_filename: 'sensu-plugins-influxdb_1.4.1-pre_centos_linux_amd64.tar.gz',
          asset_filename: '#{repo}_#{version}_centos_linux_amd64.tar.gz'
        }
      ]}
    }
  end

end
