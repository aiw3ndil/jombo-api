# La verificación por SMS se ha eliminado: solo se verifica el email
class RemovePhoneVerificationFromUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.remove :phone, type: :string
      t.remove :phone_verified_at, type: :datetime
      t.remove :phone_verification_code_digest, type: :string
      t.remove :phone_verification_sent_at, type: :datetime
      t.remove :phone_verification_attempts, type: :integer, null: false, default: 0
    end
  end
end
