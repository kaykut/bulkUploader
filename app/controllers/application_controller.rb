class ApplicationController < ActionController::Base
  protect_from_forgery
 # before_filter :go_to_index
  before_filter :authorize, :except => [:login]
  before_filter :set_currents
  

  protected
	def authorize
    unless session[:user_id] and User.find(session[:user_id])
      flash[:notice] = "Please log in"
      redirect_to :controller => 'authorization', :action => 'login'
    end
  end

	private
	def user_session
		@user_session ||= UserSession.new(session)
	end

  def set_currents
    @current_controller = controller_name
    @current_action = action_name
  end
  
  
  # def go_to_index
  #   redirect_to
  # end
end
