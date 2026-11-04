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

  # Finnish lives at the root (jombo.fi), English under jombo.fi/en
  def self.frontend_url_for(user_or_locale)
    locale = user_or_locale.respond_to?(:language) ? user_or_locale.language : user_or_locale
    base_url = ENV.fetch('FRONTEND_URL', 'https://jombo.fi').chomp('/')

    locale.to_s == 'fi' ? base_url : "#{base_url}/en"
  end

  private

  def frontend_url
    self.class.frontend_url_for(I18n.locale)
  end
end
