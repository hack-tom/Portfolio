# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                 :integer          not null, primary key
#  phone              :string
#  permission_id      :integer
#  email              :string           default(""), not null
#  sign_in_count      :integer          default(0), not null
#  current_sign_in_at :datetime
#  last_sign_in_at    :datetime
#  current_sign_in_ip :inet
#  last_sign_in_ip    :inet
#  username           :string
#  uid                :string
#  mail               :string
#  ou                 :string
#  dn                 :string
#  sn                 :string
#  givenname          :string
#
# Indexes
#
#  index_users_on_email     (email) UNIQUE
#  index_users_on_username  (username)
#

# User model
class User < ApplicationRecord
  include EpiCas::DeviseHelper

  has_many :combined_bookings, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :items, dependent: :destroy
  has_many :user_home_categories, dependent: :destroy
  has_many :categories, through: :user_home_categories
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy

  validates_format_of :phone, with: /\A([1-9])([0-9]{9})\z/, allow_blank: true
  validates :email, :username, presence: true, uniqueness: true
  validates :permission_id, presence: true

  def generate_attributes_from_ldap_info
    self.username = uid
    self.email = mail
    super # This needs to be left in so the default fields are also set
  end

  def user?
    permission_id == 1
  end

  def asset_manager?
    permission_id == 2
  end

  def admin?
    permission_id == 3
  end

  def no_asset?
    items.blank?
  end
end
