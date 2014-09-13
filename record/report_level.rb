require 'json'

file = File.open("level.txt", 'r')
file = file.read
temp = JSON.parse(file)
puts temp.select{|k,v| v > 15}
