class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.integer :seats, null: false, default: 1
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
    
    add_index :bookings, [:user_id, :trip_id]
  end
end
