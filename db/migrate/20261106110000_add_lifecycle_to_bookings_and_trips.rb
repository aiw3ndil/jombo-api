# Ciclo de vida de reservas y viajes: respuestas, cancelaciones, recordatorios y valoraciones
class AddLifecycleToBookingsAndTrips < ActiveRecord::Migration[7.1]
  def change
    change_table :bookings, bulk: true do |t|
      t.datetime :responded_at
      t.datetime :cancelled_at
      t.string :cancelled_by
      t.datetime :reminder_sent_at
      t.datetime :review_requested_at
    end
    add_index :bookings, :status

    add_column :trips, :reminder_sent_at, :datetime
  end
end
