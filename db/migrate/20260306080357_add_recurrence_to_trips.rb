class AddRecurrenceToTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :trips, :is_recurring, :boolean, default: false
    add_column :trips, :recurrence_pattern, :string
    add_column :trips, :recurrence_days, :string
    add_column :trips, :recurrence_until, :datetime
    add_column :trips, :parent_id, :integer
    add_index :trips, :parent_id
  end
end
