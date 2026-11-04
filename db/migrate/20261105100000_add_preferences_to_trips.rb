class AddPreferencesToTrips < ActiveRecord::Migration[7.1]
  def change
    change_table :trips, bulk: true do |t|
      t.boolean :instant_booking, null: false, default: false
      t.boolean :pets_allowed, null: false, default: false
      t.boolean :smoking_allowed, null: false, default: false
      t.boolean :music_allowed, null: false, default: false
      t.boolean :max_two_back, null: false, default: false
      t.string :chattiness, null: false, default: 'normal'
      t.string :luggage_size, null: false, default: 'medium'
      t.integer :distance_km
      t.integer :duration_minutes
    end
  end
end
