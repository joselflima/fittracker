class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :display_name, :string
    add_column :users, :birth_date, :date
    add_column :users, :weight_kg, :decimal
    add_column :users, :height_cm, :decimal
  end
end
