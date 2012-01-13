class CompaniesController < ApplicationController
  require 'dfp_api'

  # GET /companies
  # GET /companies.json
  def index
    @companies = Company.nw(session[:nw]).all
    @companies.sort! do |a,b|
      a.name <=> b.name
    end

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
        flash[:success] = 'Company was successfully created.'
        format.html { redirect_to @company }
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
      a=1
      if @company.save
        flash[:success] = 'Company was successfully updated.'
        format.html { redirect_to @company }
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

  def sync_to_dfp
    
    if !Label.nw(session[:nw]).find_all_by_dfp_id(nil).blank?
      flash[:error] = 'There are Labels that are not synced to DFP. Please sync those DFP before proceeding with syncing of Companies.'
      redirect_to(companies_path)
    else
      super
    end
    
  end
end
