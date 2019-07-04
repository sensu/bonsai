require 'spec_helper'

describe ReleaseAsset do
  
  let(:extension) { create :extension, :hosted}
  let(:version)   { create :extension_version_with_config, extension: extension }
  
  before do
    version.config['builds'].each do |build|
      version.release_assets << create(:release_asset,
        platform: build['platform'],
        arch: build['arch'],
        viable: build['viable'],
        source_asset_sha: build['asset_sha'],
        source_asset_url: build['asset_url'],
        source_sha_filename: build['sha_filename'],
        source_base_filename: build['base_filename'],
        source_asset_filename: build['asset_filename']
      )
    end
  end
  
  describe 'attributes' do
    let(:asset) {version.release_assets.first}
    context 'a hosted extension' do
      it 'responds to attribute methods' do
        expect(asset.destination_pathname).to include(asset.source_asset_filename)
        expect(asset.viable?).to be_truthy
        expect(asset.labels).to eq([])
      end
    end
  end

end
