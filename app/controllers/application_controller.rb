class ApplicationController < ActionController::Base
  protect_from_forgery
 # before_filter :go_to_index
  
  def set_currents
    @current_controller = controller_name
    @current_action = action_name
  end
  
  # def go_to_index
  #   redirect_to
  # end
end
