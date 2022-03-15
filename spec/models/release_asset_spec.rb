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

  describe '#asset_url' do
    let(:vanity_url)       { nil }
    let(:source_asset_url) { nil }
    subject                { build :release_asset, vanity_url: vanity_url, source_asset_url: source_asset_url}

    context 'no vanity url' do
      context 'no source asset url' do
        it { expect(subject.asset_url).to be_blank }
      end

      context 'with source asset url' do
        let(:source_asset_url) { 'some-url' }

        before do
          expect(source_asset_url).to be_present
        end

        it { expect(subject.asset_url).to eq source_asset_url }
      end
    end

    context 'with vanity url' do
      let(:vanity_url) { 'some-vanity-url' }

      before do
        expect(vanity_url).to be_present
      end

      context 'no source asset url' do
        it { expect(subject.asset_url).to eq vanity_url }
      end

      context 'with source asset url' do
        let(:source_asset_url) { 'some-url' }

        before do
          expect(source_asset_url).to be_present
        end

        it { expect(subject.asset_url).to eq vanity_url }
      end
    end
  end
end
