class AddUniqueIndexToHasOne < ActiveRecord::Migration[5.2]
  def change
    remove_index :user_profiles, :user_id
    add_index :user_profiles, :user_id, unique: true
    remove_index :user_profile_pics, :user_profile_id
    add_index :user_profile_pics, :user_profile_id, unique: true
    remove_index :item_descriptions, :item_id
    add_index :item_descriptions, :item_id, unique: true
  end
end
