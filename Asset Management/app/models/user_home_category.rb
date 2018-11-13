# frozen_string_literal: true

# == Schema Information
#
# Table name: user_home_categories
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  category_id :integer
#
# Indexes
#
#  index_user_home_categories_on_category_id  (category_id)
#  index_user_home_categories_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (user_id => users.id)
#

# User home category model
class UserHomeCategory < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :user, :category, presence: true

  scope :find_by_user, ->(user) { where user: user }

  def self.allowed_categories(user)
    Category.where.not(id: UserHomeCategory.select(:category_id).where(user: user))
  end
end
