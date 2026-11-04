class FinlandOnlyRegion < ActiveRecord::Migration[7.1]
  # Jombo now operates only in Finland: every user belongs to the "fi" region
  # and Spanish ("es") is no longer an available language.
  def up
    execute "UPDATE users SET region = 'fi' WHERE region IS NULL OR region <> 'fi'"
    execute "UPDATE users SET language = 'en' WHERE language IS NULL OR language NOT IN ('en', 'fi')"
    change_column_default :users, :region, from: nil, to: 'fi'
    change_column_default :trips, :region, from: nil, to: 'fi'
  end

  def down
    change_column_default :users, :region, from: 'fi', to: nil
    change_column_default :trips, :region, from: 'fi', to: nil
  end
end
