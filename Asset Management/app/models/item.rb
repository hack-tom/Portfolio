# frozen_string_literal: true

# == Schema Information
#
# Table name: items
#
#  id               :integer          not null, primary key
#  name             :string
#  condition        :string
#  location         :string
#  manufacturer     :string
#  model            :string
#  serial           :string
#  acquisition_date :date
#  purchase_price   :decimal(, )
#  image            :string
#  keywords         :string
#  po_number        :string
#  condition_info   :string
#  comment          :string
#  retired_date     :date
#  user_id          :integer
#  category_id      :integer
#
# Indexes
#
#  index_items_on_category_id  (category_id)
#  index_items_on_serial       (serial) UNIQUE
#  index_items_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (category_id => categories.id)
#  fk_rails_...  (user_id => users.id)
#

# Item model
class Item < ApplicationRecord
  attr_accessor :add_parents
  attr_accessor :add_peripherals
  attr_accessor :is_peripheral

  belongs_to :category
  belongs_to :user
  has_many :bookings, dependent: :destroy
  has_many :combined_bookings, through: :bookings, dependent: :destroy
  has_many :parent_items, class_name: 'ItemPeripheral', foreign_key: :parent_item_id, dependent: :destroy
  has_many :peripheral_items, class_name: 'ItemPeripheral', foreign_key: :peripheral_item_id, dependent: :destroy

  validates :name, :condition, :location, :category, :user, presence: true
  validates :serial, presence: true, uniqueness: true

  scope :name_serial, -> { pluck(:name, :serial) }
  scope :manufacturer_uniq, -> { pluck(:manufacturer).uniq }

  mount_uploader :image, ImageUploader

  def available?
    bookings.ongoing.blank?
  end

  def get_item_peripherals
    peripherals_for_item = ItemPeripheral.where(parent_item: self)
    peripherals_for_item.map(&:peripheral_item)
  end

  def get_item_parents
    parents_for_item = ItemPeripheral.where(peripheral_item: self)
    parents_for_item.map(&:parent_item)
  end
end
