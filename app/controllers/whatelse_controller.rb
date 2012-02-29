class WhatelseController < ApplicationController
  skip_before_filter :authorize
  
  def error
    
  end

  def get_started

  end

  def download
    @template_zip = Rails.root.to_s + '/data/DITTO_templates.zip'
    send_file @template_zip, :type => "application/csv"
  end

end
