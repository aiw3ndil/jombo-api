class CreateTripStops < ActiveRecord::Migration[7.1]
  def change
    create_table :trip_stops do |t|
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.string :location, null: false
      t.integer :position, null: false
      t.datetime :departure_time, null: false
      t.decimal :price_from_origin, precision: 8, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :trip_stops, [:trip_id, :position], unique: true
    add_index :trip_stops, :location

    change_table :bookings, bulk: true do |t|
      t.string :pickup_location
      t.string :dropoff_location
      t.decimal :price_per_seat, precision: 8, scale: 2
    end
  end
end
