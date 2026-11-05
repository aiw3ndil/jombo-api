# Confianza y seguridad: reportes de usuarios, bloqueos y viajes cancelados por el conductor
class CreateReportsAndBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reported, null: false, foreign_key: { to_table: :users }
      t.references :booking, foreign_key: true
      t.string :reason, null: false
      t.text :comment
      t.timestamps
    end

    create_table :blocks do |t|
      t.references :blocker, null: false, foreign_key: { to_table: :users }
      t.references :blocked, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :blocks, %i[blocker_id blocked_id], unique: true

    add_column :trips, :cancelled_at, :datetime
    add_index :trips, :cancelled_at
  end
end
