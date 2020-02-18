require "spec_helper"

describe ValidateNewExtension do

	let(:user)        { create(:user, username: 'some_user') }
	let(:extension)		{ build(:extension, github_url: "test/github-extension-handler" ) }
  let(:top_level_contents)               { [{name: 'bonsai.yml'}] }

  let(:github)      { double(:github) }

	before do
    allow(user).to receive(:octokit) { github }
    allow(github).to receive(:collaborator?).with("test/github-extension-handler", "some_user") { true }
    allow(github).to receive(:repo).with("test/github-extension-handler") { {} }
    allow(github).to receive(:contents).with("test/github-extension-handler") { top_level_contents }
  end

  subject(:context) { ValidateNewExtension.call(extension: extension, octokit: user.octokit, owner: user) }

  after do
    # Purge ActiveStorage::Blob files.
    FileUtils.rm_rf(Rails.root.join('tmp', 'storage'))
  end

	describe "call" do

    context 'a github extension' do

    	it "succeeds" do
	      expect(context).to be_a_success
	    end

	    it "does not check the repo collaborators if the extension is invalid" do
	      allow_any_instance_of(Extension).to receive(:valid?) { false }
	      expect(github).not_to receive(:collaborator?)
	      expect(context).to be_a_failure
	    end

	    context 'collaborator not valid' do 
	    	before do 
	    		allow(github).to receive(:collaborator?).with("test/github-extension-handler", "some_user") { false }
	    	end
		    it "does not save and adds an error if the user is not a collaborator in the repo" do
		      expect_any_instance_of(Extension).not_to receive(:save)
		      expect(context.extension.errors[:github_url]).to include(I18n.t("extension.github_url_format_error"))
		      expect(context).to be_a_failure
		    end
		  end

		  context 'github collaborator call fails' do
		  	before do 
		  		allow(github).to receive(:collaborator?).with("test/github-extension-handler", "some_user").and_raise(ArgumentError)
		  	end
		    it "does not save and adds an error if the repo is invalid" do
		      expect_any_instance_of(Extension).not_to receive(:save)
		      expect(context.extension.errors[:github_url]).to include(I18n.t("extension.github_url_format_error"))
		      expect(context).to be_a_failure
		    end
	   	end 

	    context "no config file" do

	      let(:top_level_contents) { [] }

	      it "does not save and adds an error if the repo has no configuration file" do
	        expect_any_instance_of(Extension).not_to receive(:save)
	        expect(context.extension.errors[:github_url]).to include("must have a top-level bonsai.yml, bonsai.yaml, .bonsai.yml, or .bonsai.yaml file.")
	        expect(context).to be_a_failure
	      end
	    end # context no config file
	  end # context github extension

	  context 'a hosted extension' do

	  	let(:blob)        { 
	    	ActiveStorage::Blob.create_after_upload!(
		      io:           StringIO.new(""),
		      filename:     'not-really-a-file',
		      content_type: 'application/gzip'
		    )
	    }
	    let(:signed_id)   { blob.signed_id}

	  	before do 
	  		extension.github_url 			= nil
	  		extension.tmp_source_file = signed_id
	  	end

			it "succeeds" do
	      expect(context).to be_a_success
	    end

			context "no source file" do

				before do 
					extension.tmp_source_file.purge
				end

	      it "does not save and adds an error if the repo has no source file" do
	        expect_any_instance_of(Extension).not_to receive(:save)
	        expect(context.extension.errors[:tmp_source_file]).to include("must be a valid source file.")
	        expect(context).to be_a_failure
	      end
	    end # context no config file

	  end # context hosted extensions

	end

end