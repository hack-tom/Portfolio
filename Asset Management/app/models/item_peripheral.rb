# frozen_string_literal: true
# == Schema Information
#
# Table name: item_peripherals
#
#  id                 :integer          not null, primary key
#  parent_item_id     :integer
#  peripheral_item_id :integer
#
# Indexes
#
#  index_item_peripherals_on_parent_item_id                         (parent_item_id)
#  index_item_peripherals_on_parent_item_id_and_peripheral_item_id  (parent_item_id,peripheral_item_id) UNIQUE
#  index_item_peripherals_on_peripheral_item_id                     (peripheral_item_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_item_id => items.id)
#  fk_rails_...  (peripheral_item_id => items.id)
#

# Item Peripheral model
class ItemPeripheral < ApplicationRecord
  belongs_to :parent_item, class_name: 'Item'
  belongs_to :peripheral_item, class_name: 'Item'

  validates :parent_item, :peripheral_item, presence: true
  validates_uniqueness_of :parent_item, scope: :peripheral_item
end
