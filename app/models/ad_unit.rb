class AdUnit < ActiveRecord::Base
  # t.string   "dfp_id"
  # t.string   "parent_id_dfp"
  # t.string   "parent_id_bulk"
  # t.string   "name"
  # t.string   "description"
  # t.string   "target_window"
  # t.boolean  "explicitly_targeted"
  require 'csv'

  has_and_belongs_to_many :ad_unit_sizes
  has_many :children, :class_name => 'AdUnit', :foreign_key => :parent_id_bulk, :dependent => :destroy
  belongs_to :parent, :class_name => 'AdUnit', :foreign_key => :parent_id_bulk
  accepts_nested_attributes_for :ad_unit_sizes, :reject_if => :already_exists

  before_save :assign_defaults
  before_save :remove_trailing_spaces

  validates :name, :presence => true, 
                   :length => { :maximum => 100 }, 
                   :uniqueness => { :case_sensitive => false, :scope => [:network_id, :parent_id_bulk] }
 
  validates :description, :length => {:maximum => 65535}

  validate :target_window_value_ok, :unless => :is_root_level?
  validate :target_platform_value_ok, :unless => :is_root_level?
  validate :parent_exists, :unless => :is_root_level?

  attr_accessor :ad_unit_sizes_list
  attr_accessor :top_parent_name
  TARGET_WINDOWS = ['TOP', 'BLANK']
  TARGET_PLATFORMS = ['WEB', 'MOBILE']

  scope :nw, lambda { |network_id| where( :network_id => network_id) }

  def exists?
    AdUnit.find_by_parent_id_bulk_and_name( self.parent_id_bulk, self.name? ) ? true : false
  end


  def self.params_dfp2bulk(p)
    params = p.dup
    params[:ad_unit_sizes_attributes] = []
    params.delete(:ad_unit_sizes).each do |s|
      s[:network_id] = p[:network_id]
      params[:ad_unit_sizes_attributes] << AdUnitSize.params_dfp2bulk(s)
    end
    params[:dfp_id] = params.delete(:id).to_s
    if p[:parent_id].nil?
      params[:level] = 0
    else
      params[:parent_id_dfp] = params.delete(:parent_id)
    end
    params.delete(:ad_unit_code)
    params.delete(:inherited_ad_sense_settings)
    params.delete(:applied_label_frequency_caps)
    params.delete(:effective_label_frequency_caps)
    params.delete(:status)
    return params
  end

  def params_bulk2dfp(update = false)
    params = {}
    params[:name] = self.name
    params[:id] = self.dfp_id
    params[:parent_id] = self.parent.dfp_id
    params[:description] = self.description
    params[:target_window] = self.target_window
    params[:ad_unit_sizes] = []
    params[:target_platform] = self.target_platform
    self.ad_unit_sizes.each do |s|
      params[:ad_unit_sizes] << s.params_bulk2dfp
    end
    params[:id] = self.dfp_id if update
    return params
  end

  def get_level
    if not self.level.nil?
      return self.level 
    else
      return self.parent.get_level + 1
    end
  end

  def self.row_to_params( row, nw_id )

    return nil if row.blank?
    params = {}
    parent = AdUnit.find_by_level(0)


    for i in 0..4
      if row[i+1].blank? or i == 4
        params[:parent_id_bulk] = parent.id
        break
      else
        if !parent.children.blank?
          
          parent = parent.children.find{ |au| au.name == row[i] }
        else
          
          params[:parent_id_bulk] = 'ERROR'
          break
        end
      end
    end

    params[:level] = i+1
    params[:name] = row[i]
    params[:ad_unit_sizes_attributes] = ad_unit_sizes_params( row[5], nw_id )
    params[:target_window] = row[6]
    params[:explicitly_targeted] = row[7]
    params[:target_platform] = row[8]
    params[:description] = row[9]

    params[:network_id] = nw_id
    return params

  end

  def ad_unit_sizes_list
    sl = ''
    self.ad_unit_sizes.each_with_index do |l, i|
      sl += l.width.to_s + 'x' + l.height.to_s
      sl += '; ' if i < ( self.ad_unit_sizes.size - 1 )
    end
    return sl
  end

  def self.ad_unit_sizes_params(slist, nw_id)

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
      wh = CSV.parse_line(s, :col_sep => 'x')
      params[:width] = wh[0].to_i
      params[:height] = wh[1].to_i
      params[:network_id] = nw_id
      ad_unit_sizes_attributes << params
    end

    
    return ad_unit_sizes_attributes
  end

  def get_parent_of_level(level, attribute = nil)
    return '' if level.nil? or self.level < level
    parent = self
    (self.level - level).times do
      parent = parent.parent
    end
    attribute ? eval('parent.' + attribute) : parent
  end

  #TEST THIS
  def ad_unit_sizes_list=(slist)

    return if slist.blank?

    ad_unit_sizes_attributes = AdUnit.ad_unit_sizes_params(slist)
    ad_unit_sizes_attributes.each do |params|
      self.ad_unit_sizes << AdUnitSize.new(params)
    end

  end


  protected
  def assign_defaults
    self.explicitly_targeted = false if self.explicitly_targeted.blank?
    self.target_window = 'BLANK' if self.target_window.blank?
  end

  # VALIDATIONS & RELATED
  def target_window_value_ok
    unless TARGET_WINDOWS.include?(self.target_window)
      errors.add('target_window', 'Permitted values are "TOP" and "BLANK".')
    end	 
  end

  def target_platform_value_ok
    unless AdUnit::TARGET_PLATFORMS.include?(self.target_platform)
      errors.add('target_platform', 'Permitted values are "WEB" and "MOBILE".')
    end	 
  end

  def is_root_level?
    self.level == 0 ? true : false
  end

  def already_exists(params)
    aus = AdUnitSize.find_by_height_and_width_and_is_aspect_ratio_and_environment_type_and_network_id( params[:height],
                                                                                                       params[:width],
                                                                                                       params[:is_aspect_ratio],
                                                                                                       params[:environment_type],
                                                                                                       params[:network_id] )
    if aus 
      self.ad_unit_sizes << aus
      return true
    else
      return false
    end
  end

  def remove_trailing_spaces
    self.name.chop! while self.name.last == ' '
    self.name.reverse!.chop!.reverse! while self.name.first == ' '
  end
  
  def parent_exists
    if !AdUnit.find_by_id(self.parent_id_bulk)
      self.errors.add(:parent_id_bulk, 'Parent AdUnit does not exist.')
    end
  end

end