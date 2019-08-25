require 'spec_helper'

describe Api::V1::ReleaseAssetsController do
  render_views

  describe 'GET #show' do
    let(:platform) { "debian" }
    let(:arch)     { "amd64" }

    context 'a regular extension' do
      let(:extension) { create :extension }
      let!(:version) { create :extension_version_with_config, extension: extension }

      before do
        extension.tags << Tag.new(name: 'label')
        version.config['builds'].each do |build|
          version.release_assets << build(:release_asset,
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

        get :show,
            params: {id:       version.extension.lowercase_name,
                     username: version.extension.owner_name,
                     version:  version,
                     platform: platform,
                     arch:     arch},
            format: :json
        @data = JSON.parse(response.body)
      end
 
      it 'succeeds' do
        expect(response).to be_successful
        expect(@data).to be_a(Hash)
      end

      it 'includes the major sections' do
        expect(@data['metadata']).to be_a(Hash)
        expect(@data['spec']).to be_a(Hash)
      end

      #it 'includes labels' do
      #  expect(@data['metadata']['labels']).to include('label')
      #end

      it 'includes common annotations' do 
        expect(@data['metadata']['annotations'].keys).to include('io.sensio.bonsai.url')
      end
    end

    context 'a hosted extension' do

      let(:extension) { create :extension, :hosted }
      let!(:version) { create :extension_version_with_config, extension: extension }

      before do
        extension.tags << Tag.new(name: 'label')
        version.config['builds'].each do |build|
          version.release_assets << build(:release_asset,
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

        get :show,
            params: {id:       version.extension.lowercase_name,
                     username: version.extension.owner_name,
                     version:  version,
                     platform: platform,
                     arch:     arch},
            format: :json
        @data = JSON.parse(response.body)
      end
    
      it 'succeeds' do
        expect(response).to be_successful
        expect(@data).to be_a(Hash)
      end

      it 'includes hosted annotation' do 
        expect(@data['metadata']['annotations'].keys).to include('io.sensio.bonsai.message')
      end
      
    end

  end # describe show
end
