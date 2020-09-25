require "spec_helper"

describe CompileGithubOverrides do 

	let!(:version) { create :extension_version_with_config }

	let(:extension) { version.extension }

	let(:config_hash) { version.config }
  let(:tag_name) { [version.version] }

	subject(:context) { 
		described_class.call(extension: extension, version: version)
	}

  describe ".call" do 
		context 'when given the proper parameters' do 
			it "is properly formed and succeeds" do
				expect(described_class.include?(Interactor)).to be_truthy
				expect(context).to be_a_success 
			end
			
			it "provides the proper context" do 
				expect(context.extension).to eq(extension)
				expect(context.version).to eq(version)
			end

			it 'loads an alternate readme file' do
	      config_hash["overrides"] = [{
	        "readme_url"=>"https://raw.githubusercontent.com/sensu/bonsai/master/README.md"
	      }]
	      version.update_column(:config, config_hash)
	      expect(context).to be_a_success
	      version.reload
	      expect(version.readme).to include('bonsai.sensu.io')
	    end

	    it 'corrects link to github to load readme file as markdown' do
	      config_hash["overrides"] = [{
	        "readme_url"=>"https://github.com/sensu/bonsai/blob/master/README.md"
	      }]
	      version.update_column(:config, config_hash)
	      expect(context).to be_a_success
	      version.reload
	      expect(version.readme).to include('bonsai.sensu.io')
	    end

	    it 'loads an alternate readme file based on extension override' do
	      config_overrides = {
	        "readme_url"=>"https://raw.githubusercontent.com/sensu/bonsai/master/README.md"
	      }
	      extension.update_column(:config_overrides, config_overrides)
	      expect(context).to be_a_success
	      version.reload
	      expect(version.readme).to include('bonsai.sensu.io')
	    end

		end
	end

end