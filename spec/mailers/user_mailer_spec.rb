require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'welcome_email' do
    let(:user) { create(:user, name: 'John Doe', email: 'john@example.com', language: 'en') }
    let(:mail) { UserMailer.welcome_email(user) }

    it 'renders the subject' do
      expect(mail.subject).to eq('[Jombo] Welcome to Jombo! 🚗')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@jombo.es'])
    end

    it 'includes user name in body' do
      expect(mail.body.encoded).to match(user.name)
    end

    it 'creates a notification for the user' do
      expect {
        mail.deliver_now
      }.to change { user.notifications.count }.by(1)
      
      notification = user.notifications.last
      expect(notification.notification_type).to eq('email')
      expect(notification.email_type).to eq('welcome_email')
      expect(notification.read).to be false
    end

    context 'with Spanish language' do
      let(:user) { create(:user, :spanish) }
      let(:mail) { UserMailer.welcome_email(user) }

      it 'renders subject in Spanish' do
        expect(mail.subject).to eq('[Jombo] ¡Bienvenido a Jombo! 🚗')
      end
    end

    context 'with Finnish language' do
      let(:user) { create(:user, :finnish) }
      let(:mail) { UserMailer.welcome_email(user) }

      it 'renders subject in Finnish' do
        expect(mail.subject).to eq('[Jombo] Tervetuloa Jomboon! 🚗')
      end
    end
  end

  describe 'booking_confirmed' do
    let(:driver) { create(:user, name: 'Driver Bob') }
    let(:passenger) { create(:user, name: 'Passenger Alice', language: 'en') }
    let(:trip) { create(:trip, driver: driver, departure_location: 'Madrid', arrival_location: 'Barcelona') }
    let(:booking) { create(:booking, :confirmed, trip: trip, user: passenger) }
    let(:mail) { UserMailer.booking_confirmed(passenger, booking) }

    it 'renders the subject' do
      expect(mail.subject).to eq('[Jombo] Your booking has been confirmed! 🎉')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([passenger.email])
    end

    it 'includes trip details in body' do
      expect(mail.body.encoded).to match('Madrid')
      expect(mail.body.encoded).to match('Barcelona')
    end

    it 'includes driver information' do
      expect(mail.body.encoded).to match(driver.name)
    end

    it 'creates a notification for the passenger' do
      expect {
        mail.deliver_now
      }.to change { passenger.notifications.count }.by(1)
      
      notification = passenger.notifications.last
      expect(notification.notification_type).to eq('email')
      expect(notification.email_type).to eq('booking_confirmed')
      expect(notification.related_id).to eq(booking.id)
    end
  end

  describe 'booking_received' do
    let(:driver) { create(:user, name: 'Driver Bob', language: 'en') }
    let(:passenger) { create(:user, name: 'Passenger Alice') }
    let(:trip) { create(:trip, driver: driver) }
    let(:booking) { create(:booking, trip: trip, user: passenger, seats: 2) }
    let(:mail) { UserMailer.booking_received(driver, booking) }

    it 'renders the subject' do
      expect(mail.subject).to eq('[Jombo] You have a new booking request! 🔔')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([driver.email])
    end

    it 'includes passenger information' do
      expect(mail.body.encoded).to match(passenger.name)
    end

    it 'includes number of seats' do
      expect(mail.body.encoded).to match('2')
    end

    it 'creates a notification for the driver' do
      expect {
        mail.deliver_now
      }.to change { driver.notifications.count }.by(1)
      
      notification = driver.notifications.last
      expect(notification.notification_type).to eq('email')
      expect(notification.email_type).to eq('booking_received')
      expect(notification.related_id).to eq(booking.id)
    end
  end

  describe 'booking_cancelled' do
    let(:user) { create(:user, language: 'en') }
    let(:trip) { create(:trip) }
    let(:booking) { create(:booking, :cancelled, trip: trip, user: user) }
    let(:mail) { UserMailer.booking_cancelled(user, booking) }

    it 'renders the subject' do
      expect(mail.subject).to eq('[Jombo] Your booking has been cancelled')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'includes trip details' do
      expect(mail.body.encoded).to match(trip.departure_location)
      expect(mail.body.encoded).to match(trip.arrival_location)
    end

    it 'creates a notification for the user' do
      expect {
        mail.deliver_now
      }.to change { user.notifications.count }.by(1)
      
      notification = user.notifications.last
      expect(notification.notification_type).to eq('email')
      expect(notification.email_type).to eq('booking_cancelled')
      expect(notification.related_id).to eq(booking.id)
    end
  end

  describe 'new_message' do
    let(:sender) { create(:user, name: 'Sender') }
    let(:recipient) { create(:user, name: 'Recipient', language: 'en') }
    let(:trip) { create(:trip) }
    let(:conversation) { create(:conversation, trip: trip) }
    let(:message) { create(:message, conversation: conversation, user: sender, content: 'Hello there!') }
    let(:mail) { UserMailer.new_message(recipient, message) }

    it 'renders the subject' do
      expect(mail.subject).to eq("[Jombo] New message from #{sender.name} 💬")
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([recipient.email])
    end

    it 'includes message preview' do
      expect(mail.body.encoded).to match('Hello there!')
    end

    it 'includes sender name' do
      expect(mail.body.encoded).to match(sender.name)
    end

    it 'includes trip details' do
      expect(mail.body.encoded).to match(trip.departure_location)
    end

    it 'creates a notification for the recipient' do
      expect {
        mail.deliver_now
      }.to change { recipient.notifications.count }.by(1)
      
      notification = recipient.notifications.last
      expect(notification.notification_type).to eq('email')
      expect(notification.email_type).to eq('new_message')
      expect(notification.related_id).to eq(message.id)
    end

    context 'with Spanish language' do
      let(:recipient) { create(:user, :spanish, name: 'Recipient') }
      let(:mail) { UserMailer.new_message(recipient, message) }

      it 'renders subject in Spanish' do
        expect(mail.subject).to eq("[Jombo] Nuevo mensaje de #{sender.name} 💬")
      end
    end
  end
end
