class CreateUserHomeCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :user_home_categories do |t|
      t.references :user, foreign_key: true
      t.references :category, foreign_key: true
    end
  end
end
