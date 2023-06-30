# frozen_string_literal: true

class CreateSingleDateTimeAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :single_date_time_attributes do |t|
      t.datetime :single_attr
      t.timestamps
    end
  end
end
