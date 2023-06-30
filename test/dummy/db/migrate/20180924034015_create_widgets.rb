# frozen_string_literal: true

class CreateWidgets < ActiveRecord::Migration[5.2]
  def change
    create_table :widgets do |t|
      t.references :user

      t.timestamps
    end
  end
end
