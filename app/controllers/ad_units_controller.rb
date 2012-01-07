class AdUnitsController < ApplicationController
  require 'dfp_api'

  # GET /ad_units
  # GET /ad_units.json
  def index
    @ad_units = AdUnit.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ad_units }
    end
  end

  # GET /ad_units/1
  # GET /ad_units/1.json
  def show
    @ad_unit = AdUnit.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ad_unit }
    end
  end

  # GET /ad_units/new
  # GET /ad_units/new.json
  def new
    @ad_unit = AdUnit.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ad_unit }
    end
  end

  # GET /ad_units/1/edit
  def edit
    @ad_unit = AdUnit.find(params[:id])
  end

  # POST /ad_units
  # POST /ad_units.json
  def create
    @ad_unit = AdUnit.new(params[:ad_unit])

    respond_to do |format|
      if @ad_unit.save
        format.html { redirect_to @ad_unit, notice: 'Ad unit was successfully created.' }
        format.json { render json: @ad_unit, status: :created, location: @ad_unit }
      else
        format.html { render action: "new" }
        format.json { render json: @ad_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ad_units/1
  # PUT /ad_units/1.json
  def update
    @ad_unit = AdUnit.find(params[:id])

    respond_to do |format|
      if @ad_unit.update_attributes(params[:ad_unit])
        format.html { redirect_to @ad_unit, notice: 'Ad unit was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @ad_unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ad_units/1
  # DELETE /ad_units/1.json
  def destroy
    @ad_unit = AdUnit.find(params[:id])
    @ad_unit.destroy

    respond_to do |format|
      format.html { redirect_to ad_units_url }
      format.json { head :ok }
    end
  end
  
  def sync_to_dfp
    super
    redirect_to :controller => @current_controller, :action => 'index'     
    
  end
  
  def sync_from_dfp
    parent_updates = super
    root_ad_unit = get_root_ad_unit
    parent_updates.each do |au|
      if au.parent_id_dfp == root_ad_unit.dfp_id
        au.level = 1
        au.parent_id_bulk = root_ad_unit.id
      else
        parent = AdUnit.find_by_dfp_id(au.parent_id_dfp)
        unless parent.blank?
          au.parent_id_bulk = parent.id
          parent = nil
        end
      end
      au.save(:validate => false)
    end
    
    
    AdUnit.find_all_by_level(nil).each do |au|
      au.level = au.get_level
      au.save(:validate => false)
    end
    
    redirect_to :controller => @current_controller, :action => 'index'     
    
  end
  
  def clear_all
    super
    AdUnitSize.delete(AdUnitSize.all)
  end
  
	
end
