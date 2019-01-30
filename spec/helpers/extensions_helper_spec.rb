require 'spec_helper'

describe ExtensionsHelper do
  let(:extension) { build_stubbed :extension }

  describe "is_followable?" do
    context "a GitHub-based extension" do
      it {expect(helper.is_followable?(extension)).to be_truthy}
    end

    context "a hosted extension" do
      let(:extension) { build_stubbed :extension, :hosted }

      it {expect(helper.is_followable?(extension)).to be_truthy}
    end
  end

  describe "is_commitable?" do
    context "a GitHub-based extension" do
      it {expect(helper.is_commitable?(extension)).to be_truthy}
    end

    context "a hosted extension" do
      let(:extension) { build_stubbed :extension, :hosted }

      it {expect(helper.is_commitable?(extension)).to be_falsey}
    end
  end

  describe "compilation_errors" do
    let(:compilation_error) { 'my error' }
    let(:extension)         { create :extension }
    let(:version_name)      { '5.2.1' }
    let!(:version)          { create :extension_version,
                                     extension:         extension,
                                     version:           version_name,
                                     compilation_error: compilation_error }

    it 'returns an array of strings' do
      result = helper.compilation_errors(extension.reload)
      expect(result).to     be_kind_of Array
      expect(result).to_not be_empty
      result.each {|elem| expect(elem).to be_kind_of String}
    end
  end

  describe "compilation_error" do
    let(:compilation_error) { 'my error' }
    let(:extension)         { build :extension }
    let(:version_name)      { '0.0.1' }
    let(:version)           { build :extension_version,
                                    extension:         extension,
                                    version:           version_name,
                                    compilation_error: compilation_error }

    it {expect(helper.compilation_error(version)).to eql compilation_error}

    context "master version" do
      let(:version_name) { 'master' }

      context "GitHub extension" do
        it {expect(helper.compilation_error(version)).to be_nil}
      end

      context "hosted extension" do
        let(:extension)   { build :extension, :hosted }

        it {expect(helper.compilation_error(version)).to eql compilation_error}
      end
    end

    context "no error" do
      let(:compilation_error) { nil }

      it {expect(helper.compilation_error(version)).to be_nil}
    end
  end
end
