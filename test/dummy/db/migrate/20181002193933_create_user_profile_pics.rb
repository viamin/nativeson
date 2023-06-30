# frozen_string_literal: true

class CreateUserProfilePics < ActiveRecord::Migration[5.2]
  def change
    create_table :user_profile_pics do |t|
      t.references :user_profile
      t.string :image_url
      t.integer :image_width
      t.integer :image_height
      t.timestamps
    end
  end
end
