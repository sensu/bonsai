class ApplicationMailer < ActionMailer::Base
  default from: 'bonsai-app@sensu.io'
  layout 'mailer'
end
