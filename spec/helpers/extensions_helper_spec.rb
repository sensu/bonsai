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
    let(:compilation_error) { 'big hairy error' }
    let(:extension)         { create :extension }
    let(:version_name)      { '5.2.1' }
    let!(:version)          { create :extension_version,
                                     extension: extension,
                                     version:   version_name }

    context "no error" do
      it {expect(helper.compilation_errors(extension)).to be_empty}
    end

    context "extension error" do
      it 'returns an array of strings' do
        extension.update_column(:compilation_error, compilation_error)
        extension.reload
        result = helper.compilation_errors(extension)
        expect(result).to be_kind_of Array
        expect(result).to_not be_empty
        result.each {|elem| expect(elem).to be_kind_of String}
      end
    end

    context "version error" do
      it 'returns an array of strings' do
        version.update_column(:compilation_error, compilation_error)
        extension.reload
        result = helper.compilation_errors(extension)
        result.each {|elem| expect(elem).to include(compilation_error)}
      end
    end

    context "errors in both" do 
      it 'returns an array of strings' do
        extension.update_column(:compilation_error, compilation_error)
        version.update_column(:compilation_error, compilation_error)
        extension.reload
        result = helper.compilation_errors(extension)
        expect(result.length).to eq(2)
        result.each {|elem| expect(elem).to include(compilation_error)}
      end
    end

    context "for one version" do 
      it 'returns an array of string' do
        extension.update_column(:compilation_error, compilation_error)
        version.update_column(:compilation_error, compilation_error)
        version_2 = create(:extension_version, 
          extension: extension, 
          version: '5.2.2', 
          compilation_error: compilation_error
        )
        extension.reload
        result = helper.compilation_errors(extension, version_2)
        expect(result.length).to eq(2)
        result.each {|elem| expect(elem).to include(compilation_error)}
      end
    end
  
  end
end
