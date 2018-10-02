require 'spec_helper'

describe SyncExtensionContentsAtVersionsWorker do
  let!(:extension) { create :extension }

  describe 'tag checking' do
    subject { SyncExtensionContentsAtVersionsWorker.new }

    before do
      FileUtils.mkdir_p extension.repo_path
      allow_any_instance_of(CmdAtPath).to receive(:cmd) { "" }
    end

    it 'honors semver tags' do
      tags = ["0.01"]   # is semver-conformant

      expect {
        subject.perform(extension.id, tags)
      }.to change{ExtensionVersion.count}.by 1
    end

    it 'ignores non-semver tags' do
      tags = ["v0.1-20180919"]  # is not semver-conformant

      expect {
        subject.perform(extension.id, tags)
      }.not_to change{ExtensionVersion.count}
    end
  end
end
