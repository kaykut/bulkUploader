class Company < ActiveRecord::Base
	require 'csv'

	validates :name, :presence => true, :length => { :maximum => 127 }, :uniqueness => { :case_sensitive => false }
	validates :address, :length => { :maximum => 65535 }
	validates :email, :length => { :maximum => 127 }
	validates :faxPhone, :length => { :maximum => 63 }
	validates :primaryPhone, :length => { :maximum => 63 }
	validates :externalId, :length => { :maximum => 255 }
	validates :comment, :length => { :maximum => 1024 }

	validate :correct_email_format_
	validate :company_type_value_is_permitted

	has_and_belongs_to_many :labels


	def row_to_params(row)
		params[:name] = row[0]
		params[:company_type] = row[1]
		params[:address] = row[2]
		params[:email] = row[3]
		params[:faxPhone] = row[4]
		params[:primaryPhone] = row[5]
		params[:comment] = row[6]
		params[:enableSameAdvertiserCompetitiveExclusion] = row[7]
		params[:labels] = []

#we assume that the format is "label1_name|label2_name|...|labeln_name"
		labels = row[8]
		CSV.parse(labels, :col_sep = '|') do |l|
			label = nil
			label = Label.find_by_name(l)
			if label.nil?
				return 'no such label'
    	elsif label.label_type != 'COMPETITIVE_EXCLUSION'
				return 'label type incompatible'
			else
				params[:labels] << label
			end
		end
	end

#Validations
	def company_type_value_is_permitted
		unless ['HOUSE_ADVERTISER', 'HOUSE_AGENCY', 'ADVERTISER', 'AGENCY', 'AD_NETWORK'].include?(company_type)
			errors.add(:company_type, 'Value not permitted.')
		end
	end

	def correct_email_format
		unless email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
			errors.add(:email, 'Email format not correct.')
		end
	end
end

