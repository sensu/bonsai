require 'spec_helper'

describe ExtensionAuthorizer do
  let(:user) { build_stubbed :user }
  subject    { ExtensionAuthorizer.new(user, Extension) }

  describe '#make_hosted_extension?' do
    context 'admin user' do
      let(:user) { build_stubbed :admin }
      it {expect(subject.make_hosted_extension?).to be_truthy}
    end

    context 'non-admin user' do
      it {expect(subject.make_hosted_extension?).to be_falsey}
    end
  end
end
