require 'rails_helper'

RSpec.describe Vehicle, type: :model do
  subject { build(:vehicle) }

  it { should belong_to(:user) }
  it { should have_many(:trips).dependent(:nullify) }
  it { should validate_presence_of(:brand) }
  it { should validate_presence_of(:model) }
  it { should validate_presence_of(:color) }
  it { should validate_inclusion_of(:vehicle_type).in_array(Vehicle::VEHICLE_TYPES) }
  it { should validate_numericality_of(:doors).only_integer.is_greater_than_or_equal_to(2).is_less_than_or_equal_to(5) }
  it { should validate_numericality_of(:seats).only_integer.is_greater_than_or_equal_to(2).is_less_than_or_equal_to(9) }

  it 'allows a blank fuel type' do
    expect(build(:vehicle, fuel_type: nil)).to be_valid
  end

  it 'rejects an unknown fuel type' do
    expect(build(:vehicle, fuel_type: 'steam')).not_to be_valid
  end
end
