require "spec_helper"

describe CompileGithubExtensionVersionConfig do
  let(:version_name) { "1.2.2"}
  let(:repo_name)    { "my_repo" }
  let(:config)       { {"builds"=>
                          [{"arch"=>"x86_64",
                            "filter"=>
                              ["System.OS == linux",
                               "(System.Arch == x86_64) || (System.Arch == amd64)"],
                            "platform"=>"linux",
                            "sha_filename"=>"\#{repo}-\#{version}-linux-x86_64.sha512.txt",
                            "asset_filename"=>"\#{repo}-\#{version}-linux-x86_64.tar.gz"}],
                        "labels"=> {"example"=> "custom"},
                        "annotations"=> {"io.sensu.bonsai.test"=> "test value"},
                        "description"=>"test asset"
                     } }
  let(:extension)    { create :extension, extension_versions_count: 0, github_url: "https://github.com/owner/#{repo_name}" }
  let(:version)      { create :extension_version, extension: extension, config: config, version: version_name }
  let(:cmd_runner)   { double("command runner", :cmd => config.to_yaml) }
  subject(:context)  { CompileGithubExtensionVersionConfig.call(version: version, system_command_runner: cmd_runner) }

  describe ".call" do
    let(:asset_hash1)        { {name: "my_repo-1.2.2-linux-x86_64.tar.gz",
                                url: "https://example.com/download"} }
    let(:asset_hash2)        { {name: "my_repo-1.2.2-linux-x86_64.sha512.txt",
                                url: "https://example.com/sha_download"} }
    let(:release_data)       { {tag_name: version.version, assets: [asset_hash1, asset_hash2]} }
    let(:expected_data_hash) { {"annotations"=>
                                  {"io.sensu.bonsai.test"=>"test value"},
                                "builds" =>
                                  [{"arch"           => "x86_64",
                                    "filter"         =>
                                      ["System.OS == linux",
                                       "(System.Arch == x86_64) || (System.Arch == amd64)"],
                                    "platform"       => "linux",
                                    "sha_filename"   => "\#{repo}-\#{version}-linux-x86_64.sha512.txt",
                                    "asset_filename" => "\#{repo}-\#{version}-linux-x86_64.tar.gz",
                                    "viable"         => true,
                                    "asset_url"      => "https://example.com/download",
                                    "base_filename"  => "my_repo-1.2.2-linux-x86_64.tar.gz",
                                    "asset_sha"      => "c1ec2f493f0ff9d83914c1ec2f493f0ff9d83914"}],
                                  "description" => "test asset",
                                  "labels" => {"example"=>"custom"}
                              } }

    before do

      allow_any_instance_of(Octokit::Client).to receive(:releases) { [release_data] }
      allow_any_instance_of(Faraday::Connection).to receive(:get) { Faraday.new }
      allow_any_instance_of(Faraday::Connection).to receive(:success?) { true }
      allow_any_instance_of(Faraday::Connection).to receive(:body)     { "c1ec2f493f0ff9d83914c1ec2f493f0ff9d83914" }

    end

    it "succeeds" do
      expect(context).to be_a_success
    end

    it "complies the configuration" do
      # not sure this is relevant anymore
      expect(context.data_hash).to eql(expected_data_hash)
    end
  end
end
