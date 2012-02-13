class CompanionAssociation < ActiveRecord::Base
  belongs_to :ad_unit_size
  belongs_to :companion, :class_name => 'AdUnitSize', :foreign_key => 'companion_id'
end
