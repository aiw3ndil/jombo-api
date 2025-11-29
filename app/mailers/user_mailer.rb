class UserMailer < ApplicationMailer
  default from: 'noreply@jombo.com'

  def welcome_email(user)
    @user = user
    @app_name = 'Jombo'
    
    I18n.with_locale(user.language) do
      mail(
        to: @user.email,
        subject: I18n.t('mailers.user_mailer.welcome_email.subject')
      )
    end
  end

  def booking_confirmed(user, booking)
    @user = user
    @booking = booking
    @trip = booking.trip
    @driver = @trip.driver
    
    I18n.with_locale(user.language) do
      mail(
        to: @user.email,
        subject: I18n.t('mailers.user_mailer.booking_confirmed.subject')
      )
    end
  end

  def booking_received(driver, booking)
    @driver = driver
    @booking = booking
    @passenger = booking.user
    @trip = booking.trip
    
    I18n.with_locale(driver.language) do
      mail(
        to: @driver.email,
        subject: I18n.t('mailers.user_mailer.booking_received.subject')
      )
    end
  end

  def booking_cancelled(user, booking)
    @user = user
    @booking = booking
    @trip = booking.trip
    
    I18n.with_locale(user.language) do
      mail(
        to: @user.email,
        subject: I18n.t('mailers.user_mailer.booking_cancelled.subject')
      )
    end
  end
end
