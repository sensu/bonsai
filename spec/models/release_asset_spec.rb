require 'spec_helper'

describe ReleaseAsset do
  
  let(:extension) { create :extension, :hosted}
  let(:version)   { create :extension_version_with_config, extension: extension }
  
  describe '.annotations' do
    
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

    context 'a hosted extension' do
      
      let(:asset) {version.release_assets.first}

      it 'includes a licensing message' do
        expect( asset.annotations.keys ).to include('bonsai.sensu.io.message')
      end
    end
  end

end
