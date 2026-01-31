class ApplicationMailer < ActionMailer::Base
  include Rails.application.routes.url_helpers
  default from: "Jombo <noreply@jombo.es>"
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
    base_url = case I18n.locale.to_s
               when 'fi'
                 ENV.fetch('FRONTEND_URL_FI', 'https://www.jombo.fi')
               when 'es'
                 ENV.fetch('FRONTEND_URL_ES', 'https://www.jombo.es')
               else
                 ENV.fetch('FRONTEND_URL', 'https://www.jombo.es')
               end
    
    # Ensure the base_url does not end with a slash to avoid double slashes
    base_url = base_url.chomp('/')

    "#{base_url}/#{I18n.locale}"
  end
end
