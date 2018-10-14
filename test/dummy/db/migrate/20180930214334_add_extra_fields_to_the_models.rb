class AddExtraFieldsToTheModels < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :name, :string
    add_column :users, :email, :string
    add_column :items, :name, :string
    add_column :widgets, :name, :string
    add_column :user_profiles, :name, :string
  end
end
