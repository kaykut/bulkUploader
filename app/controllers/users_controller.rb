class UsersController < ApplicationController
  
  def login
    
    if request.post?
      session[:user] = {}
      session[:user][:email] = params[:user][:email] 
      session[:nw] = session[:user][:network_id] = params[:user][:network_id].to_i
      session[:user][:password] = params[:user][:password]
      session[:user][:environment] = params[:user][:environment]
      session[:local_test] = params[:user][:local_test] == 1 ? true : false
      begin
        root_au = get_root_ad_unit
      rescue Exception => e
        flash[:error] = 'Login Unsuccessful. Please revise the login details.'
        redirect_to(:controller => "users", :action => "login") and return
      end
        
      redirect_to(:controller => "uploads", :action => "index")
    else 
      @user = User.new(session[:user])
    end
    
  end
    
  def logout
    session[:user] = nil
    flash[:notice] = "Logged out"
    redirect_to(:action => "login")
  end
  
end
