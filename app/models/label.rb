class Label < ActiveRecord::Base
	
	validates :name, :presence => true, 
	                 :uniqueness => { :case_sensitive => false, :scope => [:network_id, :label_type] },
	                 :length => {:maximum => 127 }
	validate :label_type_value_is_permitted

	has_and_belongs_to_many :companies

  LABEL_TYPES = ['COMPETITIVE_EXCLUSION', 'AD_UNIT_FREQUENCY_CAP']

  scope :nw, lambda { |network_id| where( :network_id => network_id) }
  
  def self.params_dfp2bulk(p)
    params = p.dup
    params[:label_type] = params.delete(:type)
    params[:dfp_id] = params.delete(:id).to_s
    params.delete(:is_active)
    return params
  end
  
  def params_bulk2dfp
    params = {}
    params[:name] = self.name
    params[:description] = self.description
    params[:type] = self.label_type
    return params
  end

	def self.row_to_params(row, nw_id)
		params = {}
		params[:name] = row[0]
		params[:description] = row[1]
		params[:label_type] = row[2].sub(' ','') unless row[2].nil?
		params[:network_id] = nw_id
    return params
	end

  def to_row
    row = [self.name, self.desciption, self.label_type]
  end

  def exists?
    if Label.find_by_name(self.name)
      return true
    else
      return false
    end
  end
  
  def self.get_statement
    statement = {
        :query => "WHERE type IN ('COMPETITIVE_EXCLUSION', 'AD_UNIT_FREQUENCY_CAP') ORDER BY name LIMIT 500"
    }
  end
  
  protected
  def label_type_value_is_permitted
		unless Label::LABEL_TYPES.include?(label_type)
			errors.add(:label_type, 'Permitted values are COMPETITIVE_EXCLUSION and AD_UNIT_FREQUENCY_CAP.')
		end
	end
	
	def remove_trailing_spaces
    self.name.chop! while self.name.last == ' '
    self.name.reverse!.chop!.reverse! while self.name.first == ' '
  end
  
end

