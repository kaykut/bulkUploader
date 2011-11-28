# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
	require 'csv'
	count = 0
	du = User.new( :email => 'kaya',  :password => 'kaya' )
  du.save(:validate => false)
  du = du = User.new( :email => 'kaya+xfp@google.com',  :password => '1Felpudo,' )
  du.save(:validate => false)	