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
      { annotations: {
          suggested_asset_url: '/suggested/asset',
          suggested_asset_message: 'Suggested Asset Message'
        },
        builds: [
        { arch: 'amd64',
          viable: true,
          filter: [
            "entity.system.os == 'linux'",
            "entity.system.arch == 'amd64'",
            "entity.system.platform == 'debian'"
          ],
          platform: 'debian',
          asset_sha: '130e25a20533582729f69e8b8be60b0fc7f6ebdddcbc7c62faaaacd1f792dbf465277224f9b5e87bbbaaa815104350b193bfcc3cab0d12fb97a1253496d2883c',
          asset_url: 'https://github.com/jspaleta/sensu-plugins-influxdb/releases/download/1.4.1-pre/sensu-plugins-influxdb_1.4.1-pre_debian_linux_amd64.tar.gz',
          sha_filename: '#{repo}_#{version}_sha512-checksums.txt',
          base_filename: 'sensu-plugins-influxdb_1.4.1-pre_debian_linux_amd64.tar.gz',
          asset_filename: '#{repo}_#{version}_debian_linux_amd64.tar.gz',
        },
        { arch: 'amd64',
          viable: true,
          filter: [
            "entity.system.os == 'linux'",
            "entity.system.arch == 'amd64'",
            "entity.system.platform == 'centos'"
          ],
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

  factory :extension_version_with_hosted_config, class: ExtensionVersion, parent: :extension_version do
    config {
      { builds: [
        { arch: 'amd64',
          viable: true,
          filter: [
            "entity.system.os == 'linux'",
            "entity.system.arch == 'amd64'",
          ],
          platform: 'linux',
          asset_sha: 'a7d4fa585758289ba0aaacd768426e6e80063d8a026f5a7f6fed9a9981baf6e8af32d5b9101bea22810b7965f7e2348b65bcdc28cc5b9087e4e7a51a5fd7561c',
          asset_url: 'https://bonsai.sensu.io/release_assets/sensu/sensu-relay-handler/0.0.7/linux/amd64/asset_file',
          sha_filename: '#{repo}_#{version}_sha512-checksums.txt',
          base_filename: 'sensu-relay-handler_0.0.7_linux_amd64.tar.gz',
          asset_filename: '#{repo}_#{version}_linux_amd64.tar.gz',
        },
        { arch: '386',
          viable: true,
          filter: [
            "entity.system.os == 'linux'",
            "entity.system.arch == '386'",
          ],
          platform: 'linux',
          asset_sha: '27c5da943d2ffc9da28d25f189e6cd950fc7466746e53b8e9b4458142bbdb2d3b1e2868a5d868f58387176a260d52f8547ff1d50bec7a473eb0dfa454d2c7037',
          asset_url: 'https://bonsai.sensu.io/release_assets/sensu/sensu-relay-handler/0.0.7/linux/386/asset_file',
          sha_filename: '#{repo}_#{version}_sha512-checksums.txt',
          base_filename: 'sensu-relay-handler_0.0.7_linux_386.tar.gz',
          asset_filename: '#{repo}_#{version}_linux_386.tar.gz'
        }
      ]}
    }
  end
end
