class ApplicationController < ActionController::Base
  require 'dfp_api'
  protect_from_forgery
  before_filter :authorize, :except => [:login]
  before_filter :set_currents
  before_filter :add_network_id_to_params, :except => [:login]

  API_VERSION = :v201111

  def user_session
    @user_session ||= UserSession.new(session)
  end

  def set_currents
    @current_controller = controller_name
    @current_action = action_name
    @kaya_local = File.exists?('/Users/kaya/') and File.exists?('/Users/macadmin/')    
  end

  def get_dfp_instance

    dfp = DfpApi::Api.new(
    { 
      :authentication => 
      {
        :method => 'ClientLogin',
        :application_name => 'bulkUploader',
        :email => session[:user][:email],
        :password => session[:user][:password],
        :network_code => session[:nw]
      },
    :service => { :environment => session[:user][:environment] } 
    })     

  end

  def get_service(type)
    dfp = get_dfp_instance
    # Get the Service.
    if type == 'ad_unit'
      return dfp.service(:InventoryService, API_VERSION)
    elsif type == 'network'
      return dfp.service(:NetworkService, API_VERSION)
    else
      service_type = (type.classify + 'Service').to_sym
      return dfp.service(service_type, API_VERSION)
    end
  end


  def get_root_ad_unit
    begin
      if session[:local_test]
        effective_root_ad_unit_id = nil
      else
        network_service = get_service('network')
        effective_root_ad_unit_id = network_service.get_current_network[:effective_root_ad_unit_id]
      end

      if session[:local_test]      
        root_au = AdUnit.find_or_create_by_name_and_level_and_dfp_id_and_network_id(:name => session[:nw].to_s + 'local_test', 
                                                                                    :level => 0,
                                                                                    :dfp_id => 'local_test',
                                                                                    :network_id => session[:nw])
      else
        root_au = AdUnit.nw(session[:nw]).find_by_level(0)
        if root_au.nil?
          root_au = AdUnit.create(:name => session[:nw].to_s, 
                                  :level => 0,
                                  :dfp_id => effective_root_ad_unit_id,
                                  :network_id => session[:nw])
        else
          root_au.update_attributes(:name => session[:nw].to_s,
                                    :dfp_id => effective_root_ad_unit_id)
        end
      end
      
      return root_au

    rescue
      flash[:error] = 'Looks like an authentication error. Please check your email & password.' +
      ' Shoot an email to kaya@google.com with details if you are sure it is not that.'
      redirect_to :controller => @current_controller, :action => 'index' and return
    end

  end	

  def clear_all
    begin 
      @current_controller.classify.constantize.delete( @current_controller.classify.constantize.nw(session[:nw]).all )
      if @current_controller == 'uploads'
        Dir.glob(Rails.root.to_s + '/tmp/uploads/' + session[:nw].to_s + '/*.*').each do |file|
          File.delete(file)
        end
      end
      redirect_to :controller => @current_controller, :action => 'index'

    rescue Exception => e
      flash[:error] = 'Ooops... This is not really what we expected. Shoot an email to kaya@google.com with details.'
      redirect_to :controller => 'whatelse', :action => 'error'
    end
  end

  protected
  def authorize
    if session[:user].blank?
      flash[:notice] = "Please provide API Login Data"
      redirect_to :controller => 'users', :action => 'login'
    else
      get_root_ad_unit
    end
  end

  def add_network_id_to_params
    if not ( params.blank? )
      key = @current_controller.singularize.to_sym
      params[key][:network_id] = session[:nw] unless params[key].nil?
    end
  end
  
  def download_all
    ad_unit_header = 'Top Level AU Name, 2nd Level AU Name, 3rd Level AU Name, 4th Level AU Name, 5th Level AU Name, Ad Unit ID, Ad Unit Sizes, Target Window, Explicitly Targeted, Target Platform, Description'
    company_header = 'Name,Company Type, Address, Email, Fax Phone, Primary Phone, External ID, Comment, enable_same_advertiser_competitive_exclusion, Credit Status, Labels'
    label_header = 'Name, description, Label Type'
    
    type = @current_controller.singularize
    all_objects = type.classify.constantize.nw(session[:nw]).all
    if type == 'ad_unit'
      root_au = get_root_ad_unit
      all_objects.delete(root_au)
    end
    type.classify.constantize.sort_all(all_objects)
    r = (rand*10000000000).floor.to_s
    temp_path = File.join( Rails.root.to_s, "/tmp/") 
    temp_file = temp_path + r + '.csv'
    

    CSV.open(temp_file, "wb") do |csv|
      csv << [eval(type + '_header')]
      all_objects.each do |o|
        csv << o.to_row
      end
    end

    File.rename(temp_file, temp_path + type.pluralize + '_nw_' + session[:nw].to_s + '.csv')
    temp_file = temp_path + type.pluralize + '_nw_' + session[:nw].to_s + '.csv'
    send_file(temp_file, :type => "application/csv")
    File.delete(temp_file)
    
  end
  
  def copy_from_dfp
    type = @current_controller.singularize
    # Define initial values.
    result_page = {}
    statement = {:query => "LIMIT 99999"}
    parent_update = []

    # Get API instance.
    dfp = get_dfp_instance       

    # Get the Service.
    if type == 'ad_unit'
      dfp_service = dfp.service(:InventoryService, API_VERSION)
      root_ad_unit = get_root_ad_unit
    else
      service_sym = (type.classify + 'Service').to_sym
      dfp_service = dfp.service(service_sym, API_VERSION)
      #Label_Service gives error when trying to get all labels. 
      statement = Label.get_statement if type == 'label'
    end

    type.classify.constantize.delete( type.classify.constantize.nw(session[:nw]) )
    get_root_ad_unit if type == 'ad_unit'

    method = ( 'get_' + type.pluralize + '_by_statement' ).to_sym
    result_page = dfp_service.send(method, statement)

    result_page[:results].each do |result|
      next if type == 'ad_unit' and result[:parent_id].blank?
      next if not type.classify.constantize.nw(session[:nw]).find_by_dfp_id( result[:id] ).nil? 
      result[:network_id] = session[:nw]

      cp = type.classify.constantize.params_dfp2bulk( result )
      dc = type.classify.constantize.new( cp )
      dc.save( :validate => false ) 
    end

    total = result_page[:results].size

    if type == 'ad_unit'

      parent_update = AdUnit.nw(session[:nw]).find_all_by_parent_id_bulk( nil )

      while parent_update.count > 1

        parent_update.each do |au|
          if au.parent_id_dfp == root_ad_unit.dfp_id
            au.level = 1
            au.parent_id_bulk = root_ad_unit.id
          else
            parent = AdUnit.nw(session[:nw]).find_by_dfp_id(au.parent_id_dfp)
            if not parent.nil?
              au.parent_id_bulk = parent.id
            end
          end
          au.save(:validate => false)

        end    
        parent_update = AdUnit.nw(session[:nw]).find_all_by_parent_id_bulk( nil )
      end
      ad_unit_level_update    
    end
    redirect_to :controller => @current_controller, :action => 'index'
      
  end  
  
  def ad_unit_level_update
    AdUnit.nw(session[:nw]).find_all_by_level(nil).each do |au|
      au.level = au.get_level
      au.save( :validate => false )
    end
  end
  
end