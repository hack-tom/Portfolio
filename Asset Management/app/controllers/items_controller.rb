# frozen_string_literal: true

require 'irb'

# Item controller
class ItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /items
  def index
    # Get all items
    @items = Item.all

    # Pass category name to js
    gon.category = params[:category_name]
  end

  # GET /items/manager
  def manager
    # Failsafe for errors. Ensures a standard a standard user cannot see their "items" page.
    if params[:user_id].to_i == current_user.id && current_user.user?
      render 'errors/error_404'
    else
      # Get the user object for the given manager
      @manager = User.find_by_id(params[:user_id])

      # If the user selects the on loan tab, fill array with assets which are on booking or late.
      if params[:tab] == 'OnLoan'
        @bookings = Booking.joins(:item).where(status: %w[3 7], items: {user_id: current_user.id})
      # If the user selects issue tab, generate a list of items where the condition is low
      elsif params[:tab] == 'Issue'
        @items = Item.where(user_id: current_user.id, condition: %w[Damaged Missing])
      # Standard tab. Display all of a user's assets
      else
        @items = Item.where(user_id: params[:user_id])
      end
    end
  end

  # GET /items/1
  def show
    # Get bookings for a given item
    @bookings = Booking.joins(:user).where(item_id: @item.id)

    # If a peripheral, get the item's parents
    @parents = @item.get_item_parents

    # If an item has peipherals, fetch a list of them.
    @peripherals = @item.get_item_peripherals
  end

  # GET /items/1/add_peripheral_option
  def add_peripheral_option
    # Get the item that a peripheral will be added to
    @item = Item.find_by_id(params[:id])
  end

  # GET /items/1/choose_peripheral
  def choose_peripheral
    @item = Item.find_by_id(params[:id])

    # Get all items ellegible to have a peripheral added
    @items = Item.where.not(serial: @item.serial)

    # Validate these choices
    Item.all.each do |i|
      if !i.peripheral_items.where(parent_item_id: @item.id).blank? || !i.parent_items.where(peripheral_item_id: @item.id).blank?
        @items -= [i]
      end
    end
  end

  # POST /items/1/add_peripheral
  def add_peripheral
    # Get the item a peripheral will be added to
    @item = Item.find_by_id(params[:id])

    # Check a peripheral was selected
    if params[:item][:add_peripherals].length == 1
      redirect_to @item, warning: 'No peripheral was added.'
    else
      peripherals = params[:item][:add_peripherals]

      peripherals.each do |peripheral|
        unless peripheral.blank?
          # Find the selected peripheral item
          new_peripheral = Item.find_by_id(peripheral.to_i)
          # Create the allowed pair of peripheral and item
          pair = ItemPeripheral.create(parent_item_id: @item.id, peripheral_item_id: new_peripheral.id)

          # Save the pair and changes to the item.
          pair.save
        end
      end

      @item.save

      redirect_to @item, notice: 'Peripheral was successfully added'
    end
  end

  # GET /items/new
  def new
    # Get all items
    @items = Item.all

    # Pass parent item id to javascript where creating a peripheral
    unless params[:item_id].blank?
      @parent = Item.find_by(id: params[:item_id])
      gon.parent_id = params[:item_id]
    end
  end

  # GET /items/1/edit
  def edit
    # If this item is a peripheral of another
    if params[:is_peripheral] == 'true'
      # Get all other items
      @items = Item.where.not(id: @item.id)
      Item.all.each do |i|
        # Validate and return potential parent items
        unless i.peripheral_items.where(parent_item_id: @item.id).blank?
          @items = @items - [i]
        end
      end

      # Get an item's actual parents
      @parents = @item.get_item_parents

      # Send each of item's parent's ids to js
      gon.parent_id = []
      @parents.each do |parent|
        gon.parent_id.append(parent.id)
      end
    end
  end

  # POST /items
  def create
    # Create an object for the item being added to database
    @item = Item.new(item_params)

    # Set fields from form
    @item.user_id = current_user.id
    @item.serial = params[:item][:serial].upcase.strip
    @item.location = params[:item][:location].titleize.strip

    # try / catch for saving to database
    if @item.save
      # Add peripheral items
      unless params[:item][:is_peripheral].blank?
        # Get parent items
        parents = params[:item][:add_parents]

        #Set created item as peripheral item
        peripheral = @item.id

        # Loop through each parent item and create pairs of allowed peripherals recursively
        parents.each do |parent|
          unless parent.blank?
            pair = ItemPeripheral.create(parent_item_id: parent.to_i, peripheral_item_id: peripheral)
            pair.save
          end
        end
      end

      redirect_to @item, notice: 'Asset was successfully created.'
    else
      redirect_to request.referrer, alert: 'The serial is already in use or invalid information provided.'
    end
  end

  # PATCH/PUT /items/1
  def update
    @item.update(item_params)

    # Format location input on form
    @item.serial = params[:item][:serial].upcase.strip
    @item.location = params[:item][:location].titleize.strip

    # Update semi-dependent fields if item marked as retired
    if params[:item][:condition] == 'Retired' && @item.retired_date.blank?
      @item.retired_date = Date.today
    elsif params[:item][:condition] != 'Retired' && !@item.retired_date.blank?
      @item.retired_date = nil
    end

    # Save the item
    if @item.save

      # If the item has parents or peripherals update these too
      unless params[:item][:is_peripheral].blank?

        parents = params[:item][:add_parents]

        # Set @item as peripheral variable
        peripheral = @item.id

        # Get the original parents before record updated
        original_parents = @item.get_item_parents
        deleted_parents = original_parents

        # For each parent item create new paits of peripheral and item
        # Remove pairs for deleted peripherals/parents
        parents.each do |parent|
          unless parent.blank?
            new_parent = Item.find(parent.to_i)

            # Remove old parents
            unless deleted_parents.blank?
              deleted_parents -= [new_parent]
            end

            # Create recursive peripheral pairings
            unless @item.get_item_parents.include? new_parent
              pair = ItemPeripheral.create(parent_item_id: parent.to_i, peripheral_item_id: peripheral)
              pair.save
            end
          end
        end

        deleted_parents.each do |deleted_parent|
          ItemPeripheral.where(parent_item_id: deleted_parent.id, peripheral_item_id: peripheral).first.destroy
        end
      end
      redirect_to @item, notice: 'Asset was successfully updated.'
    else
      redirect_to request.referrer, alert: 'Serial already exist or invalid information provided'
    end
  end

  # DELETE /items/1
  def destroy
    @item.destroy
    redirect_to items_path, notice: 'Asset was successfully deleted.'
  end

  # GET /items/change_manager_multiple
  def change_manager_multiple
    # Used by simpleform as selected entities will be objects.
    @item = Item.new
    # Show users who have sufficient permissions and are not the current user as options
    @allowed_user = User.where.not(id: current_user.id, permission_id: 1)
  end

  # POST /items/change_manager_multiple
  def update_manager_multiple
    # Get the ids of selected items on previous page
    item_ids = params[:item][:item_id_list].split(' ')

    # Get items from db using this id
    @items = Item.where(id: item_ids)

    # Update the owner of each of these items
    @items.each do |item|
      item.user_id = params[:item][:user_id]
      item.save
    end

    redirect_to manager_items_path(user_id: current_user.id), notice: 'Ownership was successfully transfered.'
  end

  # GET /items/change_manager_multiple
  def change_manager_multiple_and_delete
    # Used by simpleform as selected entities will be objects.
    @item = Item.new
    @user = User.find_by_id(params[:user_id])
    # Get a list of users that can be transferred to
    @allowed_user = User.where.not(id: params[:user_id], permission_id: 1)
  end

  # POST /items/change_manager_multiple
  def update_manager_multiple_and_delete
    # Get items belonging to the user being deleted
    @items = Item.where(user_id: params[:item][:old_id])

    # Transfer each item to a new owner and save it
    @items.each do |item|
      item.user_id = params[:item][:user_id]
      item.save
    end

    # Get the original owner of the assets
    @user = User.find(params[:item][:old_id])

    # Finally destroy the user
    if @user.destroy
      redirect_to users_path, notice: 'User was successfully deleted.'
    end
  end

  # GET /items/import
  def import; end

  # POST /items/import_file
  def import_file

    # Get import file
    excel_import = Importers::ItemImporter.new(params[:import_file][:file].tempfile.path)
    res = excel_import.import(current_user)

    # Error message 0
    if res[0].zero?
      redirect_to import_items_path, alert: 'The submitted file is not of file .xlsx format'
    # Error message 1
    elsif res[0] == 1
      redirect_to import_items_path, alert: 'Headers of excel sheet do not match appropriate format'
    elsif res[0] == 2
      incorrect_rows = res[1]
      if incorrect_rows.blank?
        redirect_to import_items_path, notice: 'Import was successful and no problems occured'
      else
        redirect_to controller: 'items', action: 'import', incorrect_rows: incorrect_rows, alert: 'Import was partially successful, view rows that had problems below'
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_item
    @item = Item.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def item_params
    params.require(:item).except(:bunny).permit!
  end
end
