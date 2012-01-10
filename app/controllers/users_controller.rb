class UsersController < ApplicationController
  
  def login
    
	    <th>Actions</th>

    if request.post?
      session[:user] = {}
      session[:user][:email] = params[:user][:email] 
      session[:user][:network] = params[:user][:network].to_i
      session[:user][:password] = params[:user][:password]
      session[:user][:environment] = params[:user][:environment]
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
