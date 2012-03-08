class User < ActiveRecord::Base
  
  attr_accessor :local_test
  
	validates :email, :email_format => {:message => 'Email format not OK'}
  validates :netword, :numericality => true
  validates :password, :presence => true
  	
end
