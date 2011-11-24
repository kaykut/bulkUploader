# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

	CSV.foreach("seedData/Users.csv") do |row|

		unless count == 0
			User.create(
				:name => row[0],
				:hashed_password => row[1],
				:salt => row[2]

			)
		end

		count = count + 1

	end
