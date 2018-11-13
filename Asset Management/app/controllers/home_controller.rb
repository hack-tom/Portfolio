# frozen_string_literal: true

require 'irb'

# Home controller
class HomeController < ApplicationController
  def index
    # Load the user's favourites
    @user_home_categories = UserHomeCategory.find_by_user(current_user)

    # Load data for search bar autocomplete
    @autocomplete = [
      Item.name_serial,
      Item.manufacturer_uniq,
      Category.all_name
    ].reduce([], :concat).to_s.tr('[]"', '')

    render layout: 'application'
  end
end
