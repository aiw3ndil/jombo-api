# Emails para el administrador de Jombo (ADMIN_EMAIL)
class AdminMailer < ApplicationMailer
  def new_report(report)
    @report = report
    to = ENV['ADMIN_EMAIL'].presence
    return unless to

    I18n.with_locale(:en) do
      mail(to: to, subject: "User report: #{report.reported.name} (##{report.reported_id}) — #{report.reason}")
    end
  end
end
