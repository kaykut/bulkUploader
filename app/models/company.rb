class Company < ActiveRecord::Base
	require 'csv'

	validates :name, :presence => true, :length => { :maximum => 127 }, :uniqueness => { :case_sensitive => false }
	validates :address, :length => { :maximum => 65535 }
	validates :email, :length => { :maximum => 127 }
	validates :faxPhone, :length => { :maximum => 63 }
	validates :primaryPhone, :length => { :maximum => 63 }
	validates :externalId, :length => { :maximum => 255 }
	validates :comment, :length => { :maximum => 1024 }

	validate :correct_email_format
	validate :company_type_value_is_permitted
	validate :labels_exist

	has_and_belongs_to_many :labels

  COMPANY_TYPES = ['ADVERTISER','AGENCY','HOUSE_ADVERTISER','HOUSE_AGENCY','AD_NETWORK']

	def self.row_to_params(row)
    return nil if row.blank?
    
	  params = {}

		params[:name] = row[0]
		params[:company_type] = row[1]
		params[:address] = row[2]
		params[:email] = row[3]
		params[:faxPhone] = row[4]
		params[:primaryPhone] = row[5]
		params[:externalId] = row[6]
		params[:comment] = row[7]
		params[:enableSameAdvertiserCompetitiveExclusion] = row[8] || false
		params[:labels] = []

    return params if row[9].blank?
    
#we assume that the format is "label1_name|label2_name|...|labeln_nameΩ
		labels = row[9]
		labels = CSV.parse(labels, :col_sep => '|')
		labels[0].each do |l|
			next if l.blank?
			label = Label.find_by_name(l) || Label.new(:name => l, :label_type => 'DOES_NOT_EXIST_ERROR_INDICATOR')
			params[:labels] << label
		end
	  return params
	end
	
  def exists?
    if Company.find_by_name(self.name)
      return true
    else
      return false
    end
  end

#Validations
	def company_type_value_is_permitted
		unless COMPANY_TYPES.include?(company_type)
			errors.add(:company_type, 'Value not permitted.')
		end
	end

	def correct_email_format
		unless email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
			errors.add(:email, 'Email format not correct.')
		end
	end
	
	def label_list
	  ll = ''
	  self.labels.each_with_index do |l, i|
      ll += l.name
      ll += ', ' if i < ( self.labels.size - 1 )
	  end
	  return ll
	end
	
	def labels_exist
	  self.labels.each do |l|
      if l.label_type == 'DOES_NOT_EXIST_ERROR_INDICATOR'
        errors.add(:labels, l.name + ': label does not exist')
      elsif l.label_type != 'COMPETITIVE_EXCLUSION'
        errors.add(:labels, l.name + ': label type not compatible')
      end
	  end
	end
	
	def company_types
	  return COMPANY_TYPES
  end
end

