require "spec_helper"

describe ExtractExtensionLicense do

	let(:octokit) { double(:octokit) }

  let(:extension) { double(:extension, github_repo: "test/github_extension", octokit: octokit) }

	subject(:context) { described_class.call(extension: extension)}

	before do
    allow(octokit).to receive(:repo).with("test/github_extension", accept: "application/vnd.github.drax-preview+json") do
      { license: { key: "mit" } }
    end
    allow(octokit).to receive(:license).with("mit", accept: "application/vnd.github.drax-preview+json") do
      { name: "MIT", body: "License language" }
    end
    allow(extension).to receive(:update_columns).with(license_name: "MIT", license_text: "License language")
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

			it "updates extension fields" do
				expect(extension).to receive(:update_columns)
				expect(context).to be_a_success
			end 
		end
	end

end