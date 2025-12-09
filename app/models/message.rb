class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  
  validates :content, presence: true, length: { maximum: 1000 }
  
  default_scope { order(created_at: :asc) }
  
  # Broadcast del mensaje (para futuro uso con Action Cable)
  after_create_commit :broadcast_message
  after_create_commit :notify_participants
  
  private
  
  def broadcast_message
    # Aquí se puede agregar Action Cable para mensajes en tiempo real
    # ActionCable.server.broadcast("conversation_#{conversation_id}", {
    #   message: as_json(include: { user: { only: [:id, :name] } })
    # })
  end

  def notify_participants
    conversation.participants.where.not(id: user_id).find_each do |participant|
      UserMailer.new_message(participant, self).deliver_later
    end
  end
end
