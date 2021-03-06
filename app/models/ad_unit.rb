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

  after_initialize :assign_defaults
  before_save :remove_trailing_spaces

  validates :name, :presence => true, 
                   :length => { :maximum => 100 }, 
                   :uniqueness => { :case_sensitive => false, :scope => [:network_id, :parent_id_bulk] }
  validates :description, :length => {:maximum => 65535}

  validate :name_characters_ok
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

  def find_existing
    AdUnit.find_by_parent_id_bulk_and_name( self.parent_id_bulk, self.name? )
  end
  

  def self.params_dfp2bulk(p)
    params = p.dup
    params[:name] = params[:name].to_s
    params[:ad_unit_sizes_attributes] = []
    params.delete(:ad_unit_sizes).each do |s|
      s[:network_id] = p[:network_id].to_s
      params[:ad_unit_sizes_attributes] << AdUnitSize.params_dfp2bulk(s)
    end
    params[:dfp_id] = params.delete(:id).to_s
    params[:level] = 0 if p[:parent_id].nil?
    params[:parent_id_dfp] = params.delete(:parent_id).to_s
    
    params.delete(:ad_unit_code)
    params.delete(:inherited_ad_sense_settings)
    params.delete(:applied_label_frequency_caps)
    params.delete(:effective_label_frequency_caps)
    params.delete(:status)
    return params
  end

  def params_bulk2dfp
    params = {}
    params[:name] = self.name
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
    self.level.nil? ? self.parent.get_level + 1 : self.level
  end

  def to_row
    row = []
    5.times do |i|
      row << self.get_parent_of_level(i+1, 'name' )
    end
    row << self.dfp_id
    row << self.ad_unit_sizes_list
    row << self.target_window
    row << self.explicitly_targeted
    row << self.target_platform
    row << self.description
    return row
  end
  
  def self.row_to_params( row, nw_id )
    
    return nil if row.blank?
    params = {}
    parent = AdUnit.nw(nw_id).find_by_level(0)
    
    for i in 0..4
      if row[i+1].blank? or i == 4 or parent.nil?
        break
      else
        if !parent.children.blank?      
          parent = parent.children.find{ |au| au.name.downcase == row[i].downcase }
        else
          params[:parent_id_bulk] = nil
          break
        end
      end
    end
    params[:parent_id_dfp] = parent.nil? ? nil : parent.dfp_id
    params[:parent_id_bulk] = parent.nil? ? nil : parent.id
    params[:name] = row[i]
    params[:level] = i + 1 
    params[:ad_unit_sizes_attributes] = ad_unit_sizes_params( row[5], nw_id )
    params[:target_window] = row[6]
    params[:explicitly_targeted] = row[7]
    params[:target_platform] = row[8]
    params[:description] = row[9]

    params[:network_id] = nw_id
    return params
  end

  def ad_unit_sizes_list(to_file = false)
    sl = ''
    self.ad_unit_sizes.each_with_index do |l, i|
      aus = ''
      if l.is_aspect_ratio
        aus = 'A' + l.width.to_s + ':' + l.height.to_s        
      else
        aus = l.width.to_s + 'x' + l.height.to_s
        if l.environment_type == 'VIDEO_PLAYER'
          aus = 'V'+ aus 
          l.companions.each do |c|
            aus += '|' + c.width.to_s + 'x' + c.height.to_s
          end
        end
      end
      sl += aus
      
      if not to_file
        sl +=  '; ' if i < ( self.ad_unit_sizes.size - 1 )
      else
        sl += ';' if i < ( self.ad_unit_sizes.size - 1 )
      end
    end
    return sl
  end

  def self.ad_unit_sizes_params(slist, nw_id)

    return [] if slist.blank?
    sizes = CSV.parse_line(slist, :col_sep => ';')
    ad_unit_sizes_attributes = []

    sizes.each do |s|
      params = {}
      separator = 'x'
      if s[0].capitalize == 'V'
        params[:environment_type] ='VIDEO_PLAYER'
        s.delete!('vV')
        v_and_comps = CSV.parse_line(s, :col_sep => '|')
        if v_and_comps.size > 1
          params[:companions_attributes] = []
          v_and_comps.each_with_index do |cs, i|
            next if i == 0
            cwh = CSV.parse_line(cs, :col_sep => 'x')
            params[:companions_attributes] << {:width => cwh[0].to_i, :height => cwh[1].to_i, :network_id => nw_id, :environment_type => 'BROWSER'}
          end

        end
      else
        if s[0].capitalize == 'A'
          params[:is_aspect_ratio] = true 
          separator = 'x'
          s.delete!('aA')
        end
        params[:environment_type] ='BROWSER' 
      end
      wh = CSV.parse_line( s, :col_sep => separator )
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

  def parent
    if parent_id_bulk.nil?
      par = AdUnit.nw( self.network_id ).find_by_dfp_id( self.parent_id_dfp )
      if not par.nil?
        self.update_attribute( :parent_id_bulk, par.id )
      end
    else
      par = AdUnit.nw( self.network_id ).find( self.parent_id_bulk )
    end
    return par
  end
  
  
  def list
    result = []
    AdUnit.all.each do |au|
      result << {:name => au.name, :dfp_id => au.dfp_id, :parent_id_dfp => au.parent_id_dfp}
    end
    result
  end

  protected
  def assign_defaults
    self.explicitly_targeted = false if self.explicitly_targeted.blank?
    self.target_window = 'BLANK' if self.target_window.blank?
    self.target_platform = 'WEB' if self.target_platform.blank?
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
    aus = AdUnitSize.nw(params[:network_id]).find_by_height_and_width_and_is_aspect_ratio_and_environment_type_and_network_id( params[:height],
                                                                                                                               params[:width],
                                                                                                                               params[:is_aspect_ratio],
                                                                                                                               params[:environment_type] )
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

  def name_characters_ok
    if self.name.include?('|') 
      errors.add('name', 'name cannot contain "|" (pipe character)')
    elsif self.name.include?(' ') 
      errors.add('name', 'name cannot contain " " (space)')
    elsif self.name.include?('/')
      errors.add('name', 'name cannot contain "/" (slash character)')
    end
  end
  
  def self.sort_all(ad_units)
    ad_units.sort! do |a,b|       

      if a.get_parent_of_level(1,'name') != b.get_parent_of_level(1,'name') 
        a.get_parent_of_level(1,'name') <=> b.get_parent_of_level(1,'name') 
      else
        if a.get_parent_of_level(2,'name') != b.get_parent_of_level(2,'name') 
          a.get_parent_of_level(2,'name') <=> b.get_parent_of_level(2,'name') 
        else
          if a.get_parent_of_level(3,'name') != b.get_parent_of_level(3,'name') 
            a.get_parent_of_level(3,'name') <=> b.get_parent_of_level(3,'name') 
          else
            if a.get_parent_of_level(4,'name') != b.get_parent_of_level(4,'name') 
              a.get_parent_of_level(4,'name') <=> b.get_parent_of_level(4,'name') 
            else
              a.get_parent_of_level(5,'name') <=> b.get_parent_of_level(5,'name') 
            end
          end
        end
      end
      
    end
    
  end
  
  
end
