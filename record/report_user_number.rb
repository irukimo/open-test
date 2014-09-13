require 'json'

file = File.open("logged_in.txt", 'r')
file = file.read
temp = JSON.parse(file)
puts temp.select{|k,v| v.count > 0}.count
