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
end
