require 'spec_helper'

describe ReleaseAsset do
  
  let(:version)   { create :extension_version_with_config }
  let(:extension) { version.extension }
 

  describe '.annotations' do
    
    before do 
      version.config['builds'].each do |build|
        version.release_assets << build(:release_asset,
          platform: build['platform'],
          arch: build['arch'],
          viable: build['viable'],
          github_asset_sha: build['asset_sha'],
          github_asset_url: build['asset_url'],
          github_sha_filename: build['sha_filename'],
          github_base_filename: build['base_filename'],
          github_asset_filename: build['asset_filename']
        )
      end
    end

    context 'a hosted extension' do
      before do
        extension.update_column(:github_url, nil)
        extension.reload
      end
      
      let(:asset) {version.release_assets.first}

      it 'includes a licensing message' do
        expect( asset.annotations.to_json).to match /license/i
      end
    end

    context 'a github extension' do
      
      let(:asset) {version.release_assets.first}

      it 'includes a licensing message' do
        expect( asset.annotations.to_json).not_to match /license/i
      end
    end

  end
end
