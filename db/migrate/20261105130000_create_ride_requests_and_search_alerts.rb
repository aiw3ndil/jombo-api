class CreateRideRequestsAndSearchAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :ride_requests do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :departure_location, null: false
      t.string :arrival_location, null: false
      t.date :departure_date, null: false
      t.integer :flexible_days, null: false, default: 0
      t.integer :seats, null: false, default: 1
      t.decimal :max_price, precision: 8, scale: 2
      t.text :note
      t.string :status, null: false, default: 'open'
      t.timestamps
    end
    add_index :ride_requests, [:status, :departure_date]

    create_table :search_alerts do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :departure_location, null: false
      t.string :arrival_location, null: false
      t.date :date
      t.boolean :active, null: false, default: true
      t.datetime :last_notified_at
      t.timestamps
    end
    add_index :search_alerts, [:user_id, :departure_location, :arrival_location, :date],
              unique: true, name: 'index_search_alerts_uniqueness'
    add_index :search_alerts, :active
  end
end
