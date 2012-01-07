class AdUnit < ActiveRecord::Base
  # t.string   "dfp_id"
  # t.string   "parent_id_dfp"
  # t.string   "parent_id_bulk"
  # t.string   "name"
  # t.string   "description"
  # t.string   "target_window"
  # t.boolean  "explicitly_targeted"
  
  has_and_belongs_to_many :ad_unit_sizes
  has_many :children, :class_name => 'AdUnit'
  belongs_to :parent, :class_name => 'AdUnit', :foreign_key => :parent_id_bulk
  accepts_nested_attributes_for :ad_unit_sizes
  
  before_save :assign_defaults
  
	validates :name, :presence => true, :length => { :maximum => 100 }, :uniqueness => { :case_sensitive => false, :scope => :parent_id_bulk }
	validates :description, :length => {:maximum => 65535}
	validate :target_window_value_ok, :unless => :is_root_level?
	
	attr_accessor :ad_unit_sizes_list
	
	TARGET_WINDOWS = ['TOP', 'BLANK']

	def exists?
    AdUnit.find_by_parent_id_bulk_and_name( self.parent_id_bulk, self.name? ) ? true : false
	end
	
	def self.params_dfp2bulk(pars)
	  params = pars.dup
	  params.delete(:inherited_ad_sense_settings)
	  params.delete(:status)
	  params.delete(:ad_unit_code)
    params[:ausizes] = params[:ad_unit_sizes]
    params.delete(:ad_unit_sizes)
    params[:ad_unit_sizes_attributes] = []
	  params[:ausizes].each do |s|
	    
      params[:ad_unit_sizes_attributes] << AdUnitSize.params_dfp2bulk(s)
    end
    params.delete(:ausizes)
    params[:dfp_id] = params[:id]
    params.delete(:id)
    # if AdUnit.find_by_dfp_id(params[:parent_id])
    #   params[:parent_id_bulk] = AdUnit.find_by_dfp_id(params[:parent_id]).id
    # end
    params[:parent_id_dfp] = params[:parent_id]
    params.delete(:parent_id)
    return params
	end
	
	def params_bulk2dfp
	  params[:name] = self.name
	  params[:id] = self.dfp_id
	  params[:parent_id] = self.parent_id_dfp
	  params[:description] = self.description
	  params[:target_window] = self.target_window
    params[:ad_unit_sizes] = []
    self.ad_unit_sizes.each do |s|
      params[:ad_unit_sizes] << s.params_bulk2dfp
    end
	  return params
	end

	def get_level
    if not self.level.nil?
	    return self.level 
    else
      return self.parent.get_level + 1
	  end
	end

	def self.row_to_params( row )
	  return nil if row.blank?
	  params = {}
	  parent = AdUnit.find_by_level(0)

debugger
    for i in 0..4
      if row[i+1].blank? or i == 4
        params[:parent_id_bulk] = parent.id
        break
      else
        parent = parent.children.find{ |name| name == row[i] }
      end
    end
  
    params[:level] = i
    params[:name] = row[i]
    params[:ad_unit_sizes_attributes] = ad_unit_sizes_params( row[5] )
    params[:target_window] = row[6]
    params[:explicitly_targeted] = row[7]
    params[:description] = row[8]
    return params
    
	end
	
	def ad_unit_sizes_list
	  sl = ''
	  self.ad_unit_sizes.each_with_index do |l, i|
      sl += l.width.to_s + 'x' + l.height.to_s
      sl += ', ' if i < ( self.ad_unit_sizes.size - 1 )
	  end
	  return sl
	end
		
	def self.ad_unit_sizes_params(slist)
	  
	  return if slist.blank?
    sizes = CSV.parse_line(slist, :col_sep => ';')
    ad_unit_sizes_attributes = []
    
    sizes.each do |s|
      params = {}
      if s[0].capitalize == 'V'
        params[:environment_type] ='VIDEO_PLAYER'
        s.delete!('vV')
      else
        params[:environment_type] ='BROWSER' 
      end
      params[:width], params[:height] = CSV.parse_line(s, :col_sep => 'x')
      ad_unit_sizes_attributes << params
    end

    return ad_unit_sizes_attributes
	end
	
#TEST THIS
	def ad_unit_sizes_list=(slist)
	  
	  return if slist.blank?
    
    ad_unit_sizes_attributes = ad_unit_sizes_params(slist)
    ad_unit_sizes_attributes.each do |params|
      self.ad_unit_sizes << AdUnitSize.new(params)
    end

  end

  def assign_defaults
    self.explicitly_targeted = false if self.explicitly_targeted.blank?
    self.target_window = 'BLANK' if self.target_window.blank?
  end
  
# VALIDATIONS & RELATED
	def target_window_value_ok
	  unless ['BLANK', 'TOP'].include?(self.target_window)
      errors.add('target_window', 'Permitted values are "TOP" and "BLANK".')
	  end	 
	end
	
	def is_root_level?
	  self.level == 0 ? true : false
	end
	  
end
