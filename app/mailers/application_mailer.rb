class ApplicationMailer < ActionMailer::Base
  default from: "Jombo <noreply@jombo.com>"
  layout "mailer"
  
  def mail(headers = {}, &block)
    headers[:subject] = "[Jombo] #{headers[:subject]}" if headers[:subject].present?
    super
  end
end
