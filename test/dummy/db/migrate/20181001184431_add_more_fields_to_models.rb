class AddMoreFieldsToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :col_int, :integer
    add_column :items, :col_int, :integer
    add_column :widgets, :col_int, :integer
    add_column :sub_widgets, :col_int, :integer
    add_column :user_profiles, :col_int, :integer
    add_column :item_descriptions, :col_int, :integer

    add_column :users, :col_float, :float
    add_column :items, :col_float, :float
    add_column :widgets, :col_float, :float
    add_column :sub_widgets, :col_float, :float
    add_column :user_profiles, :col_float, :float
    add_column :item_descriptions, :col_float, :float

    add_column :users, :col_string, :string
    add_column :items, :col_string, :string
    add_column :widgets, :col_string, :string
    add_column :sub_widgets, :col_string, :string
    add_column :user_profiles, :col_string, :string
    add_column :item_descriptions, :col_string, :string
  end
end
