require 'csv'
require 'json'
require 'time'

@@names = Array.new
tmp = nil
  File.open("record/names.txt") do |file|
    tmp = file.read
end
  @@names = JSON.parse(tmp)

  @@bundles = Hash.new
  @@level = Hash.new
  @@progress = Hash.new
  @@gems = Hash.new
  @@unlocked_uuid_index = Hash.new
  @@data_to_w_r = ["logged_in", "view_report", "play_answer","view_rankings","wins", "losses", "level", "progress", "unlocked_uuid_index", "coins"]
  @@wins = Hash.new
  @@losses = Hash.new

  @@view_report = Hash.new
  # @@play_others = Hash.new
  @@play_answer = Hash.new
  @@view_rankings = Hash.new
  # @@use_gems = Hash.new
  # @@unlock_someone = Hash.new
  @@logged_in = Hash.new

  @@alltimes = Hash.new
  @@returns = Hash.new

  @@names.each do |name|
    @@alltimes[name] = Array.new
  end


@@data_to_w_r.each do |name|
    File.open("record/" + name + ".txt", 'r') do |file|
      temp = file.read
      code = "@@" + name + "=" + "JSON.parse(temp)"
      eval(code)
    end
 end

File.open("record/librarian/bundles_played.txt") do |file|
  tmp = file.read
end 

@@bundle_played = JSON.parse(tmp)

File.open("record/librarian/bundles.txt") do |file|
  tmp = file.read
end 

@@bundles = JSON.parse(tmp)

File.open("general_results.csv", 'w') do |file|
      file.write("Names,# of questions played,time taken per question played,# of questions guessed,time taken per question guessed,wins,losses,# game played, level,coins left,# of login,# of started creating answer,# of finished creating answer,# of guessing others,# of view report,# of view rankings,# of sessions")
      file.write("\n")
      @@names.each do |name|
        file.write(name+",")
        # # of questions played
        if @@bundles[name]
          bundle_array = @@bundles[name]
          questions_count = bundle_array.count*3
          file.write(questions_count.to_s+",")
        else
          file.write("0,")
        end
        # time taken per question played
        # if @@bundles[name]
        #   bundle_array = @@bundles[name]
        #   secs_array = Array.new
        #   bundle_array.each do |bundle|
        #     # puts bundle
        #     quiz = bundle[1]
        #     #puts "quiz:"
        #     #puts quiz
        #     #puts quiz.count
        #     timerecord = nil
        #     timerecord = Array.new
        #     quiz.each do |question|
        #       #puts Time.parse(question["time"])
        #       timerecord << Time.parse(question["time"])
        #       @@alltimes[name] << Time.parse(question["time"])
        #     end
        # if timerecord[1] != nil and timerecord[0] != nil
        #    secs_array << (timerecord[1] - timerecord[0])
        # end
        # if timerecord[2] != nil and timerecord[1] != nil
        #    secs_array << (timerecord[2] - timerecord[1])
        # end
        #   end
        #   secs_sum = secs_array.inject(:+)
        #   secs_avg = secs_sum/secs_array.count
        #   file.write(secs_avg.to_s + ",")
        # else
          file.write("N/A,")
        # end

        # # of questions guessed
        file.write( ((@@wins[name]+ @@losses[name])*3).to_s + ",")

        # time taken per questions guessed
        file.write("N/A,")

        # wins
        file.write(@@wins[name].to_s + ",")

        # losses
        file.write(@@losses[name].to_s + ",")

        # # game played
        file.write( ((@@wins[name]+ @@losses[name])).to_s + ",")

        #level
        file.write(@@level[name].to_s + ",")

        # use gems
        # file.write(@@use_gems[name].count.to_s + ",")

        # coins left
        file.write(@@coins[name].to_s + ",")


        # # of login
        file.write(@@logged_in[name].count.to_s + ",")

        # # of started creating answer
        file.write(@@play_answer[name].count.to_s + ",")

        # # of finished creating answer
        if @@bundles[name]
          file.write(@@bundles[name].count.to_s + ",")
        else
          file.write("0,")
        end

        # of finished guessing answer
        if @@bundle_played[name]
          file.write(@@bundle_played[name].count.to_s + ",")
        else
          file.write("0,")
        end

        # view report
        file.write(@@view_report[name].count.to_s + ",")

        # view rankings
        file.write(@@view_rankings[name].count.to_s + ",")

        # import all times
        playtimes = @@view_rankings[name] + @@view_report[name] + @@play_answer[name]
        if playtimes == nil
          file.write("\n")
          next
        end
        playtimes.each do |time|
          @@alltimes[name] << Time.parse(time)
        end

        if @@alltimes[name] == nil
            file.write("\n")
          next
        end
        if @@alltimes[name].count == 0
            file.write("\n")
          next
        end

        @@alltimes[name].sort!

    min_time = @@alltimes.min
    max_time = @@alltimes.max

    TIMETHRESHOLD = 180 # seconds

    @@returns[name] = Array.new


    last = @@alltimes[name][0] - 5 * TIMETHRESHOLD
    first = @@alltimes[name][0]

    @@alltimes[name].each do |time|
      if (time - last) > TIMETHRESHOLD
        @@returns[name] << [1, time]
      else
        @@returns[name].last[0] += 1
      end
      last = time
    end

    next if @@returns[name] == nil

    file.write(@@returns[name].count)

        file.write("\n")
      end
end


File.open("compare_results.csv", 'w') do |file|
      file.write("Names,question,option 1,option 2,answer")
      file.write("\n")
      @@names.each do |name|
        file.write(name+",")

        if @@bundles[name]
          bundle_array = @@bundles[name]
          secs_array = Array.new
          bundle_array.each do |bundle|
            # puts bundle
            quiz = bundle[1]
            quiz.each do |question|
              file.write(question["question"] + ',' + question["option0"] + ',' + question["option1"] + ',' + question["answer"])
              file.write("\n")
                file.write(",")
            end
          end
        else
          file.write("N/A\n")
        end


        file.write("\n")
      end
end

File.open("guess_results.csv", 'w') do |file|
      file.write("Names,guess_option_1,guess_option_2")
      file.write("\n")
      @@names.each do |name|
        file.write(name+",")

        if @@bundle_played[name]
          bundle_array = @@bundle_played[name]
          bundle_array.each do |bundle_answered|
            @@names.each do |author|
            generated_array = @@bundles[author]
            next if generated_array == nil
            generated_array.each do |bundle|
              if bundle[0] == bundle_answered
                file.write(bundle[1][0]["option0"] + ',' + bundle[1][0]["option1"])
                  file.write("\n")
                    file.write(",")
              end
            end 
            end
          end
        else
          file.write("N/A\n")
        end


        file.write("\n")
      end
end

@@questions_unlock_ranking = Hash.new

@@names.each do |name|
  next if @@unlocked_uuid_index[name] == nil
  unlocked_array = @@unlocked_uuid_index[name]
  unlocked_array.each do |unlock_package|
    @@names.each do |author|
        generated_array = @@bundles[author]
        next if generated_array == nil
        generated_array.each do |bundle|
          if bundle[0] == unlock_package[0]
            question = bundle[1][unlock_package[1].to_i]["question"]
            if @@questions_unlock_ranking[question]
              @@questions_unlock_ranking[question] = @@questions_unlock_ranking[question] + 1
            else
              @@questions_unlock_ranking[question] = 1
        end
          end
        end 
      end
    end
end

File.open("questions_unlocked_results.csv", 'w') do |file|
      file.write("Question,# of unlocks")
      file.write("\n")
      sorted_array = @@questions_unlock_ranking.sort_by {|k,v| v}.reverse
      #puts sorted_array
      sorted_array.each do |question, count|
      file.write(question + ',')
      file.write(count.to_s + ',')
          file.write("\n")
      end
end

File.open("session_times.csv", 'w') do |file|
      file.write("Name,session time,# of activities in this session")
      file.write("\n")
      @@names.each do |name|
        file.write(name+",")
        if @@returns[name] == nil or @@returns[name].count == 0
          file.write("\n")
          next
        end
        @@returns[name].each do |uniquereturn|
          file.write(uniquereturn[1].to_s+",")
          file.write(uniquereturn[0].to_s+",")
          file.write("\n")
          file.write(",")
        end 
        file.write("\n")
      end
      
end

# @@data_to_w_r.each do |name|
#     File.open(name + ".txt", 'r') do |file|
#       temp = file.read
#       code = "@@" + name + "=" + "JSON.parse(temp)"
#       eval(code)
#     end
#  end