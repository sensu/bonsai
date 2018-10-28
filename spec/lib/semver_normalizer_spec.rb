require 'spec_helper'

describe SemverNormalizer do
  subject { SemverNormalizer }

  describe '.call' do
    context 'when given a nil' do
      it 'returns nil' do
        expect(subject.call(nil)).to be_nil
      end
    end

    it 'strips off any leading "v" character' do
      expect(subject.call("v790")).to eq '790'
      expect(subject.call("V097")).to eq '097'
    end

    it 'strips any leading and trailing whitespace' do
      expect(subject.call("\t\nv790  ")).to eq '790'
    end

    it 'replaces pseudo dots with dots' do
      expect(subject.call("v7-0_9.0")).to eq '7.0.9.0'
      expect(subject.call("V0.9-7_1")).to eq '0.9.7.1'
    end
  end
end
