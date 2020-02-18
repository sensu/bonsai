require "spec_helper"

describe SyncExtensionRepo do

	let(:octokit) { double(:octokit) }

  let(:extension) { build(:extension, github_url: "test/github_extension") }

  let(:compatible_platforms) { ["1", "2"] }

  let(:system) { double(:system) }

	subject(:context) { 
		described_class.call(extension: extension, compatible_platforms: compatible_platforms)
	}

	before do
    allow(extension).to receive_message_chain("octokit.releases").with(extension.github_repo) do
      [{ id: 1, tag_name: '1.0.0' }, { id: 2, tag_name: '2.0.0'}]
    end
    allow(extension).to receive(:update_column).with(:compilation_error, '') {true}

    allow_any_instance_of(described_class).to receive(:system).and_return(true)

    allow(SyncExtensionContentsAtVersions).to receive(:call).and_return(
			double(Interactor::Context, success?: :success)
  	)
  end

	describe ".call" do 
		context 'when given the proper parameters' do 
			it "is properly formed and succeeds" do
				expect(described_class.include?(Interactor)).to be_truthy
				expect(context).to be_a_success 
			end
			
			it "provides the proper context" do 
				expect(context.extension).to eq(extension)
				expect(context.compatible_platforms).to eq(compatible_platforms)
			end

			it "updates extension fields" do
				expect(SyncExtensionContentsAtVersions).to receive(:call)
				expect(context).to be_a_success
			end 
		end
	end

end