require 'spec_helper'

class ReadOnly
  class Policy
    def initialize(*_); end

    def show?
      true
    end

    def edit?
      false
    end
  end

  def policy_class
    Policy
  end
end

describe BonsaiAssetIndex::Authorization do
  subject do
    Class.new(ActionController::Base) do
      include BonsaiAssetIndex::Authorization
      def current_user; end
    end.new
  end

  let(:read_only_object) { ReadOnly.new }

  describe '#authorize!' do
    it 'raises an error if the user is not authorized' do
      pending
      allow(subject).to receive(:params).and_return(action: 'edit')

      expect { subject.send(:authorize!, read_only_object, :edit?) }
      .to raise_error(BonsaiAssetIndex::Authorization::NotAuthorizedError)
    end

    it 'does nothing with the user is authorized' do
      pending
      allow(subject).to receive(:params).and_return(action: 'show')
      expect { subject.send(:authorize!, read_only_object, :show?) }.to_not raise_error
    end
  end
end
