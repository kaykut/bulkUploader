class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authorize, :except => [:login]
  before_filter :set_currents
  
  API_VERSION = 'v201108'

  protected
	def authorize
    if session[:user].blank?
      flash[:notice] = "Please provide API Login Data"
      redirect_to :controller => 'users', :action => 'login'
    end
  end

	private
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
    update_count = new_count = error_count = 0
    limit = 9999
    statement = {:query => "LIMIT %d" % limit}
    type = @current_controller.singularize

    # Get API instance.
    dfp = get_dfp_instance       
    # Get the Service.
    dfp_service = eval( 'dfp.service(:' + type.capitalize + 'Service, API_VERSION)' )
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
        flash[:error] += "\n" + "%s: %s" % [error[:trigger], error[:error_string]]
      end
    end    
    
    redirect_to :controller => @current_controller, :action => 'index' and return if not flash[:error].blank?
    
    result_page[:results].each do |cp|
      cp = eval(type.capitalize + '.params_dfp2bulk(cp)')
      if will_update = eval( type.capitalize + '.find_by_DFP_id( cp[:DFP_id] )')
        if will_update.update_attributes( cp )
          update_count += 1
        else
          error_count += 1
        end
      else
        dc = eval( type.capitalize + '.new(cp)' )
        if dc.save
          new_count += 1
        else
          error_count += 1
        end
      end
    end
    
    if new_count != 0
      flash[:success] = new_count.to_s + ' ' + type.pluralize.capitalize + ' have been successfully CREATED in local DB.'
    end
    if update_count != 0
      flash[:notice] = update_count.to_s + ' ' + type.pluralize.capitalize + ' have been successfully UPDATED in local DB.'
    end
    if error_count != 0
      flash[:error] += '\n' + error_count.to_s + ' ' + type.pluralize.capitalize + ' could NOT be synced to local DB.'
    end
    
    redirect_to :controller => @current_controller, :action => 'index'     
  end



  def sync_to_dfp 
    flash[:error] = ''
  
    type = @current_controller.singularize
    dfp = get_dfp_instance

    # Get the Service.
    dfp_service = eval( 'dfp.service(:' + type.capitalize + 'Service, API_VERSION)' )

    # Define initial values.
    limit = 9999
    statement = {:query => "LIMIT %d" % limit}
    to_create = []
    to_update = []
    created = []
    updated = []
    all_locals = eval( type.capitalize + '.all' )
    
    all_locals.each do |c|
      if c.DFP_id.blank?
        to_create << c.params_bulk2dfp
      elsif c.synced_at || c.created_at < c.updated_at
        to_update << c.params_bulk2dfp
      end
    end

    debugger
    begin
      created = eval( 'dfp_service.create_' + type.pluralize + '(to_create)' ) unless to_create.blank?
      updated = eval( 'dfp_service.update_' + type.pluralize + '(to_update)' ) unless to_update.blank?
    # HTTP errors.
    rescue AdsCommon::Errors::HttpError => e
      flash[:error] += "HTTP Error: %s" % e
    # API errors.
    rescue DfpApi::Errors::ApiException => e
      e.errors.each_with_index do |error, index|
        flash[:error] += "\n" + "%s: %s" % [error[:trigger], error[:error_string]]
      end
    end    
    
    debugger
    created.each do |cc|
      local = eval( type.capitalize + '.find_by_name_and_' + type + '_type(cc[:name], cc[:type] )' )
      if local
        local.DFP_id = cc[:id]
        local.synced_at = Time.now
        local.save
      end
    end    
    
    if created.size != 0
      flash[:success] = created.size.to_s + @current_controller.capitalize + 'have been successfully created in server.'
    end
    if updated.size != 0
      flash[:warning] = updated.size.to_s + @current_controller.capitalize + 'have been successfully updated in server.'
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
  end
  
end