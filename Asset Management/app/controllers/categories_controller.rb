# frozen_string_literal: true

# Categories controller
class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /categories
  def index
    @categories = Category.all
  end

  # GET /categories/filter
  def filter
    @categories = Category.all
  end

  # GET /categories/new
  def new
    @category = Category.new
  end

  # POST /categories/new
  def new_peripheral
    # Get the caregory the peripheral category should belong to
    parent_category = Category.find_by_id(params[:id])
    # Mark the category as having a peripheral category.
    parent_category.has_peripheral = 1

    # Deep copy category
    category = Category.find_by_id(params[:id]).dup
    # Add peripherals to end of name
    category.name = category.name.humanize.gsub(/\b('?[a-z])/) { Regexp.last_match(1).capitalize }.strip + ' - Peripherals'

    # Format icon tag correctly for database and set in record
    if (!category.icon.include? 'material-icons') && !category.icon.empty?
      category.icon = category.icon.chomp('"></i>') + ' fa-6x"></i><i class="material-icons">P</i>'
    else
      category.icon = category.icon.chomp('</i>') + 'P</i>' unless category.icon.empty?
    end

    # Set whether categories have peripheral categories
    category.is_peripheral = 1
    category.has_peripheral = 0

    # Save the categories
    if category.save && parent_category.save
      redirect_to categories_path, notice: 'Peripheral category successfully created'
    end
  end

  # GET /categories/1/edit
  def edit; end

  # POST /categories
  def create
    @category = Category.new(category_params)

    # Checks whether the category already exists
    if Category.exists?(name: @category.name.titleize.strip)
      redirect_to new_category_path, alert: 'Category already exists.'

    # If category doesn't exist
    elsif @category.name =~ /^[a-zA-Z0-9 _.,!()+=`,"&@$#%*-]{4,50}$/

      # Set its name and format
      @category.name = @category.name.humanize.gsub(/\b('?[a-z])/) { Regexp.last_match(1).capitalize }.strip

      # Font awesome icon
      if (!@category.icon.include? 'material-icons') && !@category.icon.empty?
        @category.icon = @category.icon.chomp('"></i>') + ' fa-6x"></i>'
      end

      # Set that category does not have or is not a peripheral category
      @category.is_peripheral = 0
      @category.has_peripheral = 0

      # Create a duplicate category for the new category's peripherals
      if params[:want_peripheral].to_i == 1

        # Set category as having a peripheral category
        @category.has_peripheral = 1

        # Create the child/peripheral category
        category = Category.new(category_params)
        category.name = @category.name + ' - Peripherals'

        # Format icon tag
        if (!category.icon.include? 'material-icons') && !category.icon.empty?
          category.icon = @category.icon.chomp('"></i>') + ' fa-6x"></i><i class="material-icons">P</i>'
        else
          category.icon = @category.icon.chomp('</i>') + 'P</i>'
        end

        # Set whether categories have peripheral categories
        category.is_peripheral = 1
        category.has_peripheral = 0

        # Save the created category
        category.save
      end

      # Save the new category and handle errors
      if @category.save
        redirect_to categories_path, notice: 'Category was successfully created.'
      end
    else
      redirect_to new_category_path, alert: 'Category name does not meet requirements.'
    end
  end

  # PATCH/PUT /categories/1
  def update
    @category.update(category_params)
    redirect_to categories_path, notice: 'Category was successfully updated.'
  rescue StandardError
    redirect_to request.referrer, alert: 'Category already exist.'
  end

  # DELETE /categories/1
  def destroy
    # Get items in the category
    items = Item.where(category_id: @category.id)

    if items.blank?
      # Delete user favourites which belong to this category
      UserHomeCategory.where(category_id: @category.id).destroy_all

      begin
        # Destroy child/peripheral category
        if @category.is_peripheral
          parent_category = Category.where(name: @category.name[0..-15]).first
          parent_category.has_peripheral = 0
          parent_category.save
        end
        # Delete the category
        @category.destroy
        redirect_to categories_url, notice: 'Category was successfully deleted.'
      end
    else
      redirect_to categories_path, alert: 'Cannot delete category because it is currently in use for an asset.'
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_category
    @category = Category.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def category_params
    params.require(:category).permit!
  end
end
