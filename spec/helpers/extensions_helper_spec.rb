require 'spec_helper'

describe ExtensionsHelper do
  let(:extension) { build_stubbed :extension }

  describe "is_followable?" do
    context "a GitHub-based extension" do
      it {expect(helper.is_followable?(extension)).to be_truthy}
    end

    context "a hosted extension" do
      let(:extension) { build_stubbed :extension, :hosted }

      it {expect(helper.is_followable?(extension)).to be_falsey}
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
end
