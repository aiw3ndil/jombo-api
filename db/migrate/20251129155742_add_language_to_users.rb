class AddLanguageToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :language, :string, default: 'en', null: false
    
    # Actualizar usuarios existentes al idioma inglés por defecto
    reversible do |dir|
      dir.up do
        User.update_all(language: 'en')
      end
    end
  end
end
