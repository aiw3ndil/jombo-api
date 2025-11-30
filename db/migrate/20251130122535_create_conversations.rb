class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :trip, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
