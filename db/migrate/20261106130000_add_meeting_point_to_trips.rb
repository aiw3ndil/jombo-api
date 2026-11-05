# Punto de encuentro exacto elegido por el conductor (público)
class AddMeetingPointToTrips < ActiveRecord::Migration[7.1]
  def change
    change_table :trips, bulk: true do |t|
      t.string :meeting_point
      t.decimal :meeting_lat, precision: 10, scale: 7
      t.decimal :meeting_lng, precision: 10, scale: 7
    end
  end
end
