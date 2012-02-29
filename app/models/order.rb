class Order < ActiveRecord::Base
  validates :name, :uniqueness => {:scope => [:network_id, :advertiser_id]},
                   :length => { :in => 1..128 }
                   
  validates :po_number, :length => { :in => 1..63 }
  
  def self.params_dfp2bulk(params)
    p = params.dup
    p.de
  end
end
