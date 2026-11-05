# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_11_06_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "trip_id", null: false
    t.integer "seats", default: 1, null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pickup_location"
    t.string "dropoff_location"
    t.decimal "price_per_seat", precision: 8, scale: 2
    t.index ["trip_id"], name: "index_bookings_on_trip_id"
    t.index ["user_id", "trip_id"], name: "index_bookings_on_user_id_and_trip_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_participants_on_conversation_and_user", unique: true
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_conversations_on_trip_id", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notification_type", null: false
    t.string "title", null: false
    t.text "content"
    t.boolean "read", default: false, null: false
    t.string "email_type"
    t.integer "related_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.bigint "reviewer_id", null: false
    t.bigint "reviewee_id", null: false
    t.integer "rating", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id", "reviewer_id"], name: "index_reviews_on_booking_id_and_reviewer_id", unique: true
    t.index ["booking_id"], name: "index_reviews_on_booking_id"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
  end

  create_table "ride_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "departure_location", null: false
    t.string "arrival_location", null: false
    t.date "departure_date", null: false
    t.integer "flexible_days", default: 0, null: false
    t.integer "seats", default: 1, null: false
    t.decimal "max_price", precision: 8, scale: 2
    t.text "note"
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status", "departure_date"], name: "index_ride_requests_on_status_and_departure_date"
    t.index ["user_id"], name: "index_ride_requests_on_user_id"
  end

  create_table "search_alerts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "departure_location", null: false
    t.string "arrival_location", null: false
    t.date "date"
    t.boolean "active", default: true, null: false
    t.datetime "last_notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_search_alerts_on_active"
    t.index ["user_id", "departure_location", "arrival_location", "date"], name: "index_search_alerts_uniqueness", unique: true
    t.index ["user_id"], name: "index_search_alerts_on_user_id"
  end

  create_table "search_logs", force: :cascade do |t|
    t.string "departure_location"
    t.string "arrival_location"
    t.string "region"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trip_stops", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.string "location", null: false
    t.integer "position", null: false
    t.datetime "departure_time", null: false
    t.decimal "price_from_origin", precision: 8, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location"], name: "index_trip_stops_on_location"
    t.index ["trip_id", "position"], name: "index_trip_stops_on_trip_id_and_position", unique: true
    t.index ["trip_id"], name: "index_trip_stops_on_trip_id"
  end

  create_table "trips", force: :cascade do |t|
    t.string "departure_location"
    t.string "arrival_location"
    t.datetime "departure_time"
    t.integer "available_seats"
    t.decimal "price"
    t.integer "driver_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "region", default: "fi"
    t.boolean "is_recurring", default: false
    t.string "recurrence_pattern"
    t.string "recurrence_days"
    t.datetime "recurrence_until"
    t.integer "parent_id"
    t.bigint "vehicle_id"
    t.boolean "instant_booking", default: false, null: false
    t.boolean "pets_allowed", default: false, null: false
    t.boolean "smoking_allowed", default: false, null: false
    t.boolean "music_allowed", default: false, null: false
    t.boolean "max_two_back", default: false, null: false
    t.string "chattiness", default: "normal", null: false
    t.string "luggage_size", default: "medium", null: false
    t.integer "distance_km"
    t.integer "duration_minutes"
    t.index ["driver_id"], name: "index_trips_on_driver_id"
    t.index ["parent_id"], name: "index_trips_on_parent_id"
    t.index ["region"], name: "index_trips_on_region"
    t.index ["vehicle_id"], name: "index_trips_on_vehicle_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language", default: "en", null: false
    t.string "picture"
    t.string "provider"
    t.string "uid"
    t.string "region", default: "fi"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.text "bio"
    t.datetime "email_verified_at"
    t.string "email_verification_token"
    t.index ["email_verification_token"], name: "index_users_on_email_verification_token", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["region"], name: "index_users_on_region"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "brand", null: false
    t.string "model", null: false
    t.string "vehicle_type", null: false
    t.string "color", null: false
    t.integer "doors", null: false
    t.integer "seats", null: false
    t.integer "year"
    t.string "fuel_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_vehicles_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookings", "trips"
  add_foreign_key "bookings", "users"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "conversation_participants", "users"
  add_foreign_key "conversations", "trips"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "reviews", "bookings"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "ride_requests", "users", on_delete: :cascade
  add_foreign_key "search_alerts", "users", on_delete: :cascade
  add_foreign_key "trip_stops", "trips", on_delete: :cascade
  add_foreign_key "trips", "vehicles", on_delete: :nullify
  add_foreign_key "vehicles", "users"
end
