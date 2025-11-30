class Conversation < ApplicationRecord
  belongs_to :trip
  has_many :messages, dependent: :destroy
  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  
  validates :trip_id, presence: true, uniqueness: true
  
  # Verificar si un usuario puede acceder a esta conversación
  def participant?(user)
    # El conductor del viaje siempre puede acceder
    return true if trip.driver_id == user.id
    
    # Los pasajeros con reservas confirmadas pueden acceder
    trip.bookings.confirmed.exists?(user_id: user.id)
  end
  
  # Agregar participante a la conversación
  def add_participant(user)
    participants << user unless participants.include?(user)
  end
  
  # Último mensaje de la conversación
  def last_message
    messages.order(created_at: :desc).first
  end
end
