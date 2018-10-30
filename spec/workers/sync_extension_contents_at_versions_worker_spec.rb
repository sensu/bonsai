require 'spec_helper'

describe SyncExtensionContentsAtVersionsWorker do
  before do
    Account.destroy_all
  end

  let!(:extension) { create :extension }
  subject          { SyncExtensionContentsAtVersionsWorker.new }

  before do
    FileUtils.mkdir_p extension.repo_path
    allow_any_instance_of(CmdAtPath).to receive(:cmd) { "" }
  end

  describe 'tag checking' do
    it 'honors semver tags' do
      tags = ["0.01"]   # is semver-conformant

      expect {
        subject.perform(extension.id, tags)
      }.to change{ExtensionVersion.count}.by 1
    end

    it 'ignores non-semver tags' do
      tags = ["v0.1A20180919"]  # is not semver-conformant

      expect {
        subject.perform(extension.id, tags)
      }.not_to change{ExtensionVersion.count}
    end
  end

  describe 'release note extraction' do
    let(:body)                  { "this is my body" }
    let(:release_infos_by_tag)  { {"0.33" => {"body" => body}} }
    let(:tags)                  { release_infos_by_tag.keys }

    it 'puts the release notes into the release notes field' do
      subject.perform(extension.id, tags, [], release_infos_by_tag)
      expect(extension.reload.extension_versions.last.release_notes).to eq body
    end
  end
end
