class CreateSingleFloatAttributes < ActiveRecord::Migration[5.2]
  def change
    create_table :single_float_attributes do |t|
      t.float :single_attr
      t.timestamps
    end
  end
end
