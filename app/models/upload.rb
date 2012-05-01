class Upload < ActiveRecord::Base
  require 'csv'
  attr_accessor :file
  attr_accessor :has_header

  after_initialize :assign_filename
  after_initialize :set_has_header_value

  validates_presence_of :filename, :location
  validate :type_extension

  EXTENSION_TYPE_NOT_COMPATIBLE_MSG = 'Only CSV files are supported.'
	ERROR_MARK_STRING = 'X'
  DATA_EXISTS_ERROR_MSG = 'This data already exists, either in DFP or in the previous lines of this file.'
  PARENT_DOES_NOT_EXIST_MSG = 'Parent Ad Unit does not exist neither in DFP nor in the previous lines of this file.'
  scope :nw, lambda { |network_id| where( :network_id => network_id) }


#Saves the uploaded file to tmp/uploads/[data_owner_id]
  def save_temp(nw_id)
    
#the creation of uploads folder is necessary as tmp/ folder is not added to git. remove when in prod.
    uploads_folder = File.join( Rails.root.to_s, "/tmp/uploads/" )
    unless File.exists?( uploads_folder ) && File.directory?( uploads_folder )
      Dir.mkdir( uploads_folder )
    end

    uploads_folder += nw_id.to_s + '/'
    unless File.exists?( uploads_folder ) && File.directory?( uploads_folder )
      Dir.mkdir( uploads_folder )
    end

#Create directory with data_owner_id under tmp/
    temp_dir = uploads_folder
    Dir.mkdir( temp_dir ) unless File.exists?( temp_dir ) && File.directory?( temp_dir )
    self.location = temp_dir

    save_as = self.location + self.filename
    if File.exists?( save_as )
      i = 1
      while File.exists?( save_as )
        temp_filename = add_to_filename(self.filename, i.to_s)
        save_as = self.location + temp_filename
        i += 1
      end
      self.filename = temp_filename
    else
      save_as = self.location + self.filename
    end

    mode = 'w'
    File.open( save_as.to_s, mode ) do |file|
      file.write( self.file.read.force_encoding('UTF-8') )
    end

    self.update_attribute(:status, 'Pending Import')
  end

  def import(nw_id)
    
    self.update_attribute(:status, 'Import in progress')
    
#initialize vars
    data_class = self.datatype.classify #class of data we're importing
    csv_is_erroneous = false #global indicator of error
    saved_data = []  #array to contain all objects to be inserted to DB in case no errors in csv file
    params = {} #params hash that are extracted from the csv row
    if !File.exists?(self.location) or !File.directory?(self.location)
      Dir::mkdir(self.location)
    end
    csv_file_out = self.location + add_to_filename( self.filename, "errors" ) #the new csv file to pass back to the user in case of errors
    csv_file_in = File.join( self.location, self.filename )

    if not( File.exists?(csv_file_in) )
      self.update_attribute(:status, 'File not found.')
      return
    end

#open output file for write
    CSV.open( csv_file_out, "wb" ) do |csv|

			count = 0
      CSV.foreach( csv_file_in ) do |row_in|
        # skip header row
        row_in.each {|e| e = e.force_encoding('UTF-8') if e.class.to_s == 'String'}
        count += 1
        if self.has_header and count == 1
          csv << row_in 
        	next
        end

# if type is AdUnit, stop upload when there is an error
        if data_class == 'AdUnit' and csv_is_erroneous
          row_out = row_in.dup
          row_out << 'Has not been checked due to previous errors.'
          csv << row_out
          next
        end
        
        
        row_out = []

        params = data_class.constantize.row_to_params( row_in, nw_id )

        dummy_data = data_class.constantize.new( params )

        row_out = row_in #dump the original csv content into csv with errors

        exists = dummy_data.exists?        
        if dummy_data.valid? and ( not exists )
          dummy_data.save
          saved_data << dummy_data
        else # not valid or already exists
          csv_is_erroneous = true 
          row_out << ERROR_MARK_STRING
          row_out << DATA_EXISTS_ERROR_MSG if exists
          
          dummy_data.errors.each do |attribute, error|            
            row_out << attribute.to_s + ': ' + error.to_s
          end
          
        end
      csv << row_out

      end           #end of CSV.parse(csv_line_in)
    end             #end of erroneous CSV file write

    self.delete_file('O')
    if csv_is_erroneous
      data_class.constantize.delete(saved_data)
      self.errors_file = add_to_filename( self.filename, "errors" )
      self.imported = false
      self.update_attribute(:status, 'Errors in File')
    else
      File.delete( csv_file_out )
      self.imported = true
      self.status = 'Imported to Local'
      self.save
    end

    return saved_data.size
    
  end

  def destroy
    delete_file('OE')
    super
  end

  def add_to_filename( filename, string_to_add )
    File.basename( filename, File.extname( filename ) ) +
                            "_" + string_to_add +
                            File.extname( filename )
  end

  protected

  def delete_file(args)
    if ( args.include? 'O' or args.include? 'o' ) and not ( self.location.blank? or self.filename.blank? )
      file = File.join(self.location, self.filename)
      if File.exists?( file ) and not( File.directory?( file ) )
        File.delete( file )
      end
    end

    if ( args.include? 'E' or args.include? 'e' ) and not ( self.location.blank? or self.errors_file.blank? )
      file = File.join(self.location, self.errors_file)
      if File.exists?( file ) and not( File.directory?( file ) )
        File.delete( file )
      end
    end
  end

  def set_has_header_value
    self.has_header = self.has_header == "0" ? false : true
  end

  def assign_filename
    if self.id.nil?
      self.filename = self.file.original_filename unless file.nil?
    end
  end

  def type_extension
    extension = File.extname( self.filename ).sub( /^\./, '' ).downcase
    if extension != 'csv'
      errors.add(:label_type, EXTENSION_TYPE_NOT_COMPATIBLE_MSG)
    end
  end


end

