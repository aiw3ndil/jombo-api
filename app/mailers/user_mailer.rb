class UserMailer < ApplicationMailer
  default from: 'noreply@jombo.es'

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
    @frontend_url = frontend_url
    
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

  def new_message(recipient, message)
    @recipient = recipient
    @message = message
    @sender = message.user
    @conversation = message.conversation
    @trip = @conversation.trip
    @frontend_url = frontend_url
    
    I18n.with_locale(recipient.language) do
      mail(
        to: @recipient.email,
        subject: I18n.t('mailers.user_mailer.new_message.subject', sender_name: @sender.name)
      )
    end
  end
end
