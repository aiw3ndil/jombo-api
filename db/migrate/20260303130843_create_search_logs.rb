class CreateSearchLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :search_logs do |t|
      t.string :departure_location
      t.string :arrival_location
      t.string :region
      t.integer :user_id

      t.timestamps
    end
  end
end
