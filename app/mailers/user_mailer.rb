class UserMailer < ApplicationMailer
  default from: 'no-reply@jombo.fi'

  def welcome_email(user)
    @user = user
    @app_name = 'Jombo'
    @frontend_url = self.class.frontend_url_for(user)

    I18n.with_locale(user.language) do
      subject = I18n.t('mailers.user_mailer.welcome_email.subject')

      # Crear notificación
      NotificationService.create_email_notification(
        user,
        'welcome_email',
        subject,
        I18n.t('mailers.user_mailer.welcome_email.preview', default: 'Welcome to Jombo!'),
        nil,
        url: @frontend_url
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
    @frontend_url = self.class.frontend_url_for(user)
    @messages_url = "#{@frontend_url}/messages"

    I18n.with_locale(user.language) do
      subject = I18n.t('mailers.user_mailer.booking_confirmed.subject')

      # Crear notificación
      NotificationService.create_email_notification(
        user,
        'booking_confirmed',
        subject,
        I18n.t('mailers.user_mailer.booking_confirmed.preview', default: "Your booking for #{@trip.departure_location} to #{@trip.arrival_location} has been confirmed"),
        booking.id,
        url: "#{@frontend_url}/my-bookings"
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
    @frontend_url = self.class.frontend_url_for(driver)

    I18n.with_locale(driver.language) do
      subject = I18n.t('mailers.user_mailer.booking_received.subject')

      # Crear notificación
      NotificationService.create_email_notification(
        driver,
        'booking_received',
        subject,
        I18n.t('mailers.user_mailer.booking_received.preview', default: "#{@passenger.name} has booked your trip"),
        booking.id,
        url: "#{@frontend_url}/my-trips/#{@trip.id}"
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
    @frontend_url = self.class.frontend_url_for(user)

    I18n.with_locale(user.language) do
      subject = I18n.t('mailers.user_mailer.booking_cancelled.subject')

      # Crear notificación
      NotificationService.create_email_notification(
        user,
        'booking_cancelled',
        subject,
        I18n.t('mailers.user_mailer.booking_cancelled.preview', default: "Your booking has been cancelled"),
        booking.id,
        url: "#{@frontend_url}/my-bookings"
      )

      mail(
        to: @user.email,
        subject: subject
      )
    end
  end

  def booking_rejected(user, booking)
    @user = user
    @booking = booking
    @trip = booking.trip
    @driver = @trip.driver

    I18n.with_locale(user.language) do
      subject = I18n.t('mailers.user_mailer.booking_rejected.subject', default: "Your booking has been rejected")
      @frontend_url = self.class.frontend_url_for(user)

      NotificationService.create_email_notification(
        user,
        'booking_rejected',
        subject,
        I18n.t('mailers.user_mailer.booking_rejected.preview', default: "Your booking for #{@trip.departure_location} to #{@trip.arrival_location} has been rejected."),
        booking.id,
        url: "#{@frontend_url}/my-bookings"
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
    @frontend_url = self.class.frontend_url_for(recipient)

    I18n.with_locale(recipient.language) do
      subject = I18n.t('mailers.user_mailer.new_message.subject', sender_name: @sender.name)

      # Crear notificación
      NotificationService.create_email_notification(
        recipient,
        'new_message',
        subject,
        @message.content.truncate(100),
        message.id,
        url: "#{@frontend_url}/messages"
      )

      mail(
        to: @recipient.email,
        subject: subject
      )
    end
  end

  def password_reset(user)
    @user = user
    @token = user.reset_password_token
    @frontend_url = self.class.frontend_url_for(user)
    @reset_url = "#{@frontend_url}/reset-password?token=#{@token}"

    I18n.with_locale(user.language) do
      subject = I18n.t('mailers.user_mailer.password_reset.subject', default: "Reset your password")

      NotificationService.create_email_notification(
        user,
        'password_reset',
        subject,
        I18n.t('mailers.user_mailer.password_reset.preview', default: "Follow this link to reset your password"),
        nil,
        url: @reset_url
      )

      mail(
        to: @user.email,
        subject: subject
      )
    end
  end

  # Viaje publicado que encaja con una alerta o petición del usuario.
  # offer: true cuando el conductor responde directamente a su petición.
  def trip_match(user, trip, from, to, offer: false)
    @user = user
    @trip = trip
    @offer = offer
    @segment = trip.segment_for(from, to) || trip.segment_for
    @frontend_url = self.class.frontend_url_for(user)
    @trip_url = "#{@frontend_url}/trips/#{trip.id}"

    I18n.with_locale(user.language) do
      time = I18n.l(@segment[:departure_time].in_time_zone('Europe/Helsinki'), format: :short_datetime)
      key = offer ? 'ride_offer' : 'trip_match'
      subject = I18n.t("mailers.user_mailer.#{key}.subject", from: @segment[:from], to: @segment[:to])

      NotificationService.create_trip_notification(
        user,
        I18n.t("notifications.#{key}.title", from: @segment[:from], to: @segment[:to]),
        I18n.t("notifications.#{key}.content", driver: trip.driver.name, from: @segment[:from], to: @segment[:to],
                                                 time: time, price: format('%.2f', @segment[:price])),
        trip.id,
        url: @trip_url
      )

      @departure_label = time
      mail(to: @user.email, subject: subject)
    end
  end

  def email_verification(user)
    @user = user
    @frontend_url = self.class.frontend_url_for(user)
    @verify_url = "#{@frontend_url}/verify-email?token=#{user.email_verification_token}"

    I18n.with_locale(user.language) do
      mail(to: @user.email, subject: I18n.t('mailers.user_mailer.email_verification.subject'))
    end
  end
end
