class Label < ActiveRecord::Base
  LABEL_TYPES = ['COMPETITIVE_EXCLUSION', 'AD_UNIT_FREQUENCY_CAP']
	validates :name, :presence => true, :uniqueness => true, :length => {:maximum => 127 }
	validate :label_type_value_is_permitted

	has_and_belongs_to_many :companies

	def label_type_value_is_permitted
		unless LABEL_TYPES.include?(label_type)
			errors.add(:label_type, 'Value NOT permitted.')
		end
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

end

