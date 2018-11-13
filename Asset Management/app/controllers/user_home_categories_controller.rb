# frozen_string_literal: true

# User home categories controller
class UserHomeCategoriesController < ApplicationController
  before_action :set_user_home_category, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /user_home_categories
  def index
    @user_home_categories = UserHomeCategory.where(user: current_user)
  end

  # GET /user_home_categories/new
  def new
    # Get categories that can be set as a favourite
    @allowed = UserHomeCategory.allowed_categories(current_user)
  end

  # POST /user_home_categories
  def create
    # Save and redirect back to homepage
    redirect_to root_path, notice: 'Favourite category successfully added.' if @user_home_category.save
  end

  # DELETE /user_home_categories/1
  def destroy
    # Destroy category
    @user_home_category.destroy
    redirect_to user_home_categories_url, notice: 'Favourite category successfully removed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user_home_category
    @user_home_category = UserHomeCategory.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def user_home_category_params
    params.require(:user_home_category).permit(:user_id, :category_id)
  end
end
