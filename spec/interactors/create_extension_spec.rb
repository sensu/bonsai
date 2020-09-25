require "spec_helper"

describe CreateExtension do

  let(:params) { {
  	name: 'github_extension', 
  	description: 'test description', 
  	github_url: 'test/github_url', 
  	github_url_short: 'test/github_url', 
  	tmp_source_file: nil, 
  	tag_tokens: "tag1, tag2",
  	version: '0.0.1', 
  	compatible_platforms: ["", "platform-1", "platform-2"]
  } }

  let(:extension) { create(:extension, params) }

  let(:user) { create(:user) }

	subject(:context) { 
		described_class.call(candidate: extension, params: params, user: user)
	}

	before do
    allow(FetchGithubInfo).to receive(:call).and_return(
			double(Interactor::Context, success?: :success, github_organization: nil, owner_name: user.username)
  	)
  	allow(ValidateNewExtension).to receive(:call).and_return(
			double(Interactor::Context, success?: :success, extension: extension)
  	)
  end

	describe ".call" do 
		context 'when given the proper parameters' do 
			it "is properly formed and succeeds" do
				expect(described_class.include?(Interactor)).to be_truthy
				expect(context).to be_a_success 
			end
			
			it "provides the proper context" do 
				expect(context.params).to eq(params)
				expect(context.user).to eq(user)
			end

			it "updates extension fields" do
				expect(FetchGithubInfo).to receive(:call)
				expect(ValidateNewExtension).to receive(:call)
				expect(context.extension).to eq(extension)
			end 
		end
	end

end