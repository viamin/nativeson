# frozen_string_literal: true

class CreateSingleIntegerAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :single_integer_attributes do |t|
      t.integer :single_attr
      t.timestamps
    end
  end
end
