class UploadsController < ApplicationController

  # GET /uploads
  # GET /uploads.xml

  def index
    @uploads = Upload.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @uploads }
    end
  end

  # GET /uploads/1
  # GET /uploads/1.xml
  def show
    @upload = Upload.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @upload }
    end
  end

  # GET /uploads/new
  # GET /uploads/new.xml
  def new
    @upload = Upload.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @upload }
    end
  end

  # GET /uploads/1/edit
  def edit
    @upload = Upload.find(params[:id])
  end

  # POST /uploads
  # POST /uploads.xml
  def create

    @upload = Upload.new(params[:upload])

    if @upload.filename.blank?
      redirect_to uploads_url, :flash => { :error => "There was a problem with the upload." }
    end

    @upload.save_temp

    if @upload.datatype == 'AdUnits'
      get_root_ad_unit
    end
    @upload.import
#    @upload.delay.import

    @upload.save

    respond_to do |format|
      unless @upload.status == "Erroneous"
        flash[:success] = 'File uploaded & imported successfully.'
        format.html { redirect_to(uploads_url) }
        format.xml  { render :xml => @upload, :status => :created, :location => @upload }
      else
        flash[:error] = 'Import Unsuccesful. Download file to see errors.'
        format.html { redirect_to(uploads_url) }
        format.xml  { render :xml => @upload, :status => :created, :location => @upload }
      end
    end
  end

  # PUT /uploads/1
  # PUT /uploads/1.xml
  def update
    @upload = Upload.find(params[:id])

    respond_to do |format|
      if @upload.update_attributes(params[:upload])
        flash[:success] = 'Upload was successfully updated.'
        format.html { redirect_to(@upload) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @upload.errors, :status => :unprocessable_entity }
      end
    end
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

  def download
    @upload = Upload.find(params[:id])
    send_file @upload.location + @upload.errors_file, :type => "application/csv"
  end

  def import
    @upload.import
#    @upload.delay.import
    @upload.save
    redirect_to uploads_url 
  end

  private

end

