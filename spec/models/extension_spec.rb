require 'spec_helper'

describe Extension do
  describe "GitHub URL handling" do
    let(:extension) { create :extension }
    let(:account)   { extension.github_account }
    let(:token)     { account.oauth_token }
    let(:user)      { create :user }

    before do
      @e = Extension.new(github_url: "www.github.com/cvincent/test")
      @e.valid?
    end

    it "normalizes the URL before validation" do
      expect(@e.github_url).to eq("https://github.com/cvincent/test")
    end

    it "can return the username/repo formatted repo name from the URL" do
      expect(@e.github_repo).to eq("cvincent/test")
    end

    context 'with OAuth token' do
      let(:subject)   { extension.github_url_with_auth(user) }

      before do
        expect(token).to be_present
      end

      it 'injects the OAuth token into the URL' do
        extension.update(most_recent_valid_github_token: token)
        extension.reload
        expect(subject).to match /x-oauth-basic:#{token}/
      end
    end

    context 'without OAuth token' do
      let(:subject)     { extension.github_url_with_auth(user) }

      before do
        account.update_columns(oauth_token: nil)
        expect(token).to_not be_present
      end

      it 'injects the OAuth token into the URL' do
        expect(subject).to_not match /x-oauth-basic/
      end
    end
  end

  describe 'latest_version' do
    let(:extension) { create(:extension) }
    let(:version) { create(:extension_version, extension: extension) }

    it 'returns latest version' do
      version = extension.extension_versions.last.version
      expect(extension.latest_version.version).to eq(version)
    end

    it 'does not return pre-release versions' do
      version = extension.sorted_extension_versions.first.version
      master = create(:extension_version, extension: extension, version: 'master')
      pre_release = create(:extension_version, extension: extension)
      pre_release.update_column(:version, "#{pre_release.version}-pre")
      expect(extension.latest_version.version).to eq(version)
    end

    it 'returns pre-release version if no other' do
      master = extension.extension_versions.first.update_column(:version, 'master')
      pre_release = extension.extension_versions.second
      pre_release.update_column(:version, "#{pre_release.version}-pre")
      expect(extension.latest_version.version).to eq(pre_release.version)
    end

  end

  describe "sorted_extension_versions" do
    let(:extension) { create(:extension, extension_versions_count: 6) }
    let(:versions ) { extension.extension_versions }
    let(:sorted_versions) { extension.sorted_extension_versions }
    
    it 'returns sorted versions' do
      expect(sorted_versions.first.version).to be > sorted_versions.second.version
    end
    it 'sorts semvar versions with prerelease last' do
      versions[0].update(version: '0.0.1-1+jef.1')
      versions[1].update(version: '1.0.0-alpha+001')
      versions[2].update(version: '1.0.0-beta+exp.sha.5114f85')
      versions[3].update(version: '1.0.0+20130313144700')
      versions[4].update(version: 'master')
      version_5 = versions[5].version
      sorted_versions.reload
      puts sorted_versions.map(&:version) #{|v| v.version.gsub(/V|v|master|\+(.*)|-(.*)/, '')}
      expect(sorted_versions.first.version).to eq(version_5)
    end
  end

  describe ".in_namespace" do
    let(:owner_name) { "me"}

    it 'includes extensions having the given owner_name' do
      expect {
        create :extension, owner_name: owner_name
      }.to change{Extension.in_namespace(owner_name).count}.by(1)
    end

    it 'excludes extensions not having the given owner_name' do
      expect {
        create :extension
      }.not_to change{Extension.in_namespace(owner_name).count}
    end
  end

  describe '.for_architectures' do
    let(:arch)   { 'my-arch' }
    let(:arch2)  { 'other-arch' }
    let(:arch3)  { 'uninteresting-arch' }
    let(:viable) { true }
    let(:config) do
      {'builds' => [
        {"viable" => viable,
         "arch"   => arch},
        {"viable" => viable,
         "arch"   => arch2},
      ]}
    end

    context 'build is viable' do
      it 'includes versions with viable builds for the target architecture' do
        expect {
          create :extension_version, config: config
        }.to change{Extension.for_architectures([arch]).count}.by(1)

        expect {
          create :extension_version, config: config
        }.to change{Extension.for_architectures([arch2]).count}.by(1)
      end

      it 'does not double-count versions that have more than one matching architecture' do
        expect {
          create :extension_version, config: config
        }.to change{Extension.for_architectures([arch, arch2]).count}.by(1)
      end

      it 'ignores viable versions that do not have one of the target architectures' do
        expect {
          create :extension_version, config: config
        }.to_not change{Extension.for_architectures([arch3]).count}
      end
    end

    context 'build is not viable' do
      let(:viable) { false }

      it 'ignores versions that are not viable' do
        expect {
          create :extension_version, config: config
        }.to_not change{Extension.for_architectures([arch]).count}

        expect {
          create :extension_version, config: config
        }.to_not change{Extension.for_architectures([arch2]).count}
      end
    end
  end

  describe '.for_platforms' do
    let(:plat)   { 'my-plat' }
    let(:plat2)  { 'other-plat' }
    let(:plat3)  { 'uninteresting-plat' }
    let(:viable) { true }
    let(:config) do
      {'builds' => [
        {"viable"   => viable,
         "platform" => plat},
        {"viable"   => viable,
         "platform" => plat2},
      ]}
    end

    context 'build is viable' do
      it 'includes versions with viable builds for the target platform' do
        expect {
          create :extension_version, config: config
        }.to change{Extension.for_platforms([plat]).count}.by(1)

        expect {
          create :extension_version, config: config
        }.to change{Extension.for_platforms([plat2]).count}.by(1)
      end

      it 'does not double-count versions that have more than one matching platform' do
        expect {
          create :extension_version, config: config
        }.to change{Extension.for_platforms([plat, plat2]).count}.by(1)
      end

      it 'ignores viable versions that do not have one of the target platforms' do
        expect {
          create :extension_version, config: config
        }.to_not change{Extension.for_platforms([plat3]).count}
      end
    end

    context 'build is not viable' do
      let(:viable) { false }

      it 'ignores versions that are not viable' do
        expect {
          create :extension_version, config: config
        }.to_not change{Extension.for_platforms([plat]).count}

        expect {
          create :extension_version, config: config
        }.to_not change{Extension.for_platforms([plat2]).count}
      end
    end
  end

  describe '#hosted?' do
    it {expect(create(:extension, :hosted).hosted?).to be_truthy}
    it {expect(create(:extension         ).hosted?).to be_falsey}
  end

  describe '#name_with_namespace' do
    it {expect(create(:extension, name: 'my-extension', owner_name: 'my-org').name_with_namespace).to eq("my-org/my-extension")}
  end

  describe '#tier' do
    before do
      Tier.destroy_all
      create :tier, rank: 10
      create :tier, rank: 5    # The default Tier, since it has the lowest rank
    end

    context 'extension has a specific tier' do
      let(:other_tier)  { create :tier, rank: 20 }
      subject           { build_stubbed :extension, tier_id: other_tier.id}

      it 'returns the specific tier' do
        expect(subject.tier.rank).to eq 20
      end
    end

    context 'extension has no specific tier' do
      subject { build_stubbed :extension, tier_id: nil}

      it 'returns the default tier' do
        expect(subject.tier.rank).to eq 5
      end
    end
  end
end
