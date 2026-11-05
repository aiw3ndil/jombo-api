# Reporte de un usuario sobre otro; se envía por email al administrador
class Report < ApplicationRecord
  REASONS = %w[no_show unsafe_driving inappropriate fake_profile other].freeze

  belongs_to :reporter, class_name: 'User'
  belongs_to :reported, class_name: 'User'
  belongs_to :booking, optional: true

  validates :reason, inclusion: { in: REASONS }
  validates :comment, length: { maximum: 2000 }
  validate :not_self
  validate :once_per_day, on: :create

  private

  def not_self
    errors.add(:reported, 'cannot be yourself') if reporter_id == reported_id
  end

  def once_per_day
    return unless Report.where(reporter_id: reporter_id, reported_id: reported_id).where('created_at > ?', 1.day.ago).exists?

    errors.add(:base, 'You have already reported this user today')
  end
end
