# frozen_string_literal: true

class CreateSingleStringAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :single_string_attributes do |t|
      t.string :single_attr
      t.timestamps
    end
  end
end
