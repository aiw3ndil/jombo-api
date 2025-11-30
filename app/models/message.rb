class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  
  validates :content, presence: true, length: { maximum: 1000 }
  
  default_scope { order(created_at: :asc) }
  
  # Broadcast del mensaje (para futuro uso con Action Cable)
  after_create_commit :broadcast_message
  
  private
  
  def broadcast_message
    # Aquí se puede agregar Action Cable para mensajes en tiempo real
    # ActionCable.server.broadcast("conversation_#{conversation_id}", {
    #   message: as_json(include: { user: { only: [:id, :name] } })
    # })
  end
end
