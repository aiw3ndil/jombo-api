class AddRegionToUsersAndTrips < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :region, :string
    add_column :trips, :region, :string
    add_index :users, :region
    add_index :trips, :region
  end
end
