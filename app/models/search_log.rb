class SearchLog < ApplicationRecord
  belongs_to :user, optional: true
  validates :departure_location, :arrival_location, :region, presence: true
end
