class ApplicationMailer < ActionMailer::Base
  default from: "Jombo <noreply@jombo.es>"
  layout "mailer"
  
  def mail(headers = {}, &block)
    headers[:subject] = "[Jombo] #{headers[:subject]}" if headers[:subject].present?
    super
  end

  private

  def frontend_url
    case I18n.locale.to_s
    when 'fi'
      ENV.fetch('FRONTEND_URL_FI', 'https://www.jombo.fi')
    when 'es'
      ENV.fetch('FRONTEND_URL_ES', 'https://www.jombo.es')
    else
      ENV.fetch('FRONTEND_URL', 'https://www.jombo.es')
    end
  end
end
