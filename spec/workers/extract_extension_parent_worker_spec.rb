require "spec_helper"

describe ExtractExtensionParentWorker do

  let(:parent_name ) {"sensu-plugins-http"}
  let(:parent_owner_name) {"sensu-plugins"}

  let(:parent_extension) { create :extension }

  let(:name) {"sensu-plugins-http"}
  let(:owner_name) {"jspaleta"}

  let(:extension) { create :extension }

  subject { ExtractExtensionParentWorker.new }

  before do
    allow(subject).to receive_message_chain(:octokit, :repo).and_return(repo_json)
    # factory seems to override lowercase_name
    parent_extension.update(
      name: parent_name, 
      lowercase_name: parent_name, 
      owner_name: parent_owner_name
    )
    extension.update(
      name: name, 
      lowercase_name: name, 
      owner_name: owner_name
    )
  end

  it "updates the extension with the parent if one is present" do
    subject.perform( extension.id )
    extension.reload
    expect( extension.parent_id ).to eq( parent_extension.id )
    expect( extension.parent_name ).to eq( parent_name )
    expect( extension.parent_owner_name ).to eq( parent_owner_name )
  end

end

def repo_json
  {
    "id": 159426531,
    "node_id": "MDEwOlJlcG9zaXRvcnkxNTk0MjY1MzE=",
    "name": "sensu-plugins-http",
    "full_name": "jspaleta/sensu-plugins-http",
    "owner": {
      "login": "jspaleta",
      "id": 39937,
    },
    "html_url": "https://github.com/jspaleta/sensu-plugins-http",
    "description": "This plugin provides native HTTP instrumentation for monitoring and metrics collection, including: response code, JSON response, HTTP last modified, SSL expiry, and metrics via `curl`.",
    "forks": 0,
    "open_issues": 0,
    "watchers": 0,
    "default_branch": "master",
    "parent": {
      "id": 30851315,
      "node_id": "MDEwOlJlcG9zaXRvcnkzMDg1MTMxNQ==",
      "name": "sensu-plugins-http",
      "full_name": "sensu-plugins/sensu-plugins-http",
      "private": false,
      "owner": {
        "login": "sensu-plugins",
        "id": 10713628,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjEwNzEzNjI4",
      },
    },
  }
end