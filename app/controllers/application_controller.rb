class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authorize, :except => [:login]
  before_filter :set_currents
  
  API_VERSION = 'v201108'

  protected
	def authorize
    if session[:user].blank?
      flash[:notice] = "Please log in"
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
  
  
  
  def from_sync
    type = @current_controller.singularize
    dfp = DfpApi::Api.new({
         :authentication => {
         :method => 'ClientLogin',
         :application_name => 'bulkUploader',
         :email => session[:user][:email],
         :password => session[:user][:password],
         :network_code => session[:user][:network]
          },
       :service => { :environment => session[:user][:environment] } })
       
    # Get the Service.
    # eval( 'service_type = :' + type.capitalize + 'Service' )
    dfp_service = eval( 'dfp.service(:' + type.capitalize + 'Service, API_VERSION)' )

    # Define initial values.
    result_page = {}
    update_count = new_count = error_count = 0
    limit = 9999
    statement = {:query => "LIMIT %d" % limit}
    result_page = eval( 'dfp_service.get_' + type.pluralize + '_by_statement(statement)' )

    # label_service = dfp.service(:LabelService, API_VERSION)
    # label_page = {}
    # label_page = label_service.get_labels_by_statement(statement)
    return result_page
  end



  def to_sync
    type = @current_controller.singularize
    dfp = DfpApi::Api.new({
         :authentication => {
         :method => 'ClientLogin',
         :application_name => 'bulkUploader',
         :email => session[:user][:email],
         :password => session[:user][:password],
         :network_code => session[:user][:network]
          },
       :service => { :environment => session[:user][:environment] } })
       
    # Get the Service.
    dfp_service = eval( 'dfp.service(:' + type.capitalize + 'Service, API_VERSION)' )

    # Define initial values.
    limit = 9999
    statement = {:query => "LIMIT %d" % limit}
    to_create = to_update = created = updated = []
    all_locals = eval( type.capitalize + '.all' )
    all_locals.each do |c|
      if c.DFP_id.blank?
        to_create << c.params_bulk2dfp
      elsif c.synced_at < c.updated_at
        to_update << c.params_bulk2dfp
      end
    end
    
    created = eval( 'dfp_service.create_' + type.pluralize + '(to_create)' ) 
    updated = eval( 'dfp_service.update_' + type.pluralize + '(to_update)' ) 
    
    return { :created => created, :updated => updated }

  end

  
end
