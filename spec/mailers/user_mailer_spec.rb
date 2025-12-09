require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'welcome_email' do
    let(:user) { create(:user, name: 'John Doe', email: 'john@example.com', language: 'en') }
    let(:mail) { UserMailer.welcome_email(user) }

    it 'renders the subject' do
      expect(mail.subject).to eq('Welcome to Jombo! 🚗')
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

    context 'with Spanish language' do
      let(:user) { create(:user, :spanish) }
      let(:mail) { UserMailer.welcome_email(user) }

      it 'renders subject in Spanish' do
        expect(mail.subject).to eq('¡Bienvenido a Jombo! 🚗')
      end
    end

    context 'with Finnish language' do
      let(:user) { create(:user, :finnish) }
      let(:mail) { UserMailer.welcome_email(user) }

      it 'renders subject in Finnish' do
        expect(mail.subject).to eq('Tervetuloa Jomboon! 🚗')
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
      expect(mail.subject).to eq('Your booking has been confirmed! 🎉')
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
  end

  describe 'booking_received' do
    let(:driver) { create(:user, name: 'Driver Bob', language: 'en') }
    let(:passenger) { create(:user, name: 'Passenger Alice') }
    let(:trip) { create(:trip, driver: driver) }
    let(:booking) { create(:booking, trip: trip, user: passenger, seats: 2) }
    let(:mail) { UserMailer.booking_received(driver, booking) }

    it 'renders the subject' do
      expect(mail.subject).to eq('You have a new booking request! 🔔')
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
  end

  describe 'booking_cancelled' do
    let(:user) { create(:user, language: 'en') }
    let(:trip) { create(:trip) }
    let(:booking) { create(:booking, :cancelled, trip: trip, user: user) }
    let(:mail) { UserMailer.booking_cancelled(user, booking) }

    it 'renders the subject' do
      expect(mail.subject).to eq('Your booking has been cancelled')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'includes trip details' do
      expect(mail.body.encoded).to match(trip.departure_location)
      expect(mail.body.encoded).to match(trip.arrival_location)
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
      expect(mail.subject).to eq("New message from #{sender.name} 💬")
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

    context 'with Spanish language' do
      let(:recipient) { create(:user, :spanish, name: 'Recipient') }
      let(:mail) { UserMailer.new_message(recipient, message) }

      it 'renders subject in Spanish' do
        expect(mail.subject).to eq("Nuevo mensaje de #{sender.name} 💬")
      end
    end
  end
end
