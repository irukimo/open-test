require 'json'


# @@bundles[name] = [
#                    [uuid, [{qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}, 
#                            {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx},
#                            {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}],
#                     categ,
#                     is_anonymous
#                    ],
#                   ]
#                   

bundles = nil
File.open("bundles.txt", 'r') do |file|
  temp = file.read
  bundles = JSON.parse(temp)
end
  
bundles.each do |name, bundles_array|
  bundles_array.each do |bundle|
    author = bundle[3]
    score  = bundle[4]

    bundle[3] = "false"
    bundle[4] = author
    bundle[5] = score
  end
end

File.open("bundles_new.txt", 'w') do |file|
  file.write(bundles.to_json)
end
