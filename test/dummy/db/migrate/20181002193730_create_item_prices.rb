# frozen_string_literal: true

class CreateItemPrices < ActiveRecord::Migration[5.2]
  def change
    create_table :item_prices do |t|
      t.references :item
      t.float :current_price
      t.float :previous_price
      t.timestamps
    end
  end
end
