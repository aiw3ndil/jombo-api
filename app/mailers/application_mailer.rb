class ApplicationMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  default from: "Jombo <no-reply@jombo.fi>"
  layout "mailer"

  # Explicitly define root_url for mailer views, relying on Rails' default behavior
  def root_url(options = {})
    Rails.application.routes.url_helpers.root_url(options)
  end

  def mail(headers = {}, &block)
    headers[:subject] = "[Jombo] #{headers[:subject]}" if headers[:subject].present?
    super
  end

  private

  def frontend_url
    # Finnish lives at the root (jombo.fi), English under jombo.fi/en
    base_url = ENV.fetch('FRONTEND_URL', 'https://jombo.fi').chomp('/')

    I18n.locale.to_s == 'fi' ? base_url : "#{base_url}/en"
  end
end
