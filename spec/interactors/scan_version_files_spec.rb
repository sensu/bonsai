require "spec_helper"

describe ScanVersionFiles do 

	let(:tag_name) { "0.0.1" }

	let(:extension) { create(:extension, github_url: "test/github_extension") }
	
	let(:version) { create(:extension_version, extension: extension, version: tag_name)}

	subject(:context) { 
		described_class.call(extension: extension, version: version)
	}

	let(:config_hash) { 
		{"builds"=>
	    [
	    	{"arch"=>"x86_64",
		      "filter"=> [
		      	"System.OS == linux",
		        "(System.Arch == x86_64) || (System.Arch == amd64)"
		      ],
		      "platform"=>"linux",
		      "sha_filename"=>"\#{repo}-\#{version}-linux-x86_64.sha512.txt",
		      "asset_filename"=>"\#{repo}-\#{version}-linux-x86_64.tar.gz"
	    	}
	    ],
	    "labels"=> {"example"=> "custom"},
	    "annotations"=> {"io.sensu.bonsai.test"=> "test value"},
	    "description"=>"test asset"
	    } 
	  }

	before do
    allow_any_instance_of(CmdAtPath).to receive(:cmd).with("find . -name '*.yml' -o -name '*.yaml'").
    	and_return("test/file1.yml\ntest/file2.yaml")
    allow_any_instance_of(CmdAtPath).to receive(:cmd).with("cat 'test/file1.yml'").
    	and_return({'MiqReport' => 'test'})
    allow_any_instance_of(CmdAtPath).to receive(:cmd).with("cat 'test/file2.yaml'").
    	and_return({'MiqAlert' => 'test'})
    allow_any_instance_of(CmdAtPath).to receive(:cmd).with("find . -name '*.class'").
    	and_return("test/file1.class")
    
    allow(CompileGithubExtensionVersionConfig).to receive(:call).and_return(
			double(Interactor::Context, success?: :success, config_hash: config_hash)
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
				expect(context.version).to eq(version)
			end

			it "saves data" do
				expect(context.version.config).to eq(config_hash)
				expect(version.extension_version_content_items.length).to eq(3)
			end

		end
	end

end