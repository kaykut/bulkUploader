class CompaniesController < ApplicationController
  require 'dfp_api'

  # GET /companies
  # GET /companies.json
  def index
    @companies = Company.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @companies }
    end
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
    @company = Company.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @company }
    end
  end

  # GET /companies/new
  # GET /companies/new.json
  def new
    @company = Company.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @company }
    end
  end

  # GET /companies/1/edit
  def edit
    @company = Company.find(params[:id])
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = Company.new(params[:company])

    respond_to do |format|
      if @company.save
        format.html { redirect_to @company, notice: 'Company was successfully created.' }
        format.json { render json: @company, status: :created, location: @company }
      else
        format.html { render action: "new" }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /companies/1
  # PUT /companies/1.json
  def update
    @company = Company.find(params[:id])

    respond_to do |format|
      @company.update_attributes(params[:company])
      if @company.save
        format.html { redirect_to @company, notice: 'Company was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company = Company.find(params[:id])
    @company.destroy

    respond_to do |format|
      format.html { redirect_to companies_url }
      format.json { head :ok }
    end
  end
  
  def clear_imported
    Company.delete( Company.all )
    redirect_to companies_path
  end
  
  def sync_from_dfp
    company_page = {}
    update_count = ok_count = error_count = 0
    begin 
      
      company_page = from_sync
    # HTTP errors.
    rescue AdsCommon::Errors::HttpError => e
      flash[:error] = "HTTP Error: %s" % e
      
    # API errors.
    rescue DfpApi::Errors::ApiException => e
      flash[:error] += '\n' + "Message: %s" % e.message
      e.errors.each_with_index do |error, index|
        error.each do |field, value|
          flash[:error] += '\n' + "\t\t%s: %s" % [field, value]
        end
      end
    end    
    
    redirect_to companies_path if flash[:error]
    
    company_page[:results].each do |cp|
      cp = Company.params_dfp2bulk(cp)
      if will_update = Company.find_by_DFP_id( cp.DFP_id )
        if will_update.update_attributes( cp )
          update_count += 1
        else
          error_count += 1
        end
      else
        dc = Company.new(cp)
        if not dc.valid?
          
          a=1
        end
        if dc.save
          ok_count += 1
        else
          error_count += 1
        end
      end
    end
    if ok_count != 0
      flash[:success] = ok_count.to_s + 'companies have been successfully CREATED in local DB.'
    end
    if update_count != 0
      flash[:notice] = update_count.to_s + 'companies have been successfully UPDATED in local DB.'
    end
    if error_count != 0
      flash[:error] += '\n' + error_count.to_s + 'companies could NOT be synced to local DB.'
    end
    redirect_to companies_path     
       
  end



  def sync_to_dfp
    created_companies = updated_companies = []
    result = {}
    flash[:error] = ''
  
    begin      
      result = to_sync
    # HTTP errors.
    rescue AdsCommon::Errors::HttpError => e
      flash[:error] += "HTTP Error: %s" % e
    # API errors.
    rescue DfpApi::Errors::ApiException => e
      e.errors.each_with_index do |error, index|
        flash[:error] += "\n" + "%s: %s" % [error[:trigger], error[:error_string]]
      end
    end    

    redirect_to companies_path and return if flash[:error]

    created_companies = result[:created]
    updated_companies = result[:updated]    
    created_companies.each do |cc|
      if will_update = Company.find(:name => cc.name, :company_type => cc.type )
        will_update.DFP_id = cc.id
        will_update.synced_at = Time.now
        will_update.save
      end
    end    
    
    if created_companies.size != 0
      flash[:success] = created_companies.size.to_s + 'companies have been successfully created in server.'
    end
    if updated_companies.size != 0
      flash[:warning] = updated_companies.size.to_s + 'companies have been successfully updated in server.'
    end
    redirect_to companies_path     
       
  end
  
end
