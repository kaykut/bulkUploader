class User < ActiveRecord::Base

	validates :email, :uniqueness => true, :presence => true
  validates :email, :email_format => {:message => 'Email format not OK'}
  validates :password, :presence => true
  
	attr_accessor :password_confirmation
	validates_confirmation_of :password 
	
	def self.authenticate(email, password)
	  
		user = self.find_by_email(email)
		if user
			if user.password != password
				user = nil
			end
		end
		user
	end
	
end
