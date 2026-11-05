# Un usuario bloquea a otro: no pueden reservarse viajes ni escribirse
class Block < ApplicationRecord
  belongs_to :blocker, class_name: 'User'
  belongs_to :blocked, class_name: 'User'

  validates :blocked_id, uniqueness: { scope: :blocker_id }
  validate :not_self

  private

  def not_self
    errors.add(:blocked, 'cannot be yourself') if blocker_id == blocked_id
  end
end
