class AddProfileAndVerificationToUsers < ActiveRecord::Migration[7.1]
  def up
    change_table :users, bulk: true do |t|
      t.text :bio
      t.string :phone
      t.datetime :phone_verified_at
      t.string :phone_verification_code_digest
      t.datetime :phone_verification_sent_at
      t.integer :phone_verification_attempts, null: false, default: 0
      t.datetime :email_verified_at
      t.string :email_verification_token
    end
    add_index :users, :email_verification_token, unique: true

    # Las cuentas de Google ya tienen el email verificado por el proveedor
    execute "UPDATE users SET email_verified_at = created_at WHERE provider = 'google'"
  end

  def down
    remove_index :users, :email_verification_token
    change_table :users, bulk: true do |t|
      t.remove :bio, :phone, :phone_verified_at, :phone_verification_code_digest, :phone_verification_sent_at,
               :phone_verification_attempts, :email_verified_at, :email_verification_token
    end
  end
end
