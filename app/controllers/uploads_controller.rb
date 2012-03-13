class UploadsController < ApplicationController
  API_ERROR_LINKS = {'Labels' => 'https://developers.google.com/doubleclick-publishers/docs/reference/v201111/LabelService.ApiError',
                     'AdUnits' => 'https://developers.google.com/doubleclick-publishers/docs/reference/v201111/InventoryService.ApiError',
                     'Companies' => 'https://developers.google.com/doubleclick-publishers/docs/reference/v201111/CompanyService.ApiError'}
  # GET /uploads
  # GET /uploads.xml
  def index
    @uploads = Upload.nw(session[:nw]).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @uploads }
    end
  end

  # GET /uploads/new
  # GET /uploads/new.xml
  def new

    @upload = flash[:upload] || Upload.new 

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @upload }
    end
  end

  # POST /uploads
  # POST /uploads.xml
  def create

    # begin 
    @upload = Upload.new(params[:upload])
    type = @upload.datatype.singularize.underscore
    error_details = {}

    if @upload.filename.blank?
      flash[:upload] = @upload
      redirect_to new_upload_path, :flash => { :error => "Please choose a file to upload." } and return
    end

    #get Labels from DFP if Companies are being uploaded
    if not session[:local_test]
      copy_from_dfp('label') if type == 'company' 
      copy_from_dfp( type )

      begin
        copy_from_dfp('label') if type == 'company' 
        copy_from_dfp( type )
      rescue Exception => e
        sync_from_dfp_error = true
        error_details[:message] = e.errors[0][:reason].to_s
        error_details[:trigger] = e.errors[0][:trigger].to_s
        error_details[:type] = e.errors[0][:api_error_type].to_s
      end
    end
    
    if not sync_from_dfp_error
      @upload.save_temp(session[:nw])

      no_saved = @upload.import(session[:nw])
      
      if @upload.status == 'Errors in File'
        flash[:error] = 'Import Unsuccesful. Download <strong>Errors</strong> file to see errors.'.html_safe
        redirect_to uploads_url and return
      else
        ad_unit_level_update
      end

      if session[:local_test]
        redirect_to :controller => @upload.datatype.underscore, :action => 'index' and return
      end

      result = copy_to_dfp( @upload )
      all_created = result[0]
      not_created = result[1]
      sync_to_dfp_error = result[2]
      error_details = result[3]
      no_created = all_created.count
    end

    if sync_from_dfp_error
      flash[:error] = ('There was an error syncing data FROM DFP. Please contact kaya@google.com with details:' + 
                       '<ul>'+ 
                        '<li><strong>Trigger</strong>: ' + error_details[:trigger] + '</li>' + 
                         '<li><strong>Message</strong>: ' + error_details[:message] + '</li>' + 
                         '<li><strong>API Error Type:</strong>: ' +error_details[:type] + '</li>' + 
                       '</ul><br/>').html_safe
      redirect_to :controller => 'uploads', :action => 'index' and return
      @upload.update_attribute(:status, 'Error in import from DFP.')
    elsif sync_to_dfp_error
      flash[:error] = ('The import to local was successful, however, there was an error syncing data TO DFP. Here are the details: <br/>' + 
                      '<ul>'+ 
                        '<li><strong>Trigger</strong>: ' + error_details[:trigger] + '</li>' + 
                        '<li><strong>Message</strong>: ' + error_details[:message] + '</li>' + 
                        '<li><strong>API Error Type:</strong>: ' +error_details[:type] + '</li>' + 
                      '</ul><br/>' + 
                      'You can:' +
                      '<ul>' +
                        '<li>See the <strong>Created</strong> and <strong>Not Created</strong> objects in separate files, next to your upload in the list below.</li>' +
                        "<li>See the details of the error on the API documentation <a href=#{API_ERROR_LINKS[@upload.datatype]}>here</a>.</li>" + 
                        '<li>Get in touch with kaya@google.com if your investigation of the link above does not provide any solutions.</li>' +
                      '</ul>').html_safe
      redirect_to :controller => 'uploads', :action => 'index' and return
      @upload.update_attribute(:status, 'Error in import to DFP.')
    else
      flash[:success] = "Import successful. #{all_created.size.to_s} #{type.classify.pluralize} have been created."
      @upload.update_attribute(:status, 'Imported')
    end

    redirect_to :controller => @upload.datatype.underscore, :action => 'index' and return

  end

  # DELETE /uploads/1
  # DELETE /uploads/1.xml
  def destroy
    @upload = Upload.find(params[:id])
    @upload.destroy

    respond_to do |format|
      format.html { redirect_to(uploads_url) }
      format.xml  { head :ok }
    end
  end

  def copy_from_dfp(type)
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
    
    if type != 'ad_unit'
      type.classify.constantize.delete( type.classify.constantize.nw(session[:nw]) )
    else
      AdUnit.nw(session[:nw]).all.each do |au|
        AdUnit.delete(au) if au.id != root_ad_unit.id
      end
    end
      
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

  end

  def copy_to_dfp( upload )
    type = upload.datatype.singularize.underscore
    # Define initial values.
    limit = 9999
    statement = {:query => "LIMIT %d" % limit}
    all_created = []
    not_created = []
    error_details = {}

    # Get the Service.
    dfp_service = get_service(type)

    error = false

    if type == 'ad_unit'

      5.times do |i|
        to_create_hash = []
        to_create_object = []
        created = []
  
        all_locals_level_i = AdUnit.nw(session[:nw]).find_all_by_level(i+1)
        all_locals_level_i.each do |c| 
          if c.dfp_id.blank?
            to_create_object << c 
            to_create_hash << c.params_bulk2dfp
          end
        end

        next if to_create_object.size == 0

        if not error
          begin
            # if no prev. errors, create current level.
            created = dfp_service.create_ad_units(to_create_hash)
          rescue Exception => e
            # When error is caught, mark & keep error details

            error = true
            error_details[:message] = e.errors[0][:reason].to_s
            error_details[:trigger] = e.errors[0][:trigger].to_s
            error_details[:type] = e.errors[0][:api_error_type].to_s
          end
        end

        # if creation succeeded for this level, update & add to all_created
        if not error
          created.each do |cc|
            local = AdUnit.nw(session[:nw]).find_by_name_and_parent_id_dfp(cc[:name], cc[:parent_id])
            if not local.nil?
              local.update_attribute( 'dfp_id', cc[:id] ) 
              all_created << local
              if not local.children.nil?
                local.children.each {|cau| cau.update_attribute('parent_id_dfp', cc[:id])}
              end
            end
          end
        else
          # if any errors => add all to_created to not_created.
          not_created.concat(to_create_object)
        end        

      end

    else
      all_locals = type.classify.constantize.nw(session[:nw]).all
      all_locals.each do |c|
        if c.dfp_id.blank?
          to_create_object << c 
          to_create_hash << c.params_bulk2dfp
        end
      end

      create_method_name = ( 'create_' + type.pluralize ).to_sym
      begin
        created = dfp_service.send(create_method_name, to_create_hash) unless to_create_hash.blank?
      rescue Exception => e
        error = true
        error_details[:message] = e.errors[0][:reason].to_s
        error_details[:trigger] = e.errors[0][:trigger].to_s
        error_details[:type] = e.errors[0][:api_error_type].to_s
      end

      if not error
        created.each do |cc| 
          method_name = ( 'find_by_name_and_' + type + '_type' ).to_sym
          local = type.classify.constantize.nw(session[:nw]).send( method_name, cc[:name], cc[:type] )
          if not local.nil?
            local.update_attribute('dfp_id', cc[:id])
            all_created << local
          end
        end
      else
        not_created.concat(to_create_object)
      end
      
    end


    if all_created.size > 0
      upload.created_file = upload.add_to_filename( upload.filename, 'created')
      CSV.open(upload.location + upload.created_file, "wb") do |csv|
        all_created.each do |created|
          csv << created.to_row
        end
      end
    end
    
    if error
      upload.not_created_file = upload.add_to_filename( upload.filename, 'not_created')
      CSV.open(upload.location + upload.not_created_file, "wb") do |csv|
        not_created.each do |not_created|
          csv << not_created.to_row
        end
      end
    end

    AdUnit.delete( not_created )

    upload.save
    return [all_created, not_created, error, error_details]

  end

  def download_errors
    @upload = Upload.find(params[:id])
    send_file @upload.location + @upload.errors_file, :type => "application/csv"
  end

  def download_created
    @upload = Upload.find(params[:id])
    send_file @upload.location + @upload.created_file, :type => "application/csv"
  end
  
  def download_not_created
    @upload = Upload.find(params[:id])
    send_file @upload.location + @upload.not_created_file, :type => "application/csv"
  end


  def ad_unit_level_update
    super
  end

end