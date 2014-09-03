require 'json'
require 'csv'

puts 
puts "==========User number=========="

file = File.open("record/logged_in.txt", 'r').read
temp = JSON.parse(file)
puts temp.select{|k,v| v.count > 0}.count

puts 
puts "==========Code usage=========="

@tmp = File.open("record/invite_codes.txt", "r").read
@codes = JSON.parse(@tmp)

people_who_used_one_code    = @codes.select{|name, value| value.select{|code| code[1] == true}.count == 1 }.keys
people_who_used_two_codes   = @codes.select{|name, value| value.select{|code| code[1] == true}.count == 2 }.keys
people_who_used_three_codes = @codes.select{|name, value| value.select{|code| code[1] == true}.count == 3 }.keys
num_people_who_issued_codes     = @codes.select{|name, value| value.count > 0 }.count

puts "People who used a code (%d/%d):" % [people_who_used_one_code.count,     num_people_who_issued_codes]
puts people_who_used_one_code.join(', ')
puts "People who used 2 codes (%d/%d):" % [people_who_used_two_codes.count,    num_people_who_issued_codes] 
puts people_who_used_two_codes.join(', ')
puts "People who used 3 codes (%d/%d):" % [people_who_used_three_codes.count,  num_people_who_issued_codes] 
puts people_who_used_three_codes.join(', ')


puts 
puts "==========Code usage=========="
