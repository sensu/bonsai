require "spec_helper"

describe ExtractExtensionCollaborators do

	let(:octokit) { double(:octokit) }

  let(:extension) { build(:extension, github_url: "test/github_extension") }

	subject(:context) { described_class.call(extension: extension)}

	let(:contributors) do
    [
      { login: "test1", contributions: 1 },
      { login: "test2", contributions: 0 },
      { login: "test3", contributions: 99 }
    ]
  end

  let(:account) { build(:account) }

	before do
		allow_any_instance_of(Extension).to receive(:octokit).and_return(octokit)

		allow(EnsureGithubUserAndAccount).to receive(:call).and_return(
			double(Interactor::Context, account: account)
  	)
		
		allow(octokit).to receive(:contributors).with(extension.github_repo, nil, page: 1).and_return(contributors)
		allow(octokit).to receive(:contributors).with(extension.github_repo, nil, page: 2).and_return([])
    allow(octokit).to receive(:collaborators).with(extension.github_repo, page: 1).and_return(contributors)
    allow(octokit).to receive(:collaborators).with(extension.github_repo, page: 2).and_return([])
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
				expect(context).to be_a_success
			end 
		end
	end

end