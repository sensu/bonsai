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
      expect(subject.call("V097.1.0")).to eq '097.1.0'
      expect(subject.call("V 097.1.0")).to eq '097.1.0'
    end

    it 'strips any leading and trailing whitespace' do
      expect(subject.call("\t\nv790.1.0  ")).to eq '790.1.0'
    end

    it 'does not replace underscore or hypen' do
      expect(subject.call("v7.1.0-pre")).to eq '7.1.0-pre'
      expect(subject.call("V0.9.1-7_1")).to eq '0.9.1-7_1'
    end
  end
end
