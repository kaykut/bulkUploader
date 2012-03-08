require 'csv'
require 'date'
no_level = ARGV[0].to_i
filename = '/Users/kaya/Desktop/' + Date.today.to_s + '-' + Time.now.hour.to_s + '-' + Time.now.min.to_s + '.csv'
au_name  = (rand*1000000000).to_i.to_s
size1 = '300x250;728x90'
size2 = 'A3:2;A4:1'
size3 = 'V400x300|300x250|728x90;V640x480|900x60|180x600'
size4 = size1 + ';' + size2
size5 = size1 + ';' + size3

File.open(filename, 'wb')

main_array = []

l1_array = []
no_level.times do |l1|
  l1_array << [au_name + '_l1_' + (l1+1).to_s, nil, nil, nil, nil]  
end

l2_array = []
l1_array.each do |r|
  (no_level+1).times do |l2|
    row = r.dup
    row[1] = au_name + '_l2_' + (l2+1).to_s
    l2_array << row
  end
end

l3_array = []
l2_array.each do |r|
  (no_level+1).times do |l3|
    row = r.dup
    row[2] = au_name + '_l3_' + (l3+1).to_s
    l3_array << row
  end
end

l4_array = []
l3_array.each do |r|
  (no_level+1).times do |l4|
    row = r.dup
    row[3] = au_name + '_l4_' + (l4+1).to_s
    l4_array << row
  end
end

l5_array = []
l4_array.each do |r|
  (no_level+1).times do |l5|
    row = r.dup
    row[4] = au_name + '_l5_' + (l5+1).to_s
    l5_array << row
  end
end


main_array.concat(l1_array)
main_array.concat(l2_array)
main_array.concat(l3_array)
main_array.concat(l4_array)
main_array.concat(l5_array)

# Top Level AU Name, 2nd Level AU Name, 3rd Level AU Name, 4th Level AU Name, 5th Level AU Name, Ad Unit Sizes, Target Window, Explicitly Targeted, Target Platform, Description 
# main_array.each { |r| r.reverse! }

main_array.each_with_index do |row, i| 
  
  rand < 0.5 ? target_platform = 'WEB' : target_platform = 'MOBILE'

  if target_platform == 'WEB'
    case i%3
    when 0
      row << size1
    when 1
      row << size3
    when 2
      row << size5
    end
  else
    case i%3
    when 0
      row << size1
    when 1
      row << size2
    when 2
      row << size4
    end
  end
  r = rand
  if r < 0.5
    row << 'TOP'
    row << 'false'
  else
    row << 'BLANK'
    row << 'true'
  end
  
  row << target_platform
  row << nil
end

CSV.open(filename, 'wb') do |csv|
  csv << ['Top Level AU Name, 2nd Level AU Name, 3rd Level AU Name, 4th Level AU Name, 5th Level AU Name, Ad Unit Sizes, Target Window, Explicitly Targeted, Target Platform, Description']

  main_array.each do |row|
    csv << row
  end
end  










