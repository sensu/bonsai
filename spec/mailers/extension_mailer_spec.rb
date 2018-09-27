require 'spec_helper'

describe ExtensionMailer do
  let(:extension) { create :extension }
  let(:user)      { create :user }
  let(:reporter)  { create :user }

  describe "notify_moderator_of_new" do
    let(:mail) { ExtensionMailer.notify_moderator_of_new(extension.id, user.id) }

    it {expect(mail.to).to include user.email}
    it {mail.parts.each {|part| expect(part.body).to match /you may disable or edit this extension/i}}
  end

  describe "notify_moderator_of_reported" do
    let(:mail) { ExtensionMailer.notify_moderator_of_reported(extension.id, user.id, 'report_description', reporter.id) }

    it {expect(mail.to).to include user.email}
    it {mail.parts.each {|part| expect(part.body).to match /reported by/i}}
  end

  describe "extension_deprecated_email" do
    let(:replacement)  { create :extension }
    let(:mail)         { ExtensionMailer.extension_deprecated_email(extension, replacement, user) }
    let(:system_email) { create :system_email, name: 'Extension deprecated' }

    before do
      create :email_preference, user: user, system_email: system_email
    end

    it {expect(mail.to).to include user.email}
    it {mail.parts.each {|part| expect(part.body).to match /has been deprecated/i}}
  end
end
