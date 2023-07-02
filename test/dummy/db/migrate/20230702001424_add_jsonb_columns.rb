# frozen_string_literal: true

class AddJsonbColumns < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :permissions, :jsonb
    add_column :items, :product_codes, :jsonb
  end
end
