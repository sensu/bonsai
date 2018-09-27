require "spec_helper"

describe CreateExtension do
  let(:params) { {
    name:                 "asdf",
    description:          "desc",
    github_url:           "cvincent/test",
    tag_tokens:           "tag1, tag2",
    compatible_platforms: ["", "p1", "p2"],
  } }
  let(:github)         { double(:github) }
  let(:user)           { create(:user, username: 'some_user') }
  let(:github_account) { user.github_account }
  let(:extension)      { build :extension, owner: user }

  subject { CreateExtension.new(params, user) }
  let(:normalized_attributes) { {
    'github_url'     => "https://github.com/cvincent/test",
    'lowercase_name' => "asdf",
  } }
  let(:expected_unnormalized_attributes) { Extension.new(params.merge(owner: user)).attributes }
  let(:expected_normalized_attributes)   { Extension.new(params.merge(owner: user)).attributes.merge(normalized_attributes) }

  before do
    allow(user).to receive(:octokit) { github }
    allow(github).to receive(:collaborator?).with("cvincent/test", "some_user") { true }
    allow(github).to receive(:repo).with("cvincent/test") { {} }
    allow(CollectExtensionMetadataWorker).to receive(:perform_async)
    allow(SetupExtensionWebHooksWorker).to receive(:perform_async)
    allow(NotifyModeratorsOfNewExtensionWorker).to receive(:perform_async)
  end

  it "saves a valid extension, returning the extension" do
    result = subject.process!
    expect(result).to be_kind_of(Extension)
    expect(result).to be_persisted
  end

  it "adds tags" do
    e = subject.process!
    expect(e.tags.size).to eq(2)
    expect(e.tag_tokens).to eq('tag1, tag2')
  end

  it "kicks off a worker to gather metadata about the valid extension" do
    expect(CollectExtensionMetadataWorker).to receive(:perform_async)
    expect(subject.process!).to be_persisted
  end

  it "kicks off a worker to set up the repo's web hook for updates" do
    expect(SetupExtensionWebHooksWorker).to receive(:perform_async)
    expect(subject.process!).to be_persisted
  end

  it "kicks off a worker to notify operators" do
    expect(NotifyModeratorsOfNewExtensionWorker).to receive(:perform_async)
    expect(subject.process!).to be_persisted
  end

  it "does not save an invalid extension, returning the extension" do
    allow_any_instance_of(Extension).to receive(:valid?) { false }
    expect_any_instance_of(Extension).not_to receive(:save)
    expect(subject.process!.attributes).to eq(expected_unnormalized_attributes)
  end

  it "does not check the repo collaborators if the extension is invalid" do
    allow_any_instance_of(Extension).to receive(:valid?) { false }
    expect(github).not_to receive(:collaborator?)
    expect(subject.process!.attributes).to eq(expected_unnormalized_attributes)
  end

  it "does not save and adds an error if the user is not a collaborator in the repo" do
    allow(github).to receive(:collaborator?).with("cvincent/test", "some_user") { false }
    expect_any_instance_of(Extension).not_to receive(:save)
    result = subject.process!
    expect(result.attributes).to eq(expected_normalized_attributes)
    expect(result.errors[:github_url]).to include(I18n.t("extension.github_url_format_error"))
  end

  it "does not save and adds an error if the repo is invalid" do
    allow(github).to receive(:collaborator?).with("cvincent/test", "some_user").and_raise(ArgumentError)
    expect_any_instance_of(Extension).not_to receive(:save)
    result = subject.process!
    expect(result.attributes).to eq(expected_normalized_attributes)
    expect(result.errors[:github_url]).to include(I18n.t("extension.github_url_format_error"))
  end
end
