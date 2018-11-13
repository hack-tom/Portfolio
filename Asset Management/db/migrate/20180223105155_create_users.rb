class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string  :phone
      t.integer :permission_id
    end
  end
end
