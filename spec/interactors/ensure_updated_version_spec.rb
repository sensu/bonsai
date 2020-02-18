require "spec_helper"

describe EnsureUpdatedVersion do 

	let(:tag_name) { "0.0.1" }

	let(:extension) { create(:extension, github_url: "test/github_extension") }
	
	let(:body) { "*** Read me body ***" }
	let(:file_extension) { 'md' }

	subject(:context) { 
		described_class.call(extension: extension, tag_name: tag_name, readme_body: body, readme_ext: file_extension)
	}

	before do
    allow_any_instance_of(CmdAtPath).to receive(:cmd).and_return(" 2 ")
  end

  describe ".call" do 
		context 'when given the proper parameters' do 
			it "is properly formed and succeeds" do
				expect(described_class.include?(Interactor)).to be_truthy
				expect(context).to be_a_success 
			end
			
			it "provides the proper context" do 
				expect(context.readme_body).to eq(body)
				expect(context.readme_ext).to eq(file_extension)
			end

			it "creates version and saves data" do
				expect_any_instance_of(ExtensionVersion).to receive(:update_columns)
				expect(context).to be_a_success
				expect(context.version).to be_instance_of(ExtensionVersion)
				expect(context.version.version).to eq(tag_name)
			end

			it "finds version and saves data" do
				create(:extension_version, extension: extension, version: tag_name)
				expect(context).to be_a_success
				expect(context.version).to be_instance_of(ExtensionVersion)
				expect(context.version.version).to eq(tag_name)
				expect(context.version.readme).to eq(body)
			end

		end
	end

end