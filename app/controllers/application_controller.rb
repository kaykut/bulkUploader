class ApplicationController < ActionController::Base
  require 'dfp_api'
  protect_from_forgery
  before_filter :authorize, :except => [:login]
  before_filter :set_currents
  
  API_VERSION = 'v201111'

	def user_session
		@user_session ||= UserSession.new(session)
	end

  def set_currents
    @current_controller = controller_name
    @current_action = action_name
  end

  def sync_from_dfp
    
    # Define initial values.
    result_page = {}
    flash[:error] = ''
    no_update_needed_count = update_count = new_count = error_count = 0
    limit = 9999
    statement = {:query => "LIMIT %d" % limit}
    type = @current_controller.singularize

    # Get API instance.
    dfp = get_dfp_instance       
    # Get the Service.
    if type == 'ad_unit'
      dfp_service = dfp.service(:InventoryService, API_VERSION)
    else
      dfp_service = eval( 'dfp.service(:' + type.classify + 'Service, API_VERSION)' )
      #Label_Service gives error when trying to get all labels. 
      if type == 'label'
        statement = Label.get_statement
      end
    end
    
    begin 

      result_page = eval( 'dfp_service.get_' + type.pluralize + '_by_statement(statement)' )
      # label_service = dfp.service(:LabelService, API_VERSION)
      # label_page = {}
      # label_page = label_service.get_labels_by_statement(statement)

    # HTTP errors.
    rescue AdsCommon::Errors::HttpError => e
      flash[:error] += "HTTP Error: %s" % e
    # API errors.
    rescue DfpApi::Errors::ApiException => e
      e.errors.each_with_index do |error, index|
        flash[:error] += "<br/>" + "%s: %s" % [error[:trigger], error[:error_string]]
      end
    end    
    
    redirect_to :controller => @current_controller, :action => 'index' and return if not flash[:error].blank?
    
    parent_updates = []
    
    result_page[:results].each do |result|
      cp = eval(type.classify + '.params_dfp2bulk(result)')
      to_be_updated = eval( type.classify + '.find_by_dfp_id( cp[:dfp_id] )')
      if to_be_updated
        to_be_updated.attributes = cp 
        if to_be_updated.changed? and to_be_updated.save( :validate => false )
          update_count += 1
        else
          no_update_needed_count += 1
        end
      else
        dc = eval( type.classify + '.new(cp)' )
        dc.save(:validate => false)
        parent_updates << dc
        new_count += 1
      end
    end
    error_count = result_page[:results].size - ( update_count + no_update_needed_count + new_count )

    flash[:info] = result_page[:results].size.to_s + ' ' + type.pluralize.capitalize + ' have been retrieved from DFP.'
    flash[:info] += " No updates to local DB were required." if error_count + update_count + error_count == 0
    if new_count != 0
      flash[:success] = new_count.to_s + ' ' + type.pluralize.capitalize + ' have been successfully CREATED in local DB.'
    end
    if update_count != 0
      flash[:notice] = update_count.to_s + ' ' + type.pluralize.capitalize + ' have been successfully UPDATED in local DB.'
    end
    if error_count != 0
      flash[:error] += '<br/>' + error_count.to_s + ' ' + type.pluralize.capitalize + ' have NOT BEEN CREATED/UPDATED in the local DB. <br/><strong>Contact kaya@google.com</strong>.'
    end
    
    if type == 'ad_unit'
      return parent_updates 
    else
      redirect_to :controller => @current_controller, :action => 'index'     
    end
  end

  def sync_to_dfp 
    
    flash[:error] = ''
  
    type = @current_controller.singularize
    dfp = get_dfp_instance

    # Get the Service.
    if type == 'ad_unit'
      dfp_service = dfp.service(:InventoryService, API_VERSION)
    else
      dfp_service = eval( 'dfp.service(:' + type.classify + 'Service, API_VERSION)' )
    end

    # Define initial values.
    limit = 9999
    statement = {:query => "LIMIT %d" % limit}
    to_create = []
    to_update = []
    created = []
    updated = []
    all_locals = eval( type.classify + '.all' )
    
    all_locals.each do |c|
      if c.dfp_id.blank?
        to_create << c.params_bulk2dfp
      elsif c.synced_at || c.created_at < c.updated_at
        to_update << c.params_bulk2dfp(true)
      end
    end

    
	    <th>Actions</th>

    if  to_create.blank? and to_update.blank?
      flash[:info] = 'There is no data to be pushed to DFP.'
      redirect_to :controller => @current_controller, :action => 'index' and return
    else
      begin
        created = eval( 'dfp_service.create_' + type.pluralize + '(to_create)' ) unless to_create.blank?
        updated = eval( 'dfp_service.update_' + type.pluralize + '(to_update)' ) unless to_update.blank?
      # HTTP errors.
      rescue AdsCommon::Errors::HttpError => e
        flash[:error] += "HTTP Error: %s" % e
      # API errors.
      rescue DfpApi::Errors::ApiException => e
        e.errors.each_with_index do |error, index|
          flash[:error] += "<br/>" + "%s: %s" % [error[:trigger], error[:error_string]]
        end
      end    
    end
    
    created.each do |cc|
      local = eval( type.classify + '.find_by_name_and_' + type + '_type(cc[:name], cc[:type] )' )
      if local
        local.dfp_id = cc[:id]
        local.synced_at = Time.now
        local.save
      end
    end    
    
    if created.size != 0
      flash[:success] = created.size.to_s + @current_controller.capitalize + ' have been successfully created in DFP.'
    end
    if updated.size != 0
      flash[:notice] = updated.size.to_s + @current_controller.capitalize + ' have been successfully updated in DFP.'
    end
    
    redirect_to :controller => @current_controller, :action => 'index' and return
    
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
  end
  
  
  def get_root_ad_unit
  
    root_au = AdUnit.find_by_level(0)
    return root_au if root_au
    
    dfp = get_dfp_instance 
    network_service = dfp.service(:NetworkService, API_VERSION)
    effective_root_ad_unit_id = network_service.get_current_network[:effective_root_ad_unit_id]
    root_au = AdUnit.new(:name => session[:user][:network].to_s, 
                         :level => 0,
                         :dfp_id => effective_root_ad_unit_id )
    root_au.save
    return root_au
	end	
	
  def clear_all
    eval( @current_controller.classify + '.delete(' + @current_controller.classify + '.all)' )
    if @current_controller == 'uploads'
      Dir.glob(Rails.root.to_s + '/tmp/uploads/*.*').each do |file|
        File.delete(file)
      end
    end
    redirect_to :controller => @current_controller, :action => 'index'
  end
    
  protected
	def authorize
    if session[:user].blank?
      flash[:notice] = "Please provide API Login Data"
      redirect_to :controller => 'users', :action => 'login'
    end
  end

  
  private
  
  # FROM SAMPLE CODE 
  def get_ad_units_by_statement

    # Get DfpApi instance and load configuration from ~/dfp_api.yml.
    dfp = get_dfp_instance

    # To enable logging of SOAP requests, set the log_level value to 'DEBUG' in
    # the configuration file or provide your own logger:
    # dfp.logger = Logger.new('dfp_xml.log')

    # Get the InventoryService.
    inventory_service = dfp.service(:InventoryService, API_VERSION)

    # Get the NetworkService.
    network_service = dfp.service(:NetworkService, API_VERSION)

    # Get the effective root ad unit ID of the network.
    effective_root_ad_unit_id =
        network_service.get_current_network[:effective_root_ad_unit_id]

    puts "Using effective root ad unit: %d" % effective_root_ad_unit_id

    # Create a statement to select the children of the effective root ad unit.
    statement = {
       :query => 'WHERE parentId = :id LIMIT 500',
       :values => [
           {:key => 'id',
            :value => {:value => effective_root_ad_unit_id,
                       :xsi_type => 'NumberValue'}}
       ]
    }

    # Get ad units by statement.
    page = inventory_service.get_ad_units_by_statement(statement)

    if page[:results]
      # Print details about each ad unit in results.
      page[:results].each_with_index do |ad_unit, index|
        puts "%d) Ad unit ID: %d, name: %s, status: %s." %
            [index, ad_unit[:id], ad_unit[:name], ad_unit[:status]]
      end
    end

    # Print a footer.
    if page.include?(:total_result_set_size)
      puts "Total number of ad units: %d" % page[:total_result_set_size]
    end

    begin
      get_ad_units_by_statement()

    # HTTP errors.
    rescue AdsCommon::Errors::HttpError => e
      puts "HTTP Error: %s" % e

    # API errors.
    rescue DfpApi::Errors::ApiException => e
      puts "Message: %s" % e.message
      puts 'Errors:'
      e.errors.each_with_index do |error, index|
        puts "\tError [%d]:" % (index + 1)
        error.each do |field, value|
          puts "\t\t%s: %s" % [field, value]
        end
      end
    end
  
  end
  
end