require 'spec_helper'

describe Tier do
  before do
    Tier.destroy_all
    create :tier, rank: 100
    create :tier, rank: 5    # The default Tier, since it has the lowest rank
  end

  subject          { build_stubbed :tier }

  it {expect(subject).to be_valid}

  describe '.default' do
    it 'returns the lowest ranked tier' do
      expect(Tier.default.rank).to eq 5
      create :tier, rank: 20
      expect(Tier.default.rank).to eq 5
      create :tier, rank: 2
      expect(Tier.default.rank).to eq 2
    end
  end

  describe '#extensions' do
    context 'the tier is the default tier' do
      let(:other_tier) { create :tier, rank: 20 }
      subject          { Tier.default }

      it 'includes all the extensions specifically assigned to the tier' do
        expect {
          create :extension, tier_id: subject.id
        }.to change {subject.extensions.count}.by 1
      end

      it 'includes all the extensions not assigned to any tier' do
        expect {
          create :extension
        }.to change {subject.extensions.count}.by 1
      end

      it 'ignores all the extensions specifically assigned to other tiers' do
        expect {
          create :extension, tier_id: other_tier.id
        }.not_to change {subject.extensions.count}
      end
    end

    context 'the tier is not the default tier' do
      let(:other_tier) { create :tier, rank: 19 }
      subject          { create :tier, rank: 20 }

      it 'includes all the extensions specifically assigned to the tier' do
        expect {
          create :extension, tier_id: subject.id
        }.to change {subject.extensions.count}.by 1
      end

      it 'ignores all the extensions not assigned to any tier' do
        expect {
          create :extension
        }.to_not change {subject.extensions.count}
      end

      it 'ignores all the extensions specifically assigned to other tiers' do
        expect {
          create :extension, tier_id: other_tier.id
        }.not_to change {subject.extensions.count}
      end
    end
  end
end
