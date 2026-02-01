class AddUrlToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :url, :string
  end
end
