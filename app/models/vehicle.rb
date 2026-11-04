class Vehicle < ApplicationRecord
  VEHICLE_TYPES = %w[sedan hatchback estate suv minivan van coupe convertible pickup].freeze
  FUEL_TYPES = %w[petrol diesel hybrid plugin_hybrid electric gas other].freeze
  PUBLIC_ATTRIBUTES = %i[id brand model vehicle_type color doors seats year fuel_type].freeze

  belongs_to :user
  has_many :trips, dependent: :nullify

  validates :brand, :model, :color, presence: true, length: { maximum: 50 }
  validates :vehicle_type, inclusion: { in: VEHICLE_TYPES }
  validates :fuel_type, inclusion: { in: FUEL_TYPES }, allow_blank: true
  validates :doors, numericality: { only_integer: true, greater_than_or_equal_to: 2, less_than_or_equal_to: 5 }
  validates :seats, numericality: { only_integer: true, greater_than_or_equal_to: 2, less_than_or_equal_to: 9 }
  validates :year, numericality: { only_integer: true, greater_than_or_equal_to: 1950, less_than_or_equal_to: ->(_) { Date.current.year + 1 } }, allow_nil: true

  def as_json(options = {})
    super({ only: PUBLIC_ATTRIBUTES }.merge(options || {}))
  end
end
