class User < ActiveRecord::Base
  
	validates :email, :email_format => {:message => 'Email format not OK'}
  validates :netword, :numericality => true
  validates :password, :presence => true
  	
end
