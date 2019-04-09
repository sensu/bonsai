require "spec_helper"

describe CreateExtension do
  let(:github_url)  { "cvincent/test" }
  let(:signed_id)   { nil }
  let(:version)     { nil }
  let(:params) { {
    name:                 "asdf",
    description:          "desc",
    github_url:           github_url,
    tag_tokens:           "tag1, tag2",
    compatible_platforms: ["", "p1", "p2"],
    tmp_source_file:      signed_id,
    version:              version,
  } }
  let(:github)         { double(:github) }
  let(:user)           { create(:user, username: 'some_user') }
  let(:github_account) { user.github_account }
  let(:extension)      { build :extension, owner: user }

  subject { CreateExtension.new(params, user) }
  let(:normalized_attributes) { {
    'github_url'     => "https://github.com/#{github_url}",
    'lowercase_name' => "test",
  } }
  let(:expected_unnormalized_attributes) { Extension.new(params.merge(owner: user, owner_name: 'some_user')).attributes }
  let(:expected_normalized_attributes)   { Extension.new(params.merge(owner: user, owner_name: 'some_user')).attributes.merge(normalized_attributes) }
  let(:top_level_contents)               { [{name: 'bonsai.yml'}] }

  before do
    allow(user).to receive(:octokit) { github }
    allow(github).to receive(:collaborator?).with("cvincent/test", "some_user") { true }
    allow(github).to receive(:repo).with("cvincent/test") { {} }
    allow(github).to receive(:contents).with("cvincent/test") { top_level_contents }
    allow(SetUpGithubExtension).to receive(:call)
  end

  after do
    # Purge ActiveStorage::Blob files.
    FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
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

  context 'a github extension' do
    it "calls the set-up service" do
      expect(SetUpGithubExtension).to receive(:call)
      expect(subject.process!).to be_persisted
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

    context "no config file" do
      let(:top_level_contents) { [] }

      it "does not save and adds an error if the repo has no configuration file" do
        expect_any_instance_of(Extension).not_to receive(:save)
        result = subject.process!
        expect(result.errors[:github_url]).to include("must have a top-level bonsai.yml, bonsai.yaml, .bonsai.yml, or .bonsai.yaml file.")
      end
    end
  end

  context 'a hosted extension' do
    let(:github_url)  { nil }
    let(:version)     { 'v1.2.3' }
    let(:blob)        { ActiveStorage::Blob.create_after_upload!(
      io:           StringIO.new(""),
      filename:     'not-really-a-file',
      content_type: 'application/gzip')
    }
    let(:signed_id)   { blob.signed_id}
    let(:extension)   { build :extension, :hosted, owner: user }

    let(:params) { {
      name:                 "asdf",
      description:          "desc",
      github_url:           github_url,
      tag_tokens:           "tag1, tag2",
      compatible_platforms: ["", "p1", "p2"],
      tmp_source_file:      signed_id,
      version:              version,
    } }
    let(:extension)      { build :extension, owner: user }

    subject { CreateExtension.new(params, user) }

    it "creates a new User for Hosted Extensions" do
      new_extension = subject.process!
      expect(User.find_by(company: ENV['HOST_ORGANIZATION'])).to be_present
      expect(new_extension.owner.company).to eq(ENV['HOST_ORGANIZATION'])
    end

    it "creates an ExtensionVersion child for the extension" do
      expect {
        new_extension = subject.process!
        expect(new_extension.extension_versions.count).to eq(1)
        expect(new_extension.latest_extension_version.version).to eq version
      }.to change{ExtensionVersion.count}.by(1)
    end

    it "transfers the temporary source file to the ExtensionVersion child" do
      new_extension = subject.process!
      new_extension_version = new_extension.extension_versions.first
      expect(new_extension_version.source_file.signed_id).to eq(signed_id)
    end

    it "does not kick off a worker to gather metadata about the valid extension" do
      expect(CollectExtensionMetadataWorker).to_not receive(:perform_async)
      expect(subject.process!).to be_persisted
    end

    it "does not kick off a worker to set up the repo's web hook for updates" do
      expect(SetupExtensionWebHooksWorker).to_not receive(:perform_async)
      expect(subject.process!).to be_persisted
    end

    it "does not kick off a worker to notify operators" do
      expect(NotifyModeratorsOfNewExtensionWorker).to_not receive(:perform_async)
      expect(subject.process!).to be_persisted
    end

    context 'no version given' do
      let(:version) { nil }

      it 'defaults the version to v0.0.1' do
        new_extension = subject.process!
        expect(new_extension.latest_extension_version.version).to eq 'v0.0.1'
      end
    end
  end

  it "does not save an invalid extension, returning the extension" do
    allow_any_instance_of(Extension).to receive(:valid?) { false }
    expect_any_instance_of(Extension).not_to receive(:save)
    expect(subject.process!.attributes).to eq(expected_unnormalized_attributes)
  end
end
