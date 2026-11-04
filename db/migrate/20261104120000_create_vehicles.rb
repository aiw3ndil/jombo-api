class CreateVehicles < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :brand, null: false
      t.string :model, null: false
      t.string :vehicle_type, null: false
      t.string :color, null: false
      t.integer :doors, null: false
      t.integer :seats, null: false
      t.integer :year
      t.string :fuel_type
      t.timestamps
    end

    add_reference :trips, :vehicle, foreign_key: { on_delete: :nullify }
  end
end
