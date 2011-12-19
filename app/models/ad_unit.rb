class AdUnit < ActiveRecord::Base
  
	validates :name, :presence => true, :length => { :maximum => 100 }, :uniqueness => { :case_sensitive => false }
	validates :description, :length => {:maximum => 65535}
	validate :target_window_value_ok
	
	attr_accessor :ad_unit_sizes
	
	def self.params_dfp2bulk(params)
	  params.delete(:inherited_ad_sense_settings)
	  params.delete()
	 
	end
	
	def params_bulk2dfp
	 
	end
	
	
	
	
	
	def target_window_value_ok
	  unless ['BLANK', 'TOP'].include?(self.target_window)
      errors.add('target_window', 'Permitted values are "TOP" and "BLANK".')
	  end	 
	end
	
end
