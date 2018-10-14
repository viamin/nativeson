class AddKlassColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :klass, :string, default: 'User'
    add_column :items, :klass, :string, default: 'Item'
    add_column :item_descriptions, :klass, :string, default: 'ItemDescription'
    add_column :item_prices, :klass, :string, default: 'ItemPrice'
    add_column :widgets, :klass, :string, default: 'Widget'
    add_column :sub_widgets, :klass, :string, default: 'SubWidget'
    add_column :user_profiles, :klass, :string, default: 'UserProfile'
    add_column :user_profile_pics, :klass, :string, default: 'UserProfilePic'
  end
end
