# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id             :integer          not null, primary key
#  name           :string
#  icon           :string
#  has_peripheral :boolean
#  is_peripheral  :boolean
#
# Indexes
#
#  index_categories_on_name  (name) UNIQUE
#

# Category model
class Category < ApplicationRecord
  has_many :items
  has_many :user_home_categories
  has_many :users, through: :user_home_categories

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }

  scope :all_name, -> { pluck(:name) }
end
