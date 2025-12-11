class UserMailer < ApplicationMailer
  default from: 'noreply@jombo.es'

  def welcome_email(user)
    @user = user
    @app_name = 'Jombo'
    
    I18n.with_locale(user.language) do
      subject = I18n.t('mailers.user_mailer.welcome_email.subject')
      
      # Crear notificación
      NotificationService.create_email_notification(
        user,
        'welcome_email',
        subject,
        I18n.t('mailers.user_mailer.welcome_email.preview', default: 'Welcome to Jombo!')
      )
      
      mail(
        to: @user.email,
        subject: subject
      )
    end
  end

  def booking_confirmed(user, booking)
    @user = user
    @booking = booking
    @trip = booking.trip
    @driver = @trip.driver
    
    I18n.with_locale(user.language) do
      subject = I18n.t('mailers.user_mailer.booking_confirmed.subject')
      
      # Crear notificación
      NotificationService.create_email_notification(
        user,
        'booking_confirmed',
        subject,
        I18n.t('mailers.user_mailer.booking_confirmed.preview', default: "Your booking for #{@trip.departure_location} to #{@trip.arrival_location} has been confirmed"),
        booking.id
      )
      
      mail(
        to: @user.email,
        subject: subject
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
      subject = I18n.t('mailers.user_mailer.booking_received.subject')
      
      # Crear notificación
      NotificationService.create_email_notification(
        driver,
        'booking_received',
        subject,
        I18n.t('mailers.user_mailer.booking_received.preview', default: "#{@passenger.name} has booked your trip"),
        booking.id
      )
      
      mail(
        to: @driver.email,
        subject: subject
      )
    end
  end

  def booking_cancelled(user, booking)
    @user = user
    @booking = booking
    @trip = booking.trip
    
    I18n.with_locale(user.language) do
      subject = I18n.t('mailers.user_mailer.booking_cancelled.subject')
      
      # Crear notificación
      NotificationService.create_email_notification(
        user,
        'booking_cancelled',
        subject,
        I18n.t('mailers.user_mailer.booking_cancelled.preview', default: "Your booking has been cancelled"),
        booking.id
      )
      
      mail(
        to: @user.email,
        subject: subject
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
      subject = I18n.t('mailers.user_mailer.new_message.subject', sender_name: @sender.name)
      
      # Crear notificación
      NotificationService.create_email_notification(
        recipient,
        'new_message',
        subject,
        @message.content.truncate(100),
        message.id
      )
      
      mail(
        to: @recipient.email,
        subject: subject
      )
    end
  end
end
