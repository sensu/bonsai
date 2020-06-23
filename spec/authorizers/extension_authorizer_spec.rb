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

  describe '#report?' do
    context 'authenticated user' do
      let (:user) { build_stubbed :user }
      it {expect(subject.report?).to be(true) }
    end

    context 'user present; record not persisted' do
      let (:user) { User.new }
      it {expect(subject.report?).to be(false) }
    end

    context 'no user present' do
      let (:user) { nil }
      it {expect(subject.report?).to be(false) }
    end
  end
end
