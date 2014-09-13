require 'json'
require 'csv'
require 'time'
# require 'sinatra'
# require 'chartkick'

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
num_people_who_issued_codes = @codes.select{|name, value| value.count > 0 }.count

puts "People who used a code (%d/%d):" %  [people_who_used_one_code.count,     num_people_who_issued_codes]
puts people_who_used_one_code.join(', ')
puts "People who used 2 codes (%d/%d):" % [people_who_used_two_codes.count,    num_people_who_issued_codes] 
puts people_who_used_two_codes.join(', ')
puts "People who used 3 codes (%d/%d):" % [people_who_used_three_codes.count,  num_people_who_issued_codes] 
puts people_who_used_three_codes.join(', ')


puts 
puts "==========Network effect=========="

@names = JSON.parse(File.open("record/names.txt", 'r').read)
@view_ranking = JSON.parse(File.open("record/view_rankings.txt", 'r').read)
@view_report  = JSON.parse(File.open("record/view_report.txt", 'r').read)
@play_others  = JSON.parse(File.open("record/play_others.txt", 'r').read)
@play_answer  = JSON.parse(File.open("record/play_answer.txt", 'r').read)

@logged_in = JSON.parse(File.open("record/logged_in.txt", 'r').read)
@friends   = JSON.parse(File.open("record/friends.txt", 'r').read)

## VALUE
@reader_perspective = Hash.new
@writer_perspective = Hash.new
@names.each do |name|
  @reader_perspective[name] = @view_report[name].count + @view_ranking[name].count
  @writer_perspective[name] = @play_others[name].count + @play_answer[name].count
end

# normalization
@lifetime = Hash.new # in hours
@names.each do |name|
  logs = @logged_in[name]
  if logs != nil and logs.count > 0
    @lifetime[name] = ((Time.now - Time.parse(logs.first) ).to_f / 3600.0).round(0).to_f
  end
  # @lifetime[name] = 0.2 if @lifetime[name] == 0.0
end

def median(array)
  sorted = array.sort
  len = sorted.length
  return (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
end

## NETWORK SIZE
@logged_in_friends = Hash.new
@names.each do |name|
  @logged_in_friends[name] = @friends[name].select{|frd| (@logged_in[frd] != nil and @logged_in[frd].count > 0)}
end

@logged_names = Array.new
@names.each do |name|
  @logged_names << name if (@logged_in[name] != nil and @logged_in[name].count > 0)
end

def accumulate_data name_array, x_array, y_array
  tmp = Hash.new
  name_array.each do |name|
    next if name == "Albert Shih" or name == "王易如" or 
            name == "蕭文翔" or name == "ChiuHo Lin"
    x = x_array[name].count
    y = nil
    if y_array[name].class == Array
      y = y_array[name].count
    else
      y = y_array[name]
    end
    y /=  @lifetime[name]
    if tmp[x] == nil
      tmp[x] = [y, 1]
    else
      tmp[x][0] += y
      tmp[x][1] += 1
    end
  end
  return tmp
end

def accumulate_data_median name_array, x_array, y_array
  tmp = Hash.new
  name_array.each do |name|
    next if name == "Albert Shih" or name == "王易如" or 
                name == "蕭文翔" or name == "ChiuHo Lin"
    x = x_array[name].count
    y = nil
    if y_array[name].class == Array
      y = y_array[name].count
    else
      y = y_array[name]
    end
    y /=  @lifetime[name]
    if tmp[x] == nil
      tmp[x] = [y]
    else
      tmp[x] << y
    end
  end
  tmp.each_value do |val|
    val = median(val)
  end
  return tmp
end


def accumulate_data_two name_array, x_array, y1_array, y2_array
  tmp = Hash.new
  name_array.each do |name|
    next if name == "Albert Shih" or name == "王易如" or 
                name == "蕭文翔" or name == "ChiuHo Lin"
    x = x_array[name].count
    if tmp[x] == nil
      tmp[x] = [(y1_array[name] + y2_array[name]).to_f/@lifetime[name], 1]
    else
      tmp[x][0] += (y1_array[name] + y2_array[name]).to_f/@lifetime[name]
      tmp[x][1] += 1
    end
    # tmp[x][0] /= 
  end
  return tmp
end


def accumulate_data_two_max name_array, x_array, y1_array, y2_array
  tmp = Hash.new
  name_array.each do |name|
    next if name == "Albert Shih" or name == "王易如" or 
            name == "蕭文翔" or name == "ChiuHo Lin"
    x = x_array[name].count
    if tmp[x] == nil
      tmp[x] = [(y1_array[name] + y2_array[name]).to_f/@lifetime[name]]
    else
      tmp[x] << (y1_array[name] + y2_array[name]).to_f/@lifetime[name]
    end  
  end

  tmp2 = Hash.new
  tmp.each do |name, val|
    tmp2[name] = val.max
  end

  return tmp2
end

def accumulate_data_two_scatter name_array, x_array, y1_array, y2_array
  tmp = Array.new
  name_array.each do |name|
    next if name == "Albert Shih" or name == "王易如" or 
            name == "蕭文翔" or name == "ChiuHo Lin"
    x = x_array[name].count
    y = (y1_array[name] + y2_array[name]).to_f/@lifetime[name]
    tmp << [x, y]
  end

  return tmp
end


def accumulate_data_two_median name_array, x_array, y1_array, y2_array
  tmp = Hash.new
  name_array.each do |name|
    next if name == "Albert Shih" or name == "王易如" or 
                name == "蕭文翔" or name == "ChiuHo Lin"
    x = x_array[name].count
    if tmp[x] == nil
      tmp[x] = [(y1_array[name] + y2_array[name]).to_f/@lifetime[name]]
    else
      tmp[x] << (y1_array[name] + y2_array[name]).to_f/@lifetime[name]
    end  
  end

  tmp2 = Hash.new
  tmp.each do |name, val|
    tmp2[name] = median(val)
  end

  return tmp2
end

def accumulate_data_two_raw name_array, x_array, y1_array, y2_array
  tmp = Hash.new
  name_array.each do |name|
    next if name == "Albert Shih" or name == "王易如" or 
                name == "蕭文翔" or name == "ChiuHo Lin"
    x = x_array[name].count
    if tmp[x] == nil
      tmp[x] = [(y1_array[name] + y2_array[name])/@lifetime[name]]
    else
      tmp[x] << (y1_array[name] + y2_array[name])/@lifetime[name]
    end  
  end

  return tmp
end


tmp = accumulate_data(@logged_names, @logged_in_friends, @reader_perspective)
CSV.open("reader.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair[0].to_f/pair[1].to_f]
  end
end


tmp = accumulate_data(@logged_names, @logged_in_friends, @writer_perspective)
CSV.open("writer.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair[0].to_f/pair[1].to_f]
  end
end



tmp = accumulate_data_two(@logged_names, @logged_in_friends, @reader_perspective, @writer_perspective)
CSV.open("writer+reader.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair[0].to_f/pair[1].to_f]
  end
end


tmp = accumulate_data_two_median(@logged_names, @logged_in_friends, @reader_perspective, @writer_perspective)
CSV.open("writer+reader_median.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair]
  end
end


tmp = accumulate_data_two_max(@logged_names, @logged_in_friends, @reader_perspective, @writer_perspective)
CSV.open("writer+reader_max.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair]
  end
end



tmp = accumulate_data_two_median(@logged_names, @friends, @reader_perspective, @writer_perspective)
CSV.open("writer+reader_friends_median.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair]
  end
end


tmp = accumulate_data_two(@logged_names, @friends, @reader_perspective, @writer_perspective)
CSV.open("writer+reader_friends_average.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair[0].to_f/pair[1].to_f]
  end
end


tmp = accumulate_data_two_raw(@logged_names, @logged_in_friends, @reader_perspective, @writer_perspective)
CSV.open("writer+reader_raw.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair]
  end
end

tmp = accumulate_data_two_scatter(@logged_names, @logged_in_friends, @reader_perspective, @writer_perspective)
CSV.open("writer+reader_scatter.csv", "wb") do |csv|
  tmp.each do |pair|
    csv << pair
  end
end


tmp = accumulate_data(@logged_names, @logged_in_friends, @logged_in)
# puts tmp.inspect
CSV.open("logged.csv", "wb") do |csv|
  tmp.each do |x, pair|
    csv << [x, pair[0].to_f/pair[1].to_f]
  end
end