class Upload < ActiveRecord::Base
  require 'csv'
  cattr_accessor :file

  after_initialize :assign_filename

  validates_presence_of :filename, :location
  validate :type_extension

  DATA_EXISTS_ERROR_MSG = 'This data already exists in database.'
  EXTENSION_TYPE_NOT_COMPATIBLE_MSG = 'Only CSV files are supported.'
	ERROR_MARK_STRING = 'X'



#Saves the uploaded file to tmp/uploads/[data_owner_id]
  def save_temp
#the creation of uploads folder is necessary as tmp/ folder is not added to git. remove when in prod.
    uploads_folder = File.join( Rails.root.to_s, "/tmp/uploads/" )
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

    File.open( save_as.to_s, 'w' ) do |file|
      file.write( self.file.read )
    end

    self.status = 'Pending import'
    self.save
  end

  def import

    self.status = 'Processing'
    self.save
#initialize vars
    data_class = self.datatype.singularize.capitalize #class of data we're importing
    csv_is_erroneous = false #global indicator of error
    saved_data = []  #array to contain all objects to be inserted to DB in case no errors in csv file
    deleted_data = [] #array to contain all objects to be deleted from DB in case of no errors & overwrite
    params = {} #params hash that are extracted from the csv row
    csv_file_out = self.location + add_to_filename( self.filename, "errors" ) #the new csv file to pass back to the user in case of errors
    csv_file_in = File.join( self.location, self.filename )

    if not( File.exists?(csv_file_in) )
      self.status = 'File not found'
      return
    end

#open output file for write
    CSV.open( csv_file_out, "wb" ) do |csv|
#    csv_string = CSV.generate do |csv|


#      File.open( csv_file_in ).each do |csv_line_in| #read original file line-by-line
			count = 0
#        CSV.parse(csv_line_in ) do |row_in|
        CSV.foreach( csv_file_in ) do |row_in|
# skip header row
					count += 1
          if count == 1
            csv << row_in 
          	next
          end

          row_out = []

          params = eval(data_class + '.row_to_params( row_in )')
          dummy_data = nil

          dummy_data = eval(data_class + '.new( params )')
          row_out = row_in #dump the original csv content into csv with errors
          exists = dummy_data.exists?
          if dummy_data.valid?
            if exists
              if self.overwrite
                deleted_data << exists
                eval( data_class + '.delete( exists )' )
                saved_data << dummy_data
                dummy_data.save
              else #do NOT overwrite
                csv_is_erroneous = true unless csv_is_erroneous
                row_out << ERROR_MARK_STRING
                row_out << DATA_EXISTS_ERROR_MSG #exists contain error msg if exists, false if not.
              end
            else #does not already exist
              dummy_data.save
              saved_data << dummy_data
            end

          else #not valid
            csv_is_erroneous = true unless csv_is_erroneous
            row_out << ERROR_MARK_STRING
            dummy_data.errors.each do |attribute, error|
              
              row_out << attribute.to_s + ': ' + error.to_s
            end
            row_out << DATA_EXISTS_ERROR_MSG if exists
          end
        csv << row_out

        end           #end of CSV.parse(csv_line_in)
#      end             #end of File.open(file_in)
    end               #end of erroneous CSV file write
#

    self.delete_file('O') #REVISE - can depend on setting, we can charge for keeping files.
    if csv_is_erroneous
      eval(data_class + '.delete(saved_data)')
      deleted_data.each do |d|
        d.dup.save
      end
      self.errors_file = add_to_filename( self.filename, "errors" )
      self.imported = false
      self.status = 'Erroneous'
      self.save
    else
      File.delete( csv_file_out )
      self.imported = true
      self.status = 'Imported'
      self.save
    end

  end

  def destroy
    delete_file('OE')
    super
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

  def assign_filename
    if self.id.nil?
      self.filename = self.file.original_filename unless file.nil?
    end
  end

  def add_to_filename( filename, string_to_add )
    File.basename( filename, File.extname( filename ) ) +
                            "_" + string_to_add +
                            File.extname( filename )
  end

  def type_extension
    extension = File.extname( self.filename ).sub( /^\./, '' ).downcase
    if extension != 'csv'
      errors.add(:label_type, EXTENSION_TYPE_NOT_COMPATIBLE_MSG)
    end
  end

end
