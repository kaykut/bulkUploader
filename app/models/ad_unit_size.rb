class AdUnitSize < ActiveRecord::Base
  before_save :assign_aspect_ratio
  # t.integer  "height"
  # t.integer  "width"
  # t.boolean  "is_aspect_ratio"
  # t.string   "environment_type"

  # validate :aspect_ratio_coherent_with_environment

  has_and_belongs_to_many :ad_units
  
  has_many :companion_associations
  has_many :companions, :through => :companion_associations
  
  validates :height, :numericality => {:greater_than => 0, :only_integer => true}
  validates :width, :numericality => {:greater_than => 0, :only_integer => true}

  accepts_nested_attributes_for :companions, :reject_if => :is_not_video_ad_unit_size
  
  scope :nw, lambda { |network_id| where( :network_id => network_id) }  
  
  def assign_aspect_ratio
    self.is_aspect_ratio = self.is_aspect_ratio || false
    return true
  end
  
  def params_bulk2dfp(already_companion = false)
    params = {}
    params[:size] = {}
    params[:size][:height] = self.height
    params[:size][:width] = self.width
    params[:size][:is_aspect_ratio] = self.is_aspect_ratio
    params[:environment_type] = self.environment_type
    if ( not already_companion ) and self.environment_type == 'VIDEO_PLAYER'
      params[:companions] = []
      if self.companions 
        self.companions.each do |caus|
          params[:companions] << caus.params_bulk2dfp(true)
        end
      end
    end
    return params 
  end
  
  def self.params_dfp2bulk(p)
    params = {}
    params[:network_id] = p[:network_id]
    params[:height] = p[:size][:height]
    params[:width] = p[:size][:width]
    params[:is_aspect_ratio] = p[:size][:is_aspect_ratio]
    params[:environment_type] = p[:environment_type]
    if params[:companions]
      params[:companions].each do |caus|
        params[:companions_attributes] << AdUnitSize.params_dfp2bulk(caus)
      end
    end
    return params
  end
  
  private 

  def is_not_video_ad_unit_size(params)
    
    if self.environment_type != 'VIDEO_PLAYER'
      self.errors.add(:environment_type, 'Non-video sizes cannot have companion sizes assigned.')
      return true
    elsif params[:environment_type] == 'VIDEO_PLAYER'
      self.errors.add(:environment_type, 'Companions cannot be video sizes.')
      return true
    else
      return false
    end
  end
  # to be reactivated when mobile ad units are allowed
  # def aspect_ratio_coherent_with_environment
  #   if self.is_aspect_ratio = true and self.XXXX != 'MOBILE' 
  # end
end
