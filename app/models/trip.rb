class Trip < ApplicationRecord
  belongs_to :driver, class_name: 'User', foreign_key: 'driver_id'
  has_many :bookings, dependent: :destroy
  has_many :passengers, through: :bookings, source: :user
  has_one :conversation, dependent: :destroy
  
  validates :departure_location, :arrival_location, :departure_time, :available_seats, :price, :region, presence: true
  validates :available_seats, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :region, inclusion: { in: %w[es fi] }
  validates :recurrence_pattern, inclusion: { in: %w[daily weekly], allow_nil: true }
  
  after_create :generate_recurring_trips, if: -> { is_recurring? && parent_id.nil? }
  
  # Crear conversación automáticamente si no existe
  def ensure_conversation
    conversation || create_conversation
  end

  private

  def generate_recurring_trips
    # Límite de seguridad: máximo 3 meses en el futuro o la fecha especificada
    end_date = [recurrence_until, Time.current + 3.months].compact.min
    current_time = departure_time

    while (current_time + (recurrence_pattern == 'daily' ? 1.day : 1.week)) <= end_date
      current_time += (recurrence_pattern == 'daily' ? 1.day : 1.week)
      
      # Si es semanal, verificar si el día está incluido en recurrence_days (opcional)
      if recurrence_pattern == 'weekly' && recurrence_days.present?
        days_array = recurrence_days.split(',').map(&:to_i)
        next unless days_array.include?(current_time.wday)
      end

      # Crear la instancia del viaje copia
      Trip.create!(
        driver_id: driver_id,
        departure_location: departure_location,
        arrival_location: arrival_location,
        departure_time: current_time,
        available_seats: available_seats,
        price: price,
        description: description,
        region: region,
        is_recurring: true,
        parent_id: id # Referencia al viaje original
      )
    end
  end
end
