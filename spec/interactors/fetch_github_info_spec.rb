require "spec_helper"

describe FetchGithubInfo do

	let(:user) 								{ create(:user) }
	let(:extension)						{ create(:extension, github_url: "test/github-extension-handler" ) }

	let(:github)         			{ double(:github) }
	let(:top_level_contents)  { [{name: 'bonsai.yml'}] }

	before do
    allow(user).to receive(:octokit) { github }
    allow(github).to receive(:collaborator?).with("test/github-extension-handler", "some_user") { true }
    allow(github).to receive(:repo).with("test/github-extension-handler") { {} }
    allow(github).to receive(:contents).with("test/github-extension-handler") { top_level_contents }
  end

  subject(:context) { FetchGithubInfo.call(extension: extension, octokit: user.octokit, owner: user) }

	describe "call" do

		it "succeeds" do
      expect(context).to be_a_success
    end

	end

end
