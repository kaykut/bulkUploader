class Company < ActiveRecord::Base
	require 'csv'
	
	attr_reader :label_list

	validates :name, :presence => true, :length => { :maximum => 127 }, :uniqueness => { :case_sensitive => false }
	validates :address, :length => { :maximum => 65535 }
	validates :email, :length => { :maximum => 127 }
	validates :fax_phone, :length => { :maximum => 63 } 
	validates :primary_phone, :length => { :maximum => 63 }
	validates :external_id, :length => { :maximum => 255 }
	validates :comment, :length => { :maximum => 1024 }
  validates_email_format_of :email, :allow_nil => true, :allow_blank => true
	validate :company_type_value_is_permitted
	validate :labels_exist

	has_and_belongs_to_many :labels

  COMPANY_TYPES = ['ADVERTISER','AGENCY','HOUSE_ADVERTISER','HOUSE_AGENCY','AD_NETWORK']

  def self.params_dfp2bulk(params)
    params[:company_type] = params[:type]
    params.delete(:type)
    params[:dfp_id] = params[:id]
    params.delete(:id)
    params.delete(:applied_labels)
    return params
  end
  
  def params_bulk2dfp
    params = {}
    params[:id] = self.dfp_id unless self.dfp_id.nil?
    params[:name] = self.name
    params[:email] = self.email
    params[:type] = self.company_type
    params[:address] = self.address
    params[:fax_phone] = self.fax_phone
    params[:primary_phone] = self.primary_phone
    params[:comment] = self.comment
    params[:enable_same_advertiser_competitive_exclusion] = self.enable_same_advertiser_competitive_exclusion
    params[:applied_labels] = []
    return params
  end



	def self.row_to_params(row)
    return nil if row.blank?
    
	  params = {}

		params[:name] = row[0]
		params[:company_type] = row[1]
		params[:address] = row[2]
		params[:email] = row[3]
		params[:fax_phone] = row[4]
		params[:primary_phone] = row[5]
		params[:external_id] = row[6]
		params[:comment] = row[7]
		params[:enable_same_advertiser_competitive_exclusion] = row[8] || false
		params[:labels] = []

    return params if row[9].blank?
    
#we assume that the format is "label1_name|label2_name|...|labeln_nameΩ
		labels = row[9]
		labels = CSV.parse(labels, :col_sep => '|')
		labels[0].each do |l|
			next if l.blank?
			label = Label.find_by_name(l) || Label.new(:name => l)
			params[:labels] << label
		end
	  return params
	end
	
  def exists?
    Company.find_by_name(self.name) ? true : false
  end
	
	def label_list
	  ll = ''
	  self.labels.each_with_index do |l, i|
      ll += l.name
      ll += ', ' if i < ( self.labels.size - 1 )
	  end
	  return ll
	end
	
	def label_list=(llist)
	  return if llist.blank?
    CSV.parse(llist)[0].each do |label_name|
      self.labels << ( Label.find_by_name(label_name) || Label.new(:name => label_name) )
    end
  end
		
	def company_types
	  return COMPANY_TYPES
  end  
  
  
  
  
  #Validations
	def company_type_value_is_permitted
		unless COMPANY_TYPES.include?(company_type)
			errors.add(:company_type, 'Value not permitted.')
		end
	end

	def labels_exist
	  self.labels.each do |l|
      if l.new_record?
        errors.add(:labels, l.name + ': label does not exist')
      elsif l.label_type != 'COMPETITIVE_EXCLUSION'
        errors.add(:labels, l.name + ': label type not compatible')
      end
	  end
	end
  
end

