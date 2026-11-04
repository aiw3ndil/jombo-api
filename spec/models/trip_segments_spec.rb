require 'rails_helper'

RSpec.describe Trip, 'stops, segments and pricing', type: :model do
  let(:departure) { 2.days.from_now.change(hour: 8) }
  let(:trip) do
    build(:trip, departure_location: 'Helsinki', arrival_location: 'Oulu', price: 40,
                 departure_time: departure, distance_km: 600, duration_minutes: 400).tap do |t|
      t.assign_stops([
        { location: 'Tampere', departure_time: departure + 2.hours, price_from_origin: 12 },
        { location: 'Jyväskylä', departure_time: departure + 4.hours, price_from_origin: 22 }
      ])
      t.save!
    end
  end

  it 'lists the ordered points of the route' do
    expect(trip.points.map { |p| p[:location] }).to eq(%w[Helsinki Tampere Jyväskylä Oulu])
  end

  it 'returns the full route when no places are given' do
    segment = trip.segment_for
    expect(segment).to include(from: 'Helsinki', to: 'Oulu', price: 40.0, partial: false)
  end

  it 'computes a partial segment price' do
    segment = trip.segment_for('tampere', 'oulu')
    expect(segment).to include(from: 'Tampere', to: 'Oulu', price: 28.0, partial: true)
    expect(segment[:departure_time]).to be_within(1.second).of(departure + 2.hours)
  end

  it 'returns nil when the places are in the wrong order' do
    expect(trip.segment_for('Oulu', 'Tampere')).to be_nil
  end

  it 'replaces stops keeping positions in order' do
    trip.assign_stops([{ location: 'Lahti', departure_time: departure + 1.hour, price_from_origin: 8 }])
    trip.save!
    expect(trip.reload.stops.map(&:location)).to eq(['Lahti'])
    expect(trip.stops.first.position).to eq(1)
  end

  it 'rejects stops out of chronological order' do
    trip.assign_stops([
      { location: 'Tampere', departure_time: departure + 3.hours, price_from_origin: 12 },
      { location: 'Lahti', departure_time: departure + 1.hour, price_from_origin: 15 }
    ])
    expect(trip).not_to be_valid
    expect(trip.errors[:stops]).to be_present
  end

  it 'rejects prices above the cost-sharing maximum' do
    trip.price = 200
    expect(trip).not_to be_valid
    expect(trip.errors[:price].first).to include('cost-sharing')
  end

  it 'suggests a price from the distance' do
    expect(trip.suggested_price).to eq(39)
    expect(Trip.max_price_for(100)).to eq(12)
  end

  it 'validates preference values' do
    trip.chattiness = 'loud'
    expect(trip).not_to be_valid
  end

  it 'copies stops and preferences to recurring trips' do
    parent = build(:trip, departure_time: departure, is_recurring: true, recurrence_pattern: 'daily',
                          recurrence_until: departure + 2.days, pets_allowed: true, price: 20)
    parent.assign_stops([{ location: 'Lahti', departure_time: departure + 1.hour, price_from_origin: 5 }])
    parent.save!
    copies = Trip.where(parent_id: parent.id)
    expect(copies.count).to eq(2)
    expect(copies.all?(&:pets_allowed)).to be(true)
    expect(copies.first.stops.first.departure_time).to be_within(1.second).of(copies.first.departure_time + 1.hour)
  end
end
