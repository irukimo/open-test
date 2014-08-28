# @@bundles[name] = [
#                    [uuid, [{qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}, 
#                            {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx},
#                            {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}],
#                     categ
#                    ],
#                   ]


  # quiz = {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}
  # 
  # bundle = [{qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}, 
            # {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx},
            # {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}]
  # 
  # parcel = [uuid, [{qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}, 
                  #  {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx},
                  #  {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}],
  #           categ
  #          ]

class Librarian

  def initialize all_names
    @data_to_record = ["records", "bundles", "bundles_played"]
    # @notifications = Hash.new
    @records = Hash.new
    @bundles = Hash.new
    @bundles_played = Hash.new
    # @unlocked_guesser_uuid = Hash.new
    all_names.each do |name|
      initialize_for_a_player name
    end
  end  

  def record_all_data
    @data_to_record.each do |name| 
      File.open("record/librarian/" + name + ".txt", 'w') do |file|
        file.write(eval("@" + name).to_json)
      end
    end
  end

  def read_all_data
    @data_to_record.each do |name|
      File.open("record/librarian/" + name + ".txt", 'r') do |file|
        temp = file.read
        code = "@" + name + "=" + "JSON.parse(temp)"
        eval(code)
      end
    end
  end

  def initialize_for_a_player name
    # @unlocked_guesser_uuid[name] = Array.new if @unlocked_guesser_uuid[name] == nil
    # @notifications[name] = Array.new if @notifications[name] == nil
    @records[name] = Array.new if @records[name] == nil
    @bundles[name] = Array.new if @bundles[name] == nil
    @bundles_played[name] = Array.new if @bundles_played[name] == nil
  end

  def add_player name
    initialize_for_a_player name
  end

  # win_record = ["true", "true", "false"]
  def record_win(guesser, bundle, author, win_record)
    
    new_bundle = Array.new(bundle)
    # puts "recordd win: " + new_bundle.inspect
    new_bundle.each_with_index do |quiz, index|
      quiz["record"] = win_record[index]
    end

    @records[author] << {"guesser" => guesser, "bundle"=>new_bundle}
  end

  # return notification for tester
  # def get_notification tester
  #   ret = Array.new(@notifications[tester])
  #   @notifications[tester] = Array.new
  #   return ret
  # end

  # def record_notification(tester, question, bet, correctness)
  #   @notifications[tester] << [question, bet, correctness]
  # end

  # def unlock_guesser(tester, uuid)
  #   @unlocked_guesser_uuid[tester] = Array.new if @unlocked_guesser_uuid[tester] == nil
  #   @unlocked_guesser_uuid[tester] << uuid
  # end

  # def is_guesser_unlocked?(tester, uuid)
  #   @unlocked_guesser_uuid[tester] = Array.new if @unlocked_guesser_uuid[tester] == nil
  #   return @unlocked_guesser_uuid[tester].include? uuid
  # end

  def get_guesser_questions(tester_name)
    guesser_questions = Hash.new
    @records[tester_name].each do |hash|
      hash["bundle"].each do |quiz|
        if guesser_questions[quiz["uuid"]] == nil
          guesser_questions[quiz["uuid"]] = {"right"=> Array.new, 
                                             "wrong"=> Array.new, 
                                             "quiz"=> quiz
                                             }
        end
        if quiz["record"] == "true"
          guesser_questions[quiz["uuid"]]["right"] << hash["guesser"]
        else
          guesser_questions[quiz["uuid"]]["wrong"] << hash["guesser"]
        end
      end
    end
    
    return guesser_questions.values
  end

  # return an array of records
  def wins_with_author author
    return @records[author]
  end

  def just_played name, uuid
    @bundles_played[name] << uuid
  end

  def has_played? name, uuid
    return false if @bundles_played[name] == nil
    return @bundles_played[name].include?(uuid)
  end

  # return uuid of the parcel
  def create_parcel(name, bundle, categ)
    uuid = UUIDTools::UUID.random_create.to_s
    bundle.each do |quiz|
      quiz["uuid"]   = UUIDTools::UUID.random_create.to_s
    end
    @bundles[name] = Array.new if @bundles[name] == nil
    @bundles[name] << [uuid, bundle, categ]
    return uuid
  end

  def get_parcels_for_guess(num, tester, categ, friends, fb_friends)
    #let options be friends
    
    categ_confined = Array.new
    @bundles.each{|author, parcels| 
      if categ != nil
        tmp = parcels.select{|parcel| parcel[2] == categ} 
      else
        tmp = parcels
      end
      
      tmp.each{|parcel| parcel[3] = author}
      # puts "tmp"
      # puts tmp.inspect
      categ_confined += tmp
    }

    # strip away those empty arrays
    categ_confined.select!{|parcel| !parcel.empty? and tester != parcel[3]}

    puts "get_parcels"
    puts categ_confined.map{|parcel| {uuid: parcel[0], categ: parcel[2], author: parcel[3], score: parcel[4]}}.inspect
    # parcel => [uuid, bundle, categ, author, score]
    # option: tester     +10
    # option: friends    +4
    # option: fb_friends +2
    # option: stranger   -100
    # author: friends    +2
    # author: fb_friends +1
    # author: stranger   +0
    # author: tester     -100

    categ_confined.each do |parcel| 
      score = 0
      [parcel[1][0]["option0"], parcel[1][0]["option1"]].each do |option|
        if tester == option
          score += 10
        elsif friends.include? option
          score += 4
        elsif fb_friends.include? option
          score += 2
        else
          score -= 100 # no-go
        end
      end

      # score author
      if friends.include? parcel[3]
        score += 2
      elsif fb_friends.include? parcel[3]
        score += 1
      elsif parcel[3] == tester # no-go
        score -= 100
      end

      parcel[4] = score
    end
    puts "with score"
    puts categ_confined.map{|parcel| {uuid: parcel[0], categ: parcel[2], author: parcel[3], score: parcel[4]}}.inspect
    # parcel => [uuid, bundle, categ, author, score]
    return categ_confined.select{|parcel| parcel[4] > 0 and !has_played?(tester, parcel[0])}.sort{|a,b| b[4]<=>a[4]}.slice(0, num)

  end

  def get_parcels_by_categ name, categ
    if @bundles[name] == nil
      return nil 
    else
      return @bundles[name].select{|parcel| parcel[2] == categ}
    end
  end

  def get_parcels name
    return @bundles[name]
  end

  # return questions about him/her
  # return_value = [
  #                  [bundle_uuid, index, tester_name, quiz]
  #                ]
  def get_questions_of(tester_name)
    my_questions = Array.new
    
    @bundles.each do |name, parcels|
      next if name == tester_name
      next if parcels == nil
    
      parcels.each do |parcel|
        bundle = parcel[1]
    
        if bundle[0]["option0"] == tester_name or 
           bundle[0]["option1"] == tester_name
          bundle.each_with_index do |quiz, index|
            my_array = [parcel[0], index, name, quiz]
            my_questions << my_array
          end
        end
      end
    end
    return my_questions
  end

  # return the name and the matched bundle
  def get_bundle_by_uuid uuid
    @bundles.each do |name, parcels|
      parcels.each do |parcel|
        return [name, parcel[1]] if parcel[0] == uuid
      end
    end
  end

  def get_relevant_quizzes name
    return @bundles.values.flatten(1).map{ |parcel| parcel[1]}.flatten.
               select{|quiz| (quiz["option0"] == name) or (quiz["option1"] == name)}
  end
end