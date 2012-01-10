class Label < ActiveRecord::Base
	
	validates :name, :presence => true, :uniqueness => true, :length => {:maximum => 127 }
	validate :label_type_value_is_permitted

	has_and_belongs_to_many :companies

  LABEL_TYPES = ['COMPETITIVE_EXCLUSION', 'AD_UNIT_FREQUENCY_CAP']
  
  def self.params_dfp2bulk(p)
    params = {}
    params[:name] = p[:name]
    params[:description] = p[:description]
    params[:label_type] = p[:type]
    params[:dfp_id] = p[:id].to_s
    return params
  end
  
  def params_bulk2dfp(update = false)
    params = {}
    params[:id] = self.dfp_id if update
    params[:name] = self.name
    params[:description] = self.description
    params[:type] = self.label_type
    return params
  end

	def self.row_to_params(row)
		params = {}
		params[:name] = row[0]
		params[:description] = row[1]
		params[:label_type] = row[2].sub(' ','')
    return params
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

