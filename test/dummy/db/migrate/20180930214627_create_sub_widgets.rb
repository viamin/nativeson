class CreateSubWidgets < ActiveRecord::Migration[5.2]
  def change
    create_table :sub_widgets do |t|
      t.string :name
      t.references :widget
      t.timestamps
    end
  end
end
