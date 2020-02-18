require "spec_helper"

describe SyncExtensionContentsAtVersions do

	let(:octokit) { double(:octokit) }

	let(:tag_names) { ["0.0.1", "0.0.2"]}

	let(:extension) { build(:extension, github_url: "test/github_extension") }

  let(:version) { build(:extension_version, extension: extension, version: tag_names[0]) }

	let(:body) { "this is my body" }
  let(:release_infos_by_tag_name)  { {"0.0.1" => {"body" => body}, "0.0.2" => {"body" => body}} }

	#let(:asset_hash1)  { {name: "my_repo-1.2.2-linux-x86_64.tar.gz",
                        #browser_download_url: "https://example.com/download"} }
  #let(:asset_hash2)  { {name: "my_repo-1.2.2-linux-x86_64.sha512.txt",
                        #browser_download_url: "https://example.com/sha_download"} }
  #let(:release_infos_by_tag_name) { {tag_name: version.version, assets: [asset_hash1, asset_hash2]} }

  let(:compatible_platforms) { ["1", "2"] }

	subject(:context) { 
		described_class.call(extension: extension, tag_names: tag_names, compatible_platforms: compatible_platforms, release_infos_by_tag_name: release_infos_by_tag_name
		)
	}

	before do
    
    allow(extension).to receive(:update_column).with(:compilation_error, '') {true}

    allow(version).to receive(:supported_platform_ids=) {true}
    allow(version).to receive(:update_column).with(:commit_count, 0) {true}
    allow(version).to receive(:update_column).with(:release_notes, "this is my body") {true}

    allow_any_instance_of(CmdAtPath).to receive(:cmd).and_return("")

    allow(FetchReadmeAtVersion).to receive(:call).and_return(
			double(Interactor::Context, success?: :success, body: '** Readme Body **', file_extension: 'md')
  	)
  	allow(EnsureUpdatedVersion).to receive(:call).and_return(
			double(Interactor::Context, success?: :success, version: version)
  	)
  	allow(ScanVersionFiles).to receive(:call).and_return(
			double(Interactor::Context, success?: :success)
  	)
  	allow(CompileGithubOverrides).to receive(:call).and_return(
			double(Interactor::Context, success?: :success)
  	)
  	allow(PersistAssets).to receive(:call).and_return(
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
				expect(context.tag_names).to eq(tag_names)
				expect(context.compatible_platforms).to eq(compatible_platforms)
			end

			it "updates data fields" do
				expect(version).to receive(:supported_platform_ids=)
    		expect(version).to receive(:update_column).with(:commit_count, 0) 
    		expect(version).to receive(:update_column).with(:release_notes, "this is my body")
				expect(FetchReadmeAtVersion).to receive(:call)
				expect(context).to be_a_success
			end

			it "calls other Interactors" do
				expect(FetchReadmeAtVersion).to receive(:call)
				expect(EnsureUpdatedVersion).to receive(:call)
  			expect(ScanVersionFiles).to receive(:call)
  			expect(CompileGithubOverrides).to receive(:call)
  			expect(PersistAssets).to receive(:call)
				expect(context).to be_a_success
			end 

		end
	end

end