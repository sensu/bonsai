require "spec_helper"

describe ExtractExtensionStargazers do

	let(:octokit) { double(:octokit) }

  let(:extension) { build(:extension, github_url: "test/github_extension") }

	subject(:context) { described_class.call(extension: extension)}

	let(:stargazers) do
    [
      { login: "test1" },
      { login: "test2" },
      { login: "test3" }
    ]
  end

  let(:account) { build(:account) }

	before do
		allow_any_instance_of(Extension).to receive(:octokit).and_return(octokit)

		allow(extension.extension_followers).to receive(:create).and_return(true)

		allow(EnsureGithubUserAndAccount).to receive(:call).and_return(
			double(Interactor::Context, account: account)
  	)
		
		allow(octokit).to receive(:stargazers).with(extension.github_repo, page: 1, per_page: 100).and_return(stargazers)
		allow(octokit).to receive(:stargazers).with(extension.github_repo, page: 2, per_page: 100).and_return([])
    allow(octokit).to receive(:user).with('test1') do 
    	{ id: 1, login: 'test1', name: 'John H. Doe', email: 'johndoe1@example.com'}
    end
    allow(octokit).to receive(:user).with('test2') do 
    	{ id: 1, login: 'test2', name: 'Jane G. Doe', email: 'johndoe2@example.com'}
    end
    allow(octokit).to receive(:user).with('test3') do 
    	{ id: 1, login: 'test3', name: 'Junior O. Doe', email: 'johndoe3@example.com'}
    end
    
  end

	describe ".call" do 
		context 'when given the proper parameters' do 
			it "is properly formed and succeeds" do
				expect(described_class.include?(Interactor)).to be_truthy
				expect(context).to be_a_success 
			end
			
			it "provides the proper context" do 
				expect(context.extension).to eq(extension)
			end

			it "creates accounts and users" do
				expect(EnsureGithubUserAndAccount).to receive(:call)
				expect(extension.extension_followers).to receive(:create)
				expect(context).to be_a_success
			end 
		end
	end

end