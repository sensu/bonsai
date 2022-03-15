require "spec_helper"

describe SetUpGithubExtension do
  before do
    allow(user).to receive(:octokit) { github }
    allow(github).to receive(:repo) { {} }
  end

  let(:repo_info)   { {organization: {id:         1,
                                      login:      'my-org',
                                      avatar_url: 'https://avatar.com'}} }
  let(:github)      { double(:github) }
  let(:user)        { create(:user) }
  let(:octokit)     { user.octokit }
  let(:extension)   { build :extension }
  let(:platforms)   { ["", "p1", "p2"] }
  subject(:context) { SetUpGithubExtension.call(extension:            extension,
                                                octokit:              octokit,
                                                compatible_platforms: platforms) }

  before do
    allow(github).to receive(:repo) { repo_info }
    allow(user).to receive(:octokit) { github }
  end

  describe '.call' do

    it "kicks off a worker to gather metadata about the valid extension" do
      expect(CollectExtensionMetadataWorker).to receive(:perform_async)
      expect(context).to be_a_success
    end

    unless ROLLOUT.active?(:no_webhook)
      it "kicks off a worker to set up the repo's web hook for updates" do
        expect(SetupExtensionWebHooksWorker).to receive(:perform_async)
        expect(context).to be_a_success
      end
    end

    it "kicks off a worker to notify operators" do
      expect(NotifyModeratorsOfNewExtensionWorker).to receive(:perform_async)
      expect(context).to be_a_success
    end
  end
end
