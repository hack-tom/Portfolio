class CreateItemPeripheral < ActiveRecord::Migration[5.1]
  def change
    create_table :item_peripherals do |t|
      t.references :parent_item
      t.references :peripheral_item
    end

    add_index :item_peripherals, [:parent_item_id, :peripheral_item_id], unique: true
    add_foreign_key :item_peripherals, :items, column: :parent_item_id, primary_key: :id
    add_foreign_key :item_peripherals, :items, column: :peripheral_item_id, primary_key: :id
  end
end
