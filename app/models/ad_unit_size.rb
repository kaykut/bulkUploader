class AdUnitSize < ActiveRecord::Base
  before_save :assign_aspect_ratio
  # t.integer  "height"
  # t.integer  "width"
  # t.boolean  "is_aspect_ratio"
  # t.string   "environment_type"

  # validate :aspect_ratio_coherent_with_environment

  has_and_belongs_to_many :ad_units
  
  
  validates :height, :numericality => {:greater_than => 0, :only_integer => true}
  validates :width, :numericality => {:greater_than => 0, :only_integer => true}

  scope :nw, lambda { |network_id| where( :network_id => network_id) }  
  
  def assign_aspect_ratio
    self.is_aspect_ratio = self.is_aspect_ratio || false
    return true
  end
  
  def params_bulk2dfp(update = false)
    params = {}
    params[:size] = {}
    params[:size][:height] = self.height
    params[:size][:width] = self.width
    params[:size][:is_aspect_ratio] = self.is_aspect_ratio
    params[:environment_type] = self.environment_type
    params[:companions] = []
    params[:id] = self.dfp_id if update
    return params 
  end
  
  def self.params_dfp2bulk(p)
    params = {}
    params[:network_id] = p[:network_id]
    params[:height] = p[:size][:height]
    params[:width] = p[:size][:width]
    params[:is_aspect_ratio] = p[:size][:is_aspect_ratio]
    params[:environment_type] = p[:environment_type]
    return params
  end
  
  private 
  # to be reactivated when mobile ad units are allowed
  # def aspect_ratio_coherent_with_environment
  #   if self.is_aspect_ratio = true and self.XXXX != 'MOBILE' 
  # end
end
