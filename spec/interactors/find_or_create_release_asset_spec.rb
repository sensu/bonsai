require "spec_helper"

describe FindOrCreateReleaseAsset do

	describe ".call" do

		context "when valid version and build" do
			let(:version) { create(:extension_version_with_config ) }
			let(:build) { version.config['builds'][0] }
			subject(:context) {FindOrCreateReleaseAsset.call(version: version, build: build)}

			it "succeeds" do 
				expect(context).to be_a_success
			end

			it "creates a release asset" do
				version.reload
				expect(context.release_asset.extension_version_id).to eq(version.id)
			end

			it "finds a release asset" do
				result = FindOrCreateReleaseAsset.call(version: version, build: build)
				expect(result.release_asset.id).to eq(context.release_asset.id)
			end
		end # context

		context "when invalid version or build" do
			let(:version) { create(:extension_version_with_config ) }
			let(:build) { {} }
			subject(:context) {FindOrCreateReleaseAsset.call(version: version, build: build)}

			it "succeeds" do 
				expect(context).to_not be_a_success
			end

			it "returns an error" do
				expect(context.error).not_to be_empty
			end
		end
	
	end

end