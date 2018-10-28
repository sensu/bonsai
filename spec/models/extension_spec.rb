require 'spec_helper'

describe Extension do
  describe "GitHub URL handling" do
    before do
      @e = Extension.new(github_url: "www.github.com/cvincent/test")
      @e.valid?
    end

    it "normalizes the URL before validation" do
      expect(@e.github_url).to eq("https://github.com/cvincent/test")
    end

    it "can return the username/repo formatted repo name from the URL" do
      expect(@e.github_repo).to eq("cvincent/test")
    end
  end

  describe '#hosted?' do
    it {expect(create(:extension, :hosted).hosted?).to be_truthy}
    it {expect(create(:extension         ).hosted?).to be_falsey}
  end

  describe '#tier' do
    before do
      Tier.destroy_all
      create :tier, rank: 10
      create :tier, rank: 5    # The default Tier, since it has the lowest rank
    end

    context 'extension has a specific tier' do
      let(:other_tier)  { create :tier, rank: 20 }
      subject           { build_stubbed :extension, tier_id: other_tier.id}

      it 'returns the specific tier' do
        expect(subject.tier.rank).to eq 20
      end
    end

    context 'extension has no specific tier' do
      subject { build_stubbed :extension, tier_id: nil}

      it 'returns the default tier' do
        expect(subject.tier.rank).to eq 5
      end
    end
  end
end
