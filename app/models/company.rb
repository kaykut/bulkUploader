class Company < ActiveRecord::Base

  COMPANY_TYPES = ['ADVERTISER','AGENCY','HOUSE_ADVERTISER','HOUSE_AGENCY','AD_NETWORK']
  CREDIT_STATUS = ['ACTIVE','ON_HOLD', 'CREDIT_STOP', 'INACTIVE', 'BLOCKED']

  require 'csv'

  attr_accessor :label_list
  #TODO: name uniqueness scope? only among same type?
  validates :name, :presence => true, 
  :length => { :maximum => 127 }, 
  :uniqueness => { :case_sensitive => false,  :scope => [:network_id, :company_type] }
  validates :address, :length => { :maximum => 65535 }
  validates :email, :length => { :maximum => 127 }
  validates :fax_phone, :length => { :maximum => 63 } 
  validates :primary_phone, :length => { :maximum => 63 }
  validates :external_id, :length => { :maximum => 255 }
  validates :comment, :length => { :maximum => 1024 }
  validates_email_format_of :email, :allow_nil => true, :allow_blank => true

  validate :credit_status, :inclusion => { :in => Company::CREDIT_STATUS }
  validate :company_type_value_is_permitted
  validate :labels_exist

  has_and_belongs_to_many :labels
  accepts_nested_attributes_for :labels, :reject_if => :not_already_exists

  before_save :remove_trailing_spaces
  before_save :assign_defaults

  scope :nw, lambda { |network_id| where( :network_id => network_id) }

  def self.params_dfp2bulk(p)
    params = p.dup
    params[:company_type] = params.delete(:type)
    params[:dfp_id] = params.delete(:id).to_s
    params[:labels_attributes] = []

    unless params[:applied_labels].nil? 
      params[:applied_labels].each do |l|
        app_label = Label.find_by_dfp_id(l[:label_id])
        if app_label and !l[:is_negated]
          params[:labels_attributes] << { :name => app_label.name, :label_type => app_label.label_type }
        end
      end
    end
    params.delete(:applied_labels)
    return params
  end

  def params_bulk2dfp
    params = {}
    params[:name] = self.name
    params[:email] = self.email
    params[:type] = self.company_type
    params[:address] = self.address
    params[:fax_phone] = self.fax_phone
    params[:primary_phone] = self.primary_phone
    params[:comment] = self.comment
    params[:enable_same_advertiser_competitive_exclusion] = self.enable_same_advertiser_competitive_exclusion
    params[:applied_labels] = []
    params[:credit_status] = self.credit_status
    params[:applied_labels] = [] 
    self.labels.each do |l|
      params[:applied_labels] << {:label_id =>l.dfp_id, :is_negated => false}
    end
    return params
  end

  def self.row_to_params(row, nw_id)
    return nil if row.blank?

    params = {}

    params[:name] = row[0]
    params[:company_type] = row[1]
    params[:address] = row[2]
    params[:email] = row[3]
    params[:fax_phone] = row[4]
    params[:primary_phone] = row[5]
    params[:external_id] = row[6]
    params[:comment] = row[7]
    params[:enable_same_advertiser_competitive_exclusion] = row[8] || false
    params[:credit_status] = row[9]
    params[:network_id] = nw_id

    return params if row[10].blank?
    params[:labels_attributes] = []    
    #we assume that the format is "label1_name;label2_name;...;labeln_nameΩ
    CSV.parse_line(row[10], :col_sep => ';').each do |l|
      next if l.blank?
      dl = Label.find_or_initialize_by_name_and_label_type(l, 'COMPETITIVE_EXCLUSION')
      #no need to pass more attributes, as not_already_exists will look with these 2
      params[:labels_attributes] << { :name => dl.name, :label_type => dl.label_type } 
    end
    return params
  end

  def to_row
    row = [self.name, self.company_type, self.address, self.email, self.fax_phone, self.primary_phone, self.external_id, self.comment, 
      self.enable_same_advertiser_competitive_exclusion, self.credit_status]
    row << self.label_list
  end

  def exists?
    Company.find_by_name(self.name) ? true : false
  end

  def label_list
    return '' if self.labels.blank?
    ll = ''
    self.labels.each_with_index do |l, i|
      ll += l.name + ';'
    end
    return ll.chop!
  end

  def label_list=(llist)
    return if llist.blank?

    CSV.parse_line(llist, :col_sep => ';').each do |label_name|
      l = Label.find_or_initialize_by_name_and_label_type(label_name, 'COMPETITIVE_EXCLUSION')
      self.labels << l unless self.labels.include?(l)
    end
  end

  #Validations
  def company_type_value_is_permitted
    unless COMPANY_TYPES.include?(company_type)
      errors.add(:company_type, 'Value not permitted.')
    end
  end

  def labels_exist
    self.labels.each do |l|
      if l.new_record?
        errors.add(:labels, l.name + ': label does not exist')
      elsif l.label_type != 'COMPETITIVE_EXCLUSION'
        errors.add(:labels, l.name + ': label type not compatible')
      end
    end
  end

  def not_already_exists(params)
    l = Label.find_by_name_and_label_type( params[:name], params[:label_type] )
    if not self.labels.include?(l)
      self.labels << Label.find_or_initialize_by_name_and_label_type( params[:name], params[:label_type] ) 
    end
    return true
  end

  def remove_trailing_spaces
    self.name.chop! while self.name.last == ' '
    self.name.reverse!.chop!.reverse! while self.name.first == ' '
  end

  def assign_defaults
    self.credit_status = 'ACTIVE' if self.credit_status.blank?
  end

  def self.sort_all(companies)
    companies.sort! do |a,b|
      a.name <=> b.name
    end
  end

end

