class CompaniesController < ApplicationController
  require 'dfp_api'
  API_VERSION = 'v201108'
  PAGE_SIZE = 9999
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
      if @company.update_attributes(params[:company])
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
  
  def fromsync
    @user = User.find(session[:user_id])
    dfp = DfpApi::Api.new({
         :authentication => {
         :method => 'ClientLogin',
         :application_name => 'bulkUploader',
         :email => @user.email,
         :password => @user.password },
       :service => { :environment => 'SANDBOX' } })
       
     # Get the CompanyService.
     company_service = dfp.service(:CompanyService, API_VERSION)

     # Define initial values.
     page = {}
     statement = {:query => "LIMIT %d" % [PAGE_SIZE]}
     page = company_service.get_companies_by_statement(statement)


debugger




     # Print a footer.
     if page.include?(:total_result_set_size)
       puts "Total number of companies: %d" % page[:total_result_set_size]
     end
       
       
       
  end
end
