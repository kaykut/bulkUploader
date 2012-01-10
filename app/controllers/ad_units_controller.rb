class AdUnitsController < ApplicationController
  require 'dfp_api'

  # GET /ad_units
  # GET /ad_units.json
  def index
    @ad_units = AdUnit.all
    root_au = get_root_ad_unit
    @ad_units.delete(root_au)
    @ad_units.sort! do |a,b|       
      a.top_parent_name <=> b.top_parent_name 
    end

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
      
      flash[:error] = ''

      dfp = get_dfp_instance

      # Get the Service.
      dfp_service = dfp.service(:InventoryService, API_VERSION)

      # Define initial values.
      limit = 9999
      statement = {:query => "LIMIT %d" % limit}
      all_created = []
      all_updated = []

      5.times do |i|
        to_create = []
        to_update = []
        created = []
        updated = []
        all_locals_level_i = AdUnit.find_all_by_level(i+1)
        
        break if all_locals_level_i.size == 0
        
        all_locals_level_i.each do |c|
          if c.dfp_id.blank?
            to_create << c.params_bulk2dfp
          elsif c.synced_at || c.created_at < c.updated_at
            to_update << c.params_bulk2dfp(true)
          end
        end

        begin
          created = dfp_service.create_ad_units(to_create) unless to_create.blank?
          updated = dfp_service.update_ad_units(to_update) unless to_update.blank?
        # HTTP errors.
        rescue AdsCommon::Errors::HttpError => e
          flash[:error] += "HTTP Error: %s" % e
        # API errors.
        rescue DfpApi::Errors::ApiException => e
          e.errors.each_with_index do |error, index|
            flash[:error] += "<br/>" + "%s: %s" % [error[:trigger], error[:error_string]]
          end
        end    


        created.each do |cc|
          p = AdUnit.params_dfp2bulk(cc)
          local = AdUnit.find_by_name_and_parent_id_dfp(p[:name], p[:parent_id])
          if local
            local.dfp_id = p[:dfp_id]
            local.synced_at = Time.now
            local.save
          end
        end
        all_created.concat(created)    
      end
      if all_created.size != 0
        flash[:success] = all_created.size.to_s + ' AdUnits have been successfully created in DFP.'
      end
      if all_updated.size != 0
        flash[:notice] = all_updated.size.to_s + ' AdUnits have been successfully updated in DFP.'
      end
      if all_created.size == 0 and all_updated.size == 0
        flash[:info] = 'There is no data to be pushed to DFP.'
      end
      
      redirect_to :controller => @current_controller, :action => 'index'     
    end

    def get_dfp_instance
      dfp = DfpApi::Api.new({
         :authentication => {
         :method => 'ClientLogin',
         :application_name => 'bulkUploader',
         :email => session[:user][:email],
         :password => session[:user][:password],
         :network_code => session[:user][:network]
          },
       :service => { :environment => session[:user][:environment] } })
       return dfp
    
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
