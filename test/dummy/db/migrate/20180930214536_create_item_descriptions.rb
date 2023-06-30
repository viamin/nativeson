# frozen_string_literal: true

class CreateItemDescriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :item_descriptions do |t|
      t.references :item
      t.string :description
      t.timestamps
    end
  end
end
