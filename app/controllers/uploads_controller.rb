class UploadsController < ApplicationController

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

      if @upload.filename.blank?
        flash[:upload] = @upload
        redirect_to new_upload_path, :flash => { :error => "Please choose a file to upload." } and return
      end

      #get Labels from DFP if Companies are being uploaded
      copy_from_dfp('label') if type == 'company' 
      copy_from_dfp( type )

      @upload.save_temp(session[:nw])

      no_saved = @upload.import(session[:nw])

      if @upload.status == 'Erroneous'
        flash[:error] = 'Import Unsuccesful. Download file to see errors.'
        redirect_to uploads_url and return
      else
        ad_unit_level_update
      end

          
      no_created = copy_to_dfp( @upload.datatype.singularize.underscore )


      if no_created == 0 and no_saved == 0
        flash[:info] = 'There is no data to be pushed to DFP.'
      else
        flash[:success] = no_saved.to_s + ' ' + @upload.datatype + 'have been imported from CSV. ' +
        no_created.to_s + ' '+ @upload.datatype + ' have been created in DFP.'
        flash[:error] = '# Imported <> # Created in DFP - There is an error' if no_created != no_saved

      end
      redirect_to :controller => @upload.datatype.underscore, :action => 'index' and return
    # rescue Exception => e
    #   flash[:error] += e.to_s
    #   redirect_to :controller => 'uploads', :action => 'new'
    # end

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

  def copy_to_dfp(type)

    # Define initial values.
    limit = 9999
    statement = {:query => "LIMIT %d" % limit}
    to_create = []
    all_created = []

    # Get the Service.
    dfp_service = get_service(type)

    if type == 'ad_unit'
      5.times do |i|
        all_locals_level_i = AdUnit.nw(session[:nw]).find_all_by_level(i+1)
        all_locals_level_i.each { |c| to_create << c.params_bulk2dfp if c.dfp_id.blank? }
        next if to_create.size == 0
        
        created = dfp_service.create_ad_units(to_create) unless to_create.blank?

        created.each do |cc|
          local = AdUnit.nw(session[:nw]).find_by_name_and_parent_id_dfp(cc[:name], cc[:parent_id])
          if not local.nil?
            local.update_attribute( 'dfp_id', cc[:id] ) 
            if not local.children.nil?
              local.children.each {|cau| cau.update_attribute('parent_id_dfp', cc[:id])}
            end
          end
        end
        all_created.concat(created)    
        to_create = []
      end

    else
      all_locals = type.classify.constantize.nw(session[:nw]).all
      all_locals.each { |c| to_create << c.params_bulk2dfp if c.dfp_id.blank? }

      create_method_name = ( 'create_' + type.pluralize ).to_sym
      all_created = dfp_service.send(create_method_name, to_create) unless to_create.blank?

      all_created.each do |cc| 
        method_name = ( 'find_by_name_and_' + type + '_type' ).to_sym
        local.update_attribute('dfp_id', cc[:id]) if local = type.classify.constantize.nw(session[:nw]).send( method_name, cc[:name], cc[:type] )
      end
    end
    return all_created.nil? ? 0 : all_created.size

  end

  def download
    @upload = Upload.find(params[:id])
    send_file @upload.location + @upload.errors_file, :type => "application/csv"
  end

  private
  def ad_unit_level_update

    AdUnit.nw(session[:nw]).find_all_by_level(nil).each do |au|
      au.level = au.get_level
      au.save( :validate => false )
    end
  end

end