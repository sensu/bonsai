require "spec_helper"

describe FetchReadmeAtVersion do 

	let(:tag_name) { "0.0.1" }

	let(:extension) { build(:extension, github_url: "test/github_extension") }

	let(:body) { "*** Read me body ***" }

	subject(:context) { 
		described_class.call(extension: extension, tag_name: tag_name)
	}

	before do
    allow_any_instance_of(CmdAtPath).to receive(:cmd).with("ls README*").and_return("readme.md")
    allow_any_instance_of(CmdAtPath).to receive(:cmd).with("cat 'readme.md'").and_return(body)
  end

  describe ".call" do 
		context 'when given the proper parameters' do 
			it "is properly formed and succeeds" do
				expect(described_class.include?(Interactor)).to be_truthy
				expect(context).to be_a_success 
			end
			
			it "provides the proper context" do 
				expect(context.body).to eq(body)
				expect(context.file_extension).to eq('md')
			end

			it "provides the proper error if no readme" do
				allow_any_instance_of(CmdAtPath).to receive(:cmd).with("ls README*").and_return(nil)
				expect(context.error).to include(tag_name)
			end
		end
	end

end