#---
# Excerpted from "Agile Web Development with Rails, 3rd Ed.",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material, 
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose. 
# Visit http://www.pragmaticprogrammer.com/titles/rails3 for more book information.
#---
class AuthorizationController < ApplicationController

  # just display the form and wait for user to
  # enter a email and password
  
  def login
    if request.post?
      user = User.authenticate(params[:user][:email], params[:user][:password])
      if user
#KAYA 06/05/2011 - data_owner_id for now in session. might be security risk, as data_owner_id is CRITICAL. look into it.
        session[:user_id] = user.id
        redirect_to(:controller => "uploads", :action => "index")
      else
        flash[:error] = "Invalid user/password combination"
      end
    end
  end
  

  
  def logout
    session[:user_id] = nil
    flash[:notice] = "Logged out"
    redirect_to(:action => "login")
  end
  
  def signup
    
    if request.post?
    else
      @user = User.new()
      respond_to do |format|
        format.html
      end
    end
  end
  
  def index

  end
  
end
