#!/usr/bin/env ruby
# encoding: utf-8
PORT = 7009
### DO NOT CHANGE ANYTHING ABOVE THIS LINE


require "addressable/uri"
require 'sinatra'
require "sinatra/multi_route"
require 'json'
require 'csv'
require 'uuidtools'
require 'twilio-ruby'
require 'time'
require 'koala'
require './librarian.rb'

# CH or EN
LANG = "CH"

IP = "10.10.6.170"
# number of digits of invitation code will be the number of digits of MAX_INVITATION_CODE - 1
MAX_INVITATION_CODE = 100000
NUMBER_INVITATION_CODE = 3
GAME_CYCLE = 600
REFILL = 480
ENERGY_CAPACITY = 5
TIME_DIFFERENCE_UPPER_BOUND = 8 * 60 * 60 # secs
TIME_DIFFERENCE_LOWER_BOUND = 5 * 60 # secs
INITIAL_COINS = 1000
PLAY_MAX_BET = 250
GUESS_MAX_BET = 100
TITLE="麻吉大學"

set :bind, '0.0.0.0'
set :port, PORT

enable :sessions

# def set_interval(delay, name)
#   @@last_time_modified[name] = Time.now
#   @@threads[name] = Thread.new do
#     loop do
#       sleep delay
#       if @@energy_left[name] < ENERGY_CAPACITY
#          @@energy_left[name] = @@energy_left[name] + 1
#          @@last_time_modified[name] = Time.now
#       end
#     end
#   end
# end

def self.import_questions
  
  @@categories = Hash.new
  @@questions = Array.new
  
  CSV.foreach("questions.csv") do |row|
    # question, value, categ, dim, att
    @@questions << row[0]
    @@categories[row[0]] = {"value"=>row[1].to_i, "categ"=>row[2], "dim"=>row[3], "att"=>row[4]}
  end

  @@questions.shuffle!
end

# run after import_questions
def self.extract_categ
  categories = @@categories.values.map{|hash| hash["categ"]}.uniq
  categories.each do |categ|
    next if categ == "F"
    CATEGORIES[categ] = Array.new
    dims = @@categories.values.select{|hash| hash["categ"] == categ}.map{|hash| hash["dim"]}.uniq
    dims.each do |dim|
        CATEGORIES[categ] << dim
    end                              
  end
end

def self.import_names
  # @@names = ["John", "Peter", "Rachel Williams", "Daniel", "Sean", "中文 名字"]
  
  @@names = Array.new
  # CSV.foreach("names.csv") do |row|
  #   @@names << row[0]
  # end
end

def self.configure_Twilio
  account_sid = "ACea251252af736aa1ea64f234945d840b"
  auth_token = "35822c755833de8c04bf3f7a1bdc9ce7"

  @@client = Twilio::REST::Client.new account_sid, auth_token
end


# assuming names and questions are set
# format: [tester, question, chosen option, unchosen option]
def self.initialize_record

  # @@tester_progress = Array.new(@@names.count, -1)
  # @@phone_number = Hash.new

  # @@unlocked = Hash.new
  # @@others_comments = Hash.new
  # @@energy_left = Hash.new
  # @@last_time_modified = Hash.new
  # @@gems = Hash.new
  # @@use_gems = Hash.new
  # prng = Random.new(1234)
  # @@score = Array.new(@@names.count){|i|Array.new(@@questions.count,prng.rand(2))}

  @@questions_left = Hash.new
  @@started_playing = Hash.new
  @@threads = Hash.new
  @@coins = Hash.new
  
  @@level = Hash.new
  @@progress = Hash.new
  
  @@unlocked_uuid_index = Hash.new
  @@data_to_w_r = ["questions_left", "started_playing", "score_buffer","logged_in","view_report","shuffle_someone", 
                   "play_others","play_answer","view_rankings","wins", "losses", "threads", 
                   "level", "progress", "unlocked_uuid_index", "coins", "record", "friends", "fb_friends", "names", "choose_categ",
                   "view_others_report","invite_someone", "add_friends", "invite_codes", "vip_codes"]
  @@wins = Hash.new
  @@losses = Hash.new

  @@view_report = Hash.new
  @@play_others = Hash.new
  @@play_answer = Hash.new
  @@view_rankings = Hash.new
  
  @@shuffle_someone = Hash.new
  @@invite_someone = Hash.new
  @@logged_in = Hash.new
  @@score_buffer = Hash.new
  @@choose_categ = Hash.new
  @@view_others_report = Hash.new
  @@add_friends = Hash.new

  @@record = Array.new 
  
  @@librarian = Librarian.new(@@names)

  @@friends = Hash.new
  @@fb_friends = Hash.new
  
  @@invite_codes = Hash.new
  @@vip_codes = Hash.new
end

# def self.initialize_independent_urls
#   @@independent_ids = Hash.new
#   prng = Random.new(1234)
#   @@names.each do |name|
#      id = (prng.rand(100000000)).to_s
#      @@independent_ids[id] = name
#   end

#   @@independent_ids.each do |id, name|
#     puts "%s->\n%s/?id=%s" % [name, URL, id]
#   end

#   File.open("private_links.txt", 'w') do |file|
#     file.write "Private links:\n"
#     @@independent_ids.each do |id, name|
#       file.write "%s -> %s/?id=%s\n" % [name, URL, id]
#     end
#   end
# end

def self.initilize_variables
  @@names.each do |name|
    @@coins[name] = INITIAL_COINS
    @@level[name] = 1
    # @@energy_left[name] = ENERGY_CAPACITY
    @@progress[name] = 0
    # @@gems[name] = 0
    @@wins[name] = 0
    @@losses[name] = 0
    @@view_report[name] = Array.new
    @@play_others[name] = Array.new
    @@play_answer[name] = Array.new
    @@view_rankings[name] = Array.new
    # @@use_gems[name] = Array.new
    @@shuffle_someone[name] = Array.new
    @@invite_someone[name] = Array.new
    @@logged_in[name] = Array.new
    @@friends[name] = Array.new
    @@fb_friends[name] = Array.new
    @@choose_categ[name] = Array.new
    @@view_others_report[name] = Array.new
    @@add_friends[name] = Array.new
    @@invite_codes[name] = Array.new
  end
end



configure do
  puts "Configuring..."
  URL = "http://%s:%s" % [IP, PORT.to_s]
  # URL = "http://machi.yoursapp.cc"
  import_questions
  import_names
  initialize_record
  configure_Twilio
  initilize_variables
  # initialize_independent_urls

  CATEGORIES = Hash.new
  extract_categ
  
end


def clear_session
    session[:choose] = nil
    session[:bundle] = nil
    session[:option0] = nil
    session[:option1] = nil
    session[:question] = nil
    session[:round] = nil
    session[:guesswhom] = nil
    session[:correct_history] = nil
    session[:xp_to_add] = nil
    session[:skippedquestions] = nil
    session[:bettingleft] = nil
end


def add_new_player
  @@names.each do |name|
    if @@coins[name] == nil then @@coins[name] = INITIAL_COINS end
    if @@level[name] == nil then @@level[name] = 1 end
    # if @@energy_left[name] == nil then @@energy_left[name] = ENERGY_CAPACITY end
    if @@progress[name] == nil then @@progress[name] = 0 end
    # if @@gems[name] == nil then @@gems[name] = 0 end
    if @@wins[name] == nil then @@wins[name] = 0 end
    if @@losses[name] == nil then @@losses[name] = 0 end
    if @@view_report[name] == nil then @@view_report[name] = Array.new end
    if @@play_others[name] == nil then @@play_others[name] = Array.new end
    if @@play_answer[name] == nil then @@play_answer[name] = Array.new end
    if @@view_rankings[name] == nil then @@view_rankings[name] = Array.new end
    # if @@use_gems[name] == nil then @@use_gems[name] = Array.new end
    if @@shuffle_someone[name] == nil then @@shuffle_someone[name] = Array.new end
    if @@logged_in[name] == nil then @@logged_in[name] = Array.new end
    if @@friends[name] == nil then @@friends[name] = Array.new end
    if @@fb_friends[name] == nil then @@fb_friends[name] = Array.new end
    if @@choose_categ[name] == nil then @@choose_categ[name] = Array.new end
    if @@view_others_report[name] == nil then @@view_others_report[name] = Array.new end
    if @@invite_codes[name] == nil then @@invite_codes[name] = Array.new end
    if @@add_friends[name] == nil then @@add_friends[name] = Array.new end
    @@librarian.add_player name
  end
end

post '/moreFriendNames' do
  selected_friend_names = params["selectedFriendNames"]
  tester = session[:tester]

  add_friend_record = Array.new
  add_friend_record << @@friends[tester].count
  add_friend_record << selected_friend_names.count
  add_friend_record << Time.now
  @@add_friends[tester] << add_friend_record
  
  puts "in moreFriendNames, tester: " + tester

  if selected_friend_names != nil
    @@friends[tester] += selected_friend_names
    @@friends[tester].uniq!
    
    @@names += selected_friend_names
    add_new_player
  end
end

post '/friendNames' do
  tester = session[:tester]

  selected_friend_names = params["selectedFriendNames"]
  
  puts "in selectedFriendNames, tester: " + tester
  puts "%s already have %d FB friends" % [tester, @@fb_friends[tester].count]
  # elem[id] = {cl: cl, nm: name};
  
  @@names += selected_friend_names
  add_new_player

  @@friends[tester] += selected_friend_names
end

route :get, :post, '/home' do
  if params["name"]
    puts "name: " + params["name"]
    session[:tester] = params["name"]
    unless @@names.include? params["name"]
      @@names << params["name"] 
      add_new_player
      tester = params["name"]

      @@friends[tester] = ["Henry", "David", "Peter"]
      @@fb_friends[tester] = [{"name"=> "Henry"}, {"name"=> "David"}, {"name"=> "Peter"}]
      add_new_player
    end

  elsif params["name"] == nil and session[:tester] == nil
    puts "**ERROR**: Wrong entry point"
    redirect to('/'), 307
  end

  tester = session[:tester]

  if @@fb_friends[tester] == nil
    puts "ERROR: fb_friends of %s is nil" % tester
  elsif @@fb_friends[tester].count == 0
    puts "ERROR: fb_friends of %s is empty" % tester
  end
    
  if @@started_playing[tester] == nil
    # set_interval(REFILL, tester)
    @@started_playing[tester] = TRUE
  end
  puts "At home, tester: " + tester
  @@logged_in[tester] << Time.now

  

  #question, bet(Integer), correctness(BOOL)
  # @notifications = @@librarian.get_notification tester

  clear_session

  view_report(tester)
  @name = tester

  fb_friend_names = @@fb_friends[@name].map{|elem| elem["name"]}
  @parcel_array = @@librarian.get_parcels_for_guess(5, @name, nil, @@friends[@name], fb_friend_names)

  # @fromWalkthrough = false
  # if params["from"] == "walkthrough"
    
  @@invite_codes[tester] = Array.new if @@invite_codes[tester] == nil
  (1..(NUMBER_INVITATION_CODE - @@invite_codes[tester].count)).each do |i|
    # [code, has_used]
    @@invite_codes[tester] << [generate_invitation_code, false]
  end

  puts @@invite_codes[tester].inspect
  @codes = @@invite_codes[tester].select{|v| v[1]==false}.map{|v| v[0]}


  if session[:fromLogin] == "true"
    @fromLogin = "true"
  else
    @fromLogin = "false"
  end
  session[:fromLogin] = nil
  # @fromWalkthrough = true
  # end

  @show_vip_code = false
  if @@vip_codes[tester] != nil
    @show_vip_code = true
    @vip_code = @@vip_codes[tester]["code"]
  end

  session[:categ] = nil

  erb :home
end


post '/hasLoggedIn' do
  tester = params["name"]
  puts "in hasLoggedIn, " + tester
  session[:fromLogin] = "true"
  session[:tester]   = tester
  session[:fb_token] = params["token"]
  puts "token: " + params["token"]

  if @@logged_in[tester] == nil or @@logged_in[tester].count == 0
    status 200
    body 'false'
  else
    status 200
    body 'true'
  end
end


post '/choose_categ' do
  erb :choose_categ
end

post '/choose_people' do
  if params[:categ]
      session[:categ] = params[:categ]
  end
  tester = session[:tester]
  
  categ_record = Array.new
  categ_record << session[:categ]
  categ_record << Time.now
  @@choose_categ[session[:tester]] << categ_record

  # add players that are tester's FB friends to tester's friends list
  fb_friend_names = @@fb_friends[tester].map{|elem| elem["name"]}
  (@@names - [tester]).each do |name|
    puts "try to add: " + name
    if @@logged_in[name] != nil and @@logged_in[name].count > 0 and fb_friend_names.include? name
      puts "%s is friends of %s on FB" % [name, tester]
      @@friends[tester] << name unless @@friends[tester].include? name
    end

    # add names that are tester's FB friends and also options of other players to tester's friend list
    @@friends[name].each do |frd|
      next if frd == tester
      puts "try to add: " + frd
      if fb_friend_names.include? frd
        puts "%s is friends of %s on FB" % [frd, tester]
        @@friends[tester] << frd unless @@friends[tester].include? frd
      end
    end
  end


  # if @@energy_left[session[:tester]] > 0
  #    @@energy_left[session[:tester]] = @@energy_left[session[:tester]] - 1
  #    if @@energy_left[session[:tester]] == 4
  #       Thread.kill(@@threads[session[:tester]])
  #       set_interval(REFILL, session[:tester])
  #    end
  # end
  if params[:addedMore] == "true" and params[:number].to_i > 1
    number = params[:number].to_i
    @initial_first, @initial_second = try_to_draw_two_fb_friended_options(tester, number)
    # @initial_first, @initial_second = @@friends[tester].slice(-number, number).sample(2)
  else
    @initial_first, @initial_second = try_to_draw_two_fb_friended_options(tester, nil)
    # @initial_first, @initial_second = @@friends[tester].sample(2)
  end
   
  erb :choose_people
end

def are_fb_friends(a, b)
  if @@fb_friends[a] == nil
    if @@fb_friends[b] == nil
      return false
    else
      return @@fb_friends[b].index{|elem| elem["name"] == a} != nil
    end
  else
    return @@fb_friends[a].index{|elem| elem["name"] == b} != nil
  end
end

def try_to_draw_two_fb_friended_options(tester, number)
  first  = nil
  second = nil
  if number != nil
    @@friends[tester].slice(-number, number).combination(2).to_a.shuffle.each do |pair|
      # puts "try number %d" % number
      # puts "%s vs %s" % pair
      if are_fb_friends(pair[0], pair[1])
        first, second = pair
        break  
      end
    end
  end

  if first == nil or second == nil
    @@friends[tester].combination(2).to_a.shuffle.each do |pair|
      # puts "not try number"
      # puts "%s vs %s" % pair
      if are_fb_friends(pair[0], pair[1])
        first, second = pair
        break  
      end
    end
  end

  if first == nil or second == nil
    if number != nil
      first, second = @@friends[tester].slice(-number, number).sample(2)
    else
      first, second = @@friends[tester].sample(2)
    end
  end

  return [first, second]
end


def already_exists(question, current_array)
  current_array.each do |quiz|
     if question == quiz["question"]
      return true
     end
  end
  return false
end

# this makes sure sampled question does not exist in bundle
def sample_questions_in_categ categ, bundle

  sample_base = 
    @@questions.select do |qs| 
      (@@categories[qs]["categ"] == categ) and 
      (bundle.index{|quiz| quiz["question"] == qs} == nil)
    end

  return sample_base.sample
end


get '/' do
  clear_session
  puts "logging in!"
  logged_in = false
  
  if logged_in
    erb :wtstart
  else
    erb :login
  end
end

get '/wtstart' do
  erb :wtstart
end

get '/wtchoose' do
  erb :wtchoose
end

get '/wtguess' do
  erb :wtguess
end
get '/wtprofile' do
  erb :wtprofile
end
get '/wtcoin' do
  erb :wtcoin
end

get '/view_others_choose_people' do
  fb_friend_names = @@fb_friends[session[:tester]].map{|elem| elem["name"]}
  @others_to_view = @@names & fb_friend_names
  erb :view_others_choose_people
end

post '/view_others_report' do 
  @@coins[session[:tester]] -= 200
  @clickedname = params[:clickedname]
  # begin
    view_report(@clickedname)
    @name = @clickedname
    erb :my_report
  # rescue
  #   @guesser_questions = Array.new
  #   @my_questions = Array.new
  #   erb :my_report_exception
  # end 
end

route :get, :post, '/view_my_report' do
  begin
    view_report(session[:tester])
    @name = session[:tester]
    erb :my_report
  rescue
    @guesser_questions = Array.new
    @my_questions = Array.new
    erb :my_report_exception
  end 
end

post '/choose_answer' do
  @@play_answer[session[:tester]] << Time.now
  if session[:choose] == nil
    session[:choose] = 1
    session[:bundle] = Array.new
  else
    session[:choose] = session[:choose] + 1
  end
  if params[:option0]
    session[:option0] = params[:option0]
  end
  if params[:option1]
    session[:option1] = params[:option1]
  end
  if params[:question]
    session[:question] = params[:question]
  end

  if params[:answer] and params[:betting]
     quiz = Hash.new
     quiz["question"] = session[:question]
     quiz["option0"] = session[:option0]
     quiz["option1"] = session[:option1]
     quiz["answer"] = params[:answer]
     quiz["time"] = Time.now

     @@coins[session[:tester]] -= params[:betting].to_i
     quiz["bet"] = params[:betting].to_i
     quiz["done"] = false
     session[:bundle] << quiz
  end
  puts "played Session " + session[:choose].to_s
  if session[:choose] == 4
    
    uuid = @@librarian.create_parcel(session[:tester], session[:bundle], session[:categ])
    puts "played over: " + uuid
    clear_session
    redirect to('/choose_ending'), 307
  end
  
  if session[:categ] == nil
    session[:categ] = 'F'
  end

  question = sample_questions_in_categ(session[:categ], session[:bundle])

  session[:question] = question
  session[:bettingleft] = (@@coins[session[:tester]] < PLAY_MAX_BET)? @@coins[session[:tester]] : PLAY_MAX_BET

  # fb_friends : [{name: "Albert Lin", closeness: 23}, {name: "Tim Lin", closeness: 20}]
  puts "options are %s, %s" % [session[:option0], session[:option1]]
  friend0 = @@fb_friends[session[:tester]].select{|frd| frd["name"] == session[:option0]}
  friend1 = @@fb_friends[session[:tester]].select{|frd| frd["name"] == session[:option1]}
  if friend0 == nil or friend1 == nil
    puts "ERROR: cannot find %s/%s in %s's FB friends" % [session[:option0], session[:option1], session[:tester]]
  end
  
  @option0_id = friend0[0]["id"]
  @option1_id = friend1[0]["id"]

  erb :choose_answer
end



def get_XP_needed(name)
  level = @@level[name]
  return level*100
end

def addupXP(value, name)
  xpneeded = get_XP_needed(name)
  progress = @@progress[name]
  xpgot = progress*xpneeded/100
  if xpgot + value >= xpneeded
    @@progress[name] = 100
    session[:xp_to_add] = xpgot + value - xpneeded
  else
    @@progress[name] = (100*((xpgot + value).to_f/xpneeded.to_f)).ceil
  end
end

post '/choose_ending' do
  @@coins[session[:tester]] = @@coins[session[:tester]] + 100
  addupXP(100, session[:tester])
  if session[:xp_to_add]
    @gonnaLevelUp = true
  else
    @gonnaLevelUp = false
  end
  erb :choose_ending
end


post '/level_up' do
  # @@energy_left[session[:tester]] = ENERGY_CAPACITY
  xp_to_add = session[:xp_to_add]
  @@level[session[:tester]] += 1
  xp_needed = get_XP_needed(session[:tester])
  @@progress[session[:tester]] = (100*(xp_to_add.to_f/xp_needed.to_f)).floor
  # @@gems[session[:tester]] =  @@gems[session[:tester]] + 1
  @@coins[session[:tester]] += 200
  if session[:atGuess] and session[:atGuess] == true
    @atGuess = true
  else
    @atGuess = false
  end
  session[:atGuess] = nil
  erb :level_up
end

post '/refill' do
  # @@use_gems[session[:tester]] << Time.now

  session[:tester] = params[:tester]
  # @@energy_left[session[:tester]] = ENERGY_CAPACITY
  # @@gems[session[:tester]] = @@gems[session[:tester]] - 1
  redirect to('/home'), 307
end


def normalize score
  multiplier = 0.10
  Math.atan(multiplier * score.to_f)/(Math::PI) + 0.5
end

def normalize_score scores
  res = Hash.new
  scores.each do |key, value| 
    if ["S", "R", "P"].include? key
      res[key] = normalize value
    elsif key == "detail"
      res[key] = Hash.new
    #value = {"S"=>{"dim1":2.0, "dim2":3.2}, "P"=>... }
      value.each {|categ, dims|
        res[key][categ] = Hash.new
        dims.each { |dim, score|
          res[key][categ][dim] = normalize score
        }
      }
    else # "time" => Time....
      res[key] = value
    end
  end
  return res
end

#  tan(0.25 * PI)/30 = m => m = 0.033
def sec_to_units seconds
  mm, ss = seconds.divmod(60)
  hh, mm = mm.divmod(60)
  dd, hh = hh.divmod(24)
  if dd > 0 
    if LANG == "CH" 
      return "%d天又%d小時前" % [dd, hh]
    else
      return "%d days, %d hours ago" % [dd, hh]
    end
    
  elsif hh > 0
    if LANG == "CH"
      return "%d小時又%d分鐘前" % [dd, hh]
    else
      return "%d hours, %d mins ago" % [hh, mm]  
    end
  else
    if LANG == "CH"
      return "%d分鐘前" % [mm]  
    else
      return "%d mins ago" % [mm]  
    end
  end
end

def view_report(name)
    if name == session[:tester]
        @@view_report[name] << Time.now
    else
        view_others_report_record = Array.new
        view_others_report_record << name
        view_others_report_record << Time.now
        @@view_others_report[name] << view_others_report_record
    end

    # @my_questions = @@librarian.get_questions_of(name)

    # @my_questions.shuffle!

    if params[:toguess]
      @toguess = params[:toguess]
    end
    #-------- Below is about calculating the spider web! --------#
    # @@generated_bundles[name] = [
    #                              [uuid, [{qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}, 
    #                                      {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx},
    #                                      {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}]]
    #                             ]


    # quiz = {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}
    # 
    # bundle = [{qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}, 
              # {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx},
              # {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}]
    # 
    # parcel = [uuid, [{qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}, 
                    #  {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx},
                    #  {qustion:xx, option0:xx, option1:xx, answer:xx, time:xx}]]

    if @@score_buffer[name] == nil
      @@score_buffer[name] = Hash.new
      @@score_buffer[name]["old"] = {"S"=>0.5, "P"=>0.5, "R"=>0.5, "time"=>Time.now, 
                                          "detail"=> {"S"=>Hash.new, "P"=>Hash.new, "R"=>Hash.new}
                                         }
      @@score_buffer[name]["new"] = {"S"=>0.5, "P"=>0.5, "R"=>0.5, "time"=>Time.now, 
                                          "detail"=> {"S"=>Hash.new, "P"=>Hash.new, "R"=>Hash.new}
                                         }
      CATEGORIES.each do |categ, dims|
        dims.each do |dim|
          @@score_buffer[name]["old"]["detail"][categ][dim] = 0.5
          @@score_buffer[name]["new"]["detail"][categ][dim] = 0.5
        end                              
      end
    end

    # for resuming the server
    @@score_buffer[name].each do |key, version|
      if version["time"].class == String
        version["time"] = Time.parse(version["time"])
      end
    end

    @scores = {"S"=>0, "P"=>0, "R"=>0, "time"=>Time.now,
               "detail" => {"S"=>Hash.new, "P"=>Hash.new, "R"=>Hash.new}
              }
    
    relevants = @@librarian.get_relevant_quizzes(name)

    CATEGORIES.each do |categ, dims|
      dims.each do |dim|
          @scores["detail"][categ][dim] = 0.0
      end                              
    end

    relevants.each do |quiz|
      next if @@categories[quiz["question"]] == nil

      category  = @@categories[quiz["question"]]["categ"]
      next if category == "F"

      value     = @@categories[quiz["question"]]["value"]
      dim       = @@categories[quiz["question"]]["dim"]
      # att       = @@categories[quiz["question"]]["att"]

      another_option = (quiz["option1"] == name) ? quiz["option0"] : quiz["option1"]
      if quiz["answer"] == name      
        @scores[category] += value
        @scores["detail"][category][dim] += value  

      elsif quiz["answer"] == another_option
        @scores[category] -= value
        @scores["detail"][category][dim] -= value
        
      end
    end
    
    # puts "score before"
    # puts @scores.inspect
    @scores = normalize_score @scores
    
    # puts "score after"
    # puts @scores.inspect

    time_diff_w_old = @scores["time"] - @@score_buffer[name]["old"]["time"]
    time_diff_w_new = @scores["time"] - @@score_buffer[name]["new"]["time"]

    # First rule: Never too old
    if time_diff_w_old > TIME_DIFFERENCE_UPPER_BOUND
      @@score_buffer[name]["old"] = @@score_buffer[name]["new"]
    # Second rule: Never too new
    elsif time_diff_w_new < TIME_DIFFERENCE_LOWER_BOUND

    else
      # Third rule: The one with larger difference stays
      diff_w_old = (@scores["S"] - @@score_buffer[name]["old"]["S"]).abs + 
                   (@scores["P"] - @@score_buffer[name]["old"]["P"]).abs + 
                   (@scores["R"] - @@score_buffer[name]["old"]["R"]).abs

      diff_w_new = (@scores["S"] - @@score_buffer[name]["new"]["S"]).abs + 
                   (@scores["P"] - @@score_buffer[name]["new"]["P"]).abs + 
                   (@scores["R"] - @@score_buffer[name]["new"]["R"]).abs

      if diff_w_new > diff_w_old
        @@score_buffer[name]["old"] = @@score_buffer[name]["new"]
      end
    end
    @@score_buffer[name]["new"] = @scores

    @time_difference = sec_to_units(@@score_buffer[name]["new"]["time"] - @@score_buffer[name]["old"]["time"])
    
    # @contributors = collect_contributors(name)

    # @guesser_questions = @@librarian.get_guesser_questions(name)
end

def generate_vip_code
  code = generate_invitation_code
  while @@vip_codes.values.map{|v| v["code"]}.include? code
    code = generate_invitation_code
  end
  return code
end

get '/process_vip' do 
  vips = nil
  begin
    vips = CSV.read("vips.csv").flatten
  rescue
    puts "ERROR: cannot read vips.csv"
    status 400
    return
  end

  vips.each do |vip|
    vip.strip!
    # checking if all vips are included in names
    unless @@names.include? vip
      puts "ERROR: cannot find %s in names" % vip
      status 400
      return
    end

    @@vip_codes[vip] = {"code"=> generate_vip_code, "times"=> 0} if @@vip_codes[vip] == nil
    puts "VIP codes:" + @@vip_codes.inspect
  end

  File.open("vip_code.txt", 'w') do |file|
    file.write "VIP Code(s):\n"
    @@vip_codes.each do |name, val|
      file.write "%s -> code: %s, times: %s\n" % [name, val["code"], val["times"]]
    end
  end
end


post '/choose_guess_categ' do
  tester = session[:tester]
  fb_friend_names = @@fb_friends[tester].map{|elem| elem["name"]}
  @disable_professional = (@@librarian.get_parcels_for_guess(1, tester, "P", @@friends[tester], fb_friend_names).count == 0)
  @disable_relationship = (@@librarian.get_parcels_for_guess(1, tester, "R", @@friends[tester], fb_friend_names).count == 0)
  @disable_social       = (@@librarian.get_parcels_for_guess(1, tester, "S", @@friends[tester], fb_friend_names).count == 0)
  @disable_fun          = (@@librarian.get_parcels_for_guess(1, tester, "F", @@friends[tester], fb_friend_names).count == 0)
  erb :choose_guess_categ
end

post '/choose_guess_people' do
  tester = session[:tester]
  if params[:categ]
    @categ = params[:categ]
    session[:categ] = params[:categ]
  else
    @categ = session[:categ] 
  end

  # puts 'categ'
  # puts @categ

  fb_friend_names = @@fb_friends[tester].map{|elem| elem["name"]}
  if params["view_all"] != "true"
    @parcel_array = @@librarian.get_parcels_for_guess(10, tester, @categ, @@friends[tester], fb_friend_names)
  else
    # view all
    @parcel_array = @@librarian.get_parcels_for_guess(nil, tester, @categ, @@friends[tester], fb_friend_names)
  end
  
  @parcel_array.shuffle
  erb :choose_guess_people
end

post '/guess' do
  @@play_others[session[:tester]] << Time.now

  if session[:round] == nil
    @@coins[session[:tester]] -= 50
    session[:round] = 1
    session[:correct_history] = Array.new
  else
    session[:round] += 1
  end

  # start the guessing
  if params[:uuid]
    session[:guesswhom],session[:bundle] = @@librarian.get_bundle_by_uuid(params[:uuid])
    session[:uuid] = params[:uuid]
    @@librarian.just_played(session[:tester], params[:uuid])
  end

  # in the middle of guessing
  if params[:correct]
    session[:correct_history] << params[:correct]
    if params[:betting]
      if params[:correct] == "true"
        @@coins[session[:tester]] += params[:betting].to_i
      else
        @@coins[session[:tester]] -= params[:betting].to_i
      end
    end
  end

  if session[:round] == 4
    redirect to('/result'), 307
  end
  # puts 'session[:bundle]'
  # puts session[:bundle]
  # puts 'session[:round]'
  # puts session[:round]
  # puts 'session[:bundle][session[:round]-1]'
  # puts session[:bundle][session[:round]-1]
  @question = session[:bundle][session[:round]-1]["question"]
  @option0 = session[:bundle][session[:round]-1]["option0"]
  @option1 = session[:bundle][session[:round]-1]["option1"]
  @answer = session[:bundle][session[:round]-1]["answer"]
  session[:bettingleft] = (@@coins[session[:tester]] < GUESS_MAX_BET)? @@coins[session[:tester]] : GUESS_MAX_BET
  erb :guess
end

# the output is a string
def generate_invitation_code
  num_digits = MAX_INVITATION_CODE.to_s.size - 1
  code = rand(MAX_INVITATION_CODE).to_s.rjust(num_digits, '0')
  while @@invite_codes.values.flatten(1).map{|v| v[0]}.index(code) != nil
    code = rand(MAX_INVITATION_CODE).to_s.rjust(num_digits, '0')
  end
  return code
end

get '/enter_code' do
  erb :enter_code
end

def ensure_fb_friends
  tester = session[:tester]
  token  = session[:fb_token]

  @@names << tester unless @@names.include? tester
  add_new_player

  if @@fb_friends[tester] == nil or @@fb_friends[tester].count == 0
    Thread.new{
      graph = Koala::Facebook::API.new(token)
      @@fb_friends[tester] = graph.get_connections("me", "friends", {"locale"=>"zh_TW"})
      puts "Received %d FB friends for %s" % [@@fb_friends[tester].count, tester]
    }
  end
end

post '/sendCode' do
  puts "code: " + params["code"]
  success = false
  inviter = nil
  code = params["code"]
  # firstly, lets see if it is a VIP code
  found = @@vip_codes.select{|inviter, val| val["code"] == code}
  if found.count == 1
    inviter = found.keys[0]
    found.values[0]["times"] += 1
    ensure_fb_friends
    
    success = true
    @msg = "Welcome! %s invited you;D" % inviter

  else # secondly, lets see if it s an invite code

    found = @@invite_codes.select{|inviter, codes| codes.map{|v| v[0]}.include? code}
    # code does not exist
    if found.count == 0
      @msg = "Code does not exist"
    elsif found.count > 1
      @msg = "Duplicate codes exist"
    else
      inviter = found.keys[0]
      found.values[0].each do |code_status|
        if code_status[0] == code
          # the code has been used before
          if code_status[1] == true
            @msg = "The code of which inviter is %s has been used before" % inviter
          # the code has not been used. Now use it
          else
            code_status[1] = true

            ensure_fb_friends

            success = true
            @msg = "Welcome! %s invited you;D" % inviter
          end
          break # since we found the code already
        end
      end    
    end
  end

  puts "Verifying code: " + @msg
  if success
    status 200
    body inviter
  else
    status 200
    body 'false'
  end
end

get '/invite_failure' do
  tester = session[:tester]
  token  = session[:fb_token]

  graph = Koala::Facebook::API.new(token)
  fb_friends = graph.get_connections("me", "friends", {"locale"=>"zh_TW"})
  puts "Received %d FB friends for %s" % [fb_friends.count, tester]

  players = @@logged_in.select{|key, val| val.count > 0}.keys
  @friends_who_play = fb_friends.select{|v| players.include? v["name"]}
  # @friends_who_play = [{"name"=>"蕭文翔", "id"=> 220104}]
  erb :invite_failure
end


post '/result' do
  # for player-side betting
  # conditions:
  # bet > 0
  # has not displayed before
  # only happen at first time being played
  tester, bundle = @@librarian.get_bundle_by_uuid(session[:uuid])
  puts "result: "
  puts bundle
  bundle.each_with_index do |quiz, index|
    if quiz["done"] == false
      puts quiz["bet"]
      puts session[:correct_history][index]

      @@coins[tester] += 2 * quiz["bet"] if session[:correct_history][index] == "true"

      if quiz["displayed"] != true
        
        # if quiz["bet"] > 0
          # tester, question, bet, correctness
        #   @@librarian.record_notification(tester, quiz["question"], 2 * quiz["bet"], 
        #                                   session[:correct_history][index] == "true")
        # end

        quiz["displayed"] = true
      end

      quiz["done"] = true
    end
  end

  @win = 0
  session[:correct_history].each do |value|
    if value == "true"
       @win += 1
    end
  end
  if @win == 0
    @reward = 10
  elsif @win == 1
    @reward = 20
  elsif @win == 2
    @reward = 40
  else
    @reward = 60
  end
  @@coins[session[:tester]] += @reward

  addupXP(@reward*3, session[:tester])
  if session[:xp_to_add]
    session[:atGuess] = true
    @gonnaLevelUp = true
  else
    @gonnaLevelUp = false
  end
    
  if @win >= 2
    @correct = true
    @@wins[session[:tester]] += 1
    @@librarian.record_win(session[:tester], session[:bundle], session[:guesswhom], session[:correct_history])
  else
    @correct = false
    @@losses[session[:tester]] += 1
  end
  clear_session
  erb :result
end


route :get, :post, '/rankings' do
  @@view_rankings[session[:tester]] << Time.now

  if session[:xp_to_add]
    redirect to('/level_up'), 307
  end

  # @sortedLevelArray = @@level.sort_by {|key,value| value}
  tester = session[:tester]
  # tmp = @@level.select{|key, value| @@friends[tester].include? key}  
  fb_friend_names = @@fb_friends[tester].map{|elem| elem["name"]}
  tmp = @@level.select{|key, value| ((fb_friend_names.include? key) or (key == tester)) and 
                                    (@@logged_in[key] != nil and @@logged_in[key].count > 0)
                      }
  # puts "ranking"
  # puts tmp
  @sortedLevelArray = tmp.sort_by {|key,value| value}
  clear_session
  erb :rankings
end

# post '/start' do
#   # if @@energy_left[session[:tester]] > 0
#   #    @@energy_left[session[:tester]] = @@energy_left[session[:tester]] - 1
#   #    if @@energy_left[session[:tester]] == 4
#   #       Thread.kill(@@threads[session[:tester]])
#   #       set_interval(REFILL, session[:tester])
#   #    end
#   # end
#   @@questions_left[session[:tester]] = 5
#   @current_tester = session[:tester]
#   #if @@questions_left[session[:tester]] == nil
#   #    @@questions_left[session[:tester]] = 10;
#   #    @@last_played[session[:tester]] = Time.now
#   #end


#   #if session[:stage] == "tel"
#   #  session[:stage] = nil
#   #  if (@@phone_number[@current_tester] == nil) or 
#   #     (params[:skip] != "yes")

#   #    phone_number = params[:phone_number]

#   #    @@client.account.messages.create(
#   #      :from => '+17183955452',
#   #      :to => phone_number,
#   #      :body => 'Welcome, %s! Ready to play the game? :-)' % @current_tester
#   #    )

#   #    @@phone_number[@current_tester] = phone_number  
#   #  end
#   #end

#   name_index = @@names.index(@current_tester)
#   if @@tester_progress[name_index] != -1
#     @current_question = @@questions[@@tester_progress[name_index]]
    
#   else
#     @current_question = @@questions.sample
#     question_index = @@questions.index(@current_question)
#     @@tester_progress[name_index] = question_index
  
#   end

#   if session[:option0] and session[:option1]
#     @current_options = [session[:option0], session[:option1]]
#   else
#     @current_options = (@@names - [@current_tester]).sample(2)  
#   end

#   session[:question] = @current_question
#   session[:option0] = @current_options[0]
#   session[:option1] = @current_options[1]
#   name_index_0 = @@names.index(@current_options[0])
#   name_index_1 = @@names.index(@current_options[1])
#   current_question_index = @@questions.index(@current_question)
#   @option_0_vote = @@score[name_index_0][current_question_index]
#   @option_1_vote = @@score[name_index_1][current_question_index]


#   if @@questions_left[session[:tester]] == 0
#     @@questions_left[session[:tester]] = nil
#     redirect to('/lobby'), 307
#   else
#     erb :question
#   end
# end

# post '/next' do
#   @@questions_left[session[:tester]] = @@questions_left[session[:tester]] -1
  
#   prev_options = [session[:option0], session[:option1]]
#   prev_question = session[:question]
#   @current_tester = session[:tester]
  
#   answer = params[:chosenName]
#   #unanswer = (prev_options[0] == answer) ? prev_options[1] : prev_options[0]

#   # record the result
#   @@record << [@current_tester, prev_question, answer, prev_options[0], prev_options[1], Time.now]

#   subject_index = @@names.index(answer)
#   # if subject_index != nil
#   #   question_index = @@questions.index(prev_question)
#   #   if question_index != nil
#   #     @@score[subject_index][question_index] += 1
#   #   end
#   # end

#   new_index = @@questions.index(prev_question) + 1
#   new_index = 0 if new_index >= (@@questions.count)

#   @current_question = @@questions[new_index]
#   name_index = @@names.index(@current_tester)
#   @@tester_progress[name_index] = new_index
#   @current_options = (@@names - [@current_tester]).sample(2)

#   session[:question] = @current_question
#   session[:option0] = @current_options[0]
#   session[:option1] = @current_options[1]
#   name_index_0 = @@names.index(@current_options[0])
#   name_index_1 = @@names.index(@current_options[1])
#   current_question_index = @@questions.index(@current_question)
#   # @option_0_vote = @@score[name_index_0][current_question_index]
#   # @option_1_vote = @@score[name_index_1][current_question_index]
  
#   if @@questions_left[session[:tester]] == 0
#     @@questions_left[session[:tester]] = nil
#     @@coins[session[:tester]] = @@coins[session[:tester]] + 10
#     redirect to('/lobby'), 307
#   else   
#     erb :question
#   end
# end

post "/unlockGuesser" do
  # puts "unlock guesser: " + params[:uuid]
  @@coins[session[:tester]] = @@coins[session[:tester]] - 100
  # @@librarian.unlock_guesser(session[:tester], params[:uuid])
  status 200
  body ''
end


post "/unlock" do
  @@unlock_someone[session[:tester]] << Time.now

  @current_tester = params[:tester]
  uuid = params[:uuid]
  index = params[:index]
  index_array = Array.new
  index_array << uuid
  index_array << index
  @@coins[@current_tester] = @@coins[@current_tester] - 300
  if @@unlocked_uuid_index[@current_tester] == nil
      uuid_index_array = Array.new
      uuid_index_array << index_array
      @@unlocked_uuid_index[@current_tester] = uuid_index_array
  else
      uuid_index_array = @@unlocked_uuid_index[@current_tester]
      uuid_index_array << index_array
  end
  status 200
  body ''
end

post "/shuffle_people" do
  @@shuffle_someone[session[:tester]] << Time.now
  @@coins[session[:tester]] = params[:coinsLeft].to_i
  
  status 200
  body ''
end

post "/invite_people" do
  @@invite_someone[session[:tester]] << Time.now
  
  status 200
  body ''
end

post "/shuffle_question" do
  @@coins[session[:tester]] = params[:coinsLeft].to_i
  if session[:skippedquestions]
    session[:skippedquestions] << params[:oldq]
  else
    session[:skippedquestions] = Array.new
    session[:skippedquestions] << params[:oldq]
  end

  loop do 
      @question = @@questions.sample
      break if !already_exists(@question, session[:bundle])
  end 
  # puts @question
  status 200
  body @question
end


get "/record_all_data" do
  @@data_to_w_r.each do |name| 
    File.open("record/" + name + ".txt", 'w') do |file|
      file.write(eval("@@" + name).to_json)
    end
  end
  @@librarian.record_all_data
  status 200
  body ''
end

get "/read_all_data" do
  @@data_to_w_r.each do |name|
    File.open("record/" + name + ".txt", 'r') do |file|
      temp = file.read
      code = "@@" + name + "=" + "JSON.parse(temp)"
      eval(code)
    end
  end
  @@librarian.read_all_data
  status 200
  body ''
end

def calculate_slowdown
  people_in_slowdown = Array.new(@@names.count)
  looping_stopper = Array.new(@@names.count, false)
  time_now = Time.now

  @@record.reverse.each do |record| 
    index = @@names.index(record[0])
    unless looping_stopper[index]    
      looping_stopper[index] = true
      people_in_slowdown[index] = (time_now - record[5]) > @slowdown_minutes * 60
      @slowdown_people << record[0] if people_in_slowdown[index]
    end

    if looping_stopper.index(false) == nil
      break
    end
  end
end

get '/admin' do
  @slowdown_minutes = 2
  @slowdown_people = Array.new

  # calculate slowdown
  calculate_slowdown #store in @slowdown_people

  # number of questions answered including the special answers
  @number_of_answered_questions = @@record.count.to_f/@@names.count.to_f


  @@names.each do |name|
    @@record.select{||}
  end
  
  erb :admin
end

post '/scores' do
  erb :scores
end

def collect_contributors name
  contributors = Array.new
  @@record.each do |row|
    answer = row[2]
    contributors << row[0] if answer == name    
  end
  return contributors.uniq
end

# get '/score' do
#   name = params[:name]
#   name_index = @@names.index(name)
  
#   @p_score = Array.new
#   @@score[name_index].each_with_index do |number, index| 
#     @p_score << [index, number]
#   end
#   @p_score.sort!{ |a, b|
#     b[1] <=> a[1]
#   }

#   @contributors = collect_contributors(name)
#   @name = name

#   erb :score
# end

get '/record' do
  erb :record
end

get '/admin/share' do
  erb :share_record
end

get '/css/*.*' do |path, ext|
  send_file 'css/' + path + '.' + ext
end

get '/fonts/*.*' do |path, ext|
  send_file 'fonts/' + path + '.' + ext
end

get '/js/*.*' do |path, ext|
  send_file 'js/' + path + '.' + ext
end

get '/img/*.*' do |path, ext|
  send_file 'img/' + path + '.' + ext
end

get '/html/*.*' do |path, ext|
  send_file 'html/' + path + '.' + ext
end

get '*.*' do |path, ext|
  send_file path + '.' + ext
end


# post '/who_to_share' do
#   erb :who_to_share
# end


# post '/share' do
#   options = [session[:option0], session[:option1]]
#   question = session[:question]
#   @current_tester = session[:tester]
#   receiver = params[:name]

#   uuid = UUIDTools::UUID.random_create.to_s
#   @@sharing_queue[uuid] = {question: question, 
#                             options: options, 
#                      time_of_asking: Time.now, 
#                               asker: @current_tester, 
#                       asker_thought: params[:thought],
#                            receiver: receiver,
#                   answered_by_asker: false}

#   link = URL + "/answer_share?uuid=" + uuid
#   message = "Hey! %s is asking you %s Click to answer! %s" % [@current_tester, question, link]
#   @@client.account.messages.create(
#     :from => '+17183955452',
#     :to => @@phone_number[receiver],
#     :body => message
#   )

#   puts link
#   redirect to('/start'), 307
# end

# get "/answer_share" do
#   uuid = params[:uuid]
#   sharing = @@sharing_queue[uuid]
  
#   @asker = sharing[:asker]
#   @question = sharing[:question]
#   @options = sharing[:options]
#   @asker_thought = sharing[:asker_thought]

#   @current_tester = sharing[:receiver]

#   session[:uuid] = uuid
#   session[:tester] = @current_tester
#   erb :answer_share
# end

# post "/why" do
#   record_index = params[:index].to_i 
#   record = @@record[record_index]
#   receiver = record[0] 
#   if receiver == session[:tester]
#     session[:reason_index] = record_index
#     redirect to('/edit_reason'), 307
#   end
#   if @@people_asks[session[:tester]] == nil
#       index_array = Array.new
#       index_array << params[:index]
#       @@people_asks[session[:tester]] = index_array
#   else
#       index_array = @@people_asks[session[:tester]]
#       index_array << params[:index]
#   end

#   if @@record_asks[record_index] == nil
#       @@record_asks[record_index] = 1;
#   else
#       @@record_asks[record_index] = @@record_asks[record_index]+1;
#   end
  
#   @current_tester = session[:tester]
#   if record[2] == record[3]
#        not_chosen = record[4]
#   else
#        not_chosen = record[3]
#   end

#   uuid = UUIDTools::UUID.random_create.to_s
#   @@asking_queue[uuid] = {recordID: params[:index],
#                           question: record[1],
#                             chosen: record[2],
#                             not_chosen: not_chosen,
#                      time_of_asking: Time.now,
#                               asker: @current_tester,
#                            receiver: receiver,
#                   answered_by_asker: false}

#   link = URL + "/answer_ask?uuid=" + uuid
  
#   begin 
#      message = "Hey! %s is asking you why you chose %s in the question %s Click to answer! %s" % [@current_tester, record[2], record[1], link]
#      @@client.account.messages.create(
#        :from => '+17183955452',
#        :to => @@phone_number[receiver],
#        :body => message
#      )
#   rescue
#   end

#   redirect to('/lobby'), 307
# end

# post "/edit_reason" do
#   erb :edit_reason
# end

# post "/edit_comment" do
#   session[:comment_index] = params[:index].to_i
#   erb :edit_comment
# end

# post "/done_reason" do
#   index = session[:reason_index]
#   session[:reason_index] = nil
#   if @@record_comments[index] == nil
#       comment_array = Array.new
#       comment_array << params[:thought]
#       @@record_comments[index] = comment_array
#   else
#       comment_array = @@record_comments[index]
#       comment_array << params[:thought]
#   end
#   redirect to('/lobby'), 307
# end

# post "/done_comment" do
#   index = session[:comment_index]
#   session[:comment_index] = nil
#   if @@others_comments[index] == nil
#       comment = Array.new
#       comment[0] = session[:tester]
#       comment[1] = params[:thought]
#       comments_array = Array.new
#       comments_array << comment
#       @@others_comments[index] = comments_array
#   else
#       comment = Array.new
#       comment[0] = session[:tester]
#       comment[1] = params[:thought]
#       comments_array = @@others_comments[index]
#       comments_array << comment
#   end
#   redirect to('/lobby'), 307
# end

# get "/answer_ask" do
#   uuid = params[:uuid]
#   session[:uuid] = uuid
#   asking = @@asking_queue[uuid]

#   @asker = asking[:asker]
#   @question = asking[:question]
#   @chosen = asking[:chosen]
#   @not_chosen = asking[:not_chosen]

#   @current_tester = asking[:receiver]

#   session[:uuid] = uuid
#   session[:tester] = @current_tester
#   erb :answer_ask
# end

# post "/reply_ask" do
#   uuid = session[:uuid]
#   session[:uuid] = nil

#   @@asking_queue[uuid][:receiver_thought] = params[:thought]
#   @@asking_queue[uuid][:time_of_replying] = Time.now

#   record_index = @@asking_queue[uuid][:recordID].to_i
#   if @@record_comments[record_index] == nil
#       comment_array = Array.new
#       comment_array << params[:thought]
#       @@record_comments[record_index] = comment_array
#   else
#       comment_array = @@record_comments[record_index]
#       comment_array << params[:thought]
#   end

#   redirect to('/lobby'), 307
# end

# post "/reply_share" do
#   name = params[:name]
#   uuid = session[:uuid]
#   session[:uuid] = nil

#   @@sharing_queue[uuid][:answer] = name
#   @@sharing_queue[uuid][:receiver_thought] = params[:thought]
#   @@sharing_queue[uuid][:time_of_replying] = Time.now


#   uri = Addressable::URI.parse(URL + "/sharing_history")
#   uri.query_values = {
#     'tester'  => @@sharing_queue[uuid][:asker]
#   }

#   puts uri.to_s
#   # link = URL + "/sharing_history?tester=" + 
#   message = "%s replied your question! Go to Check sharing! to see it! %s" % [@@sharing_queue[uuid][:receiver], uri.to_s]

#   @@client.account.messages.create(
#     :from => '+17183955452',
#     :to => @@phone_number[@@sharing_queue[uuid][:asker]],
#     :body => message
#   )

#   redirect to('/start'), 307
# end

# get "/sharing_history" do 
#   session[:tester] = params[:tester] if params[:tester]
    
#   tmp = @@sharing_queue.select do |uuid, share| 
#     (share[:asker] == session[:tester])
#   end

#   if tmp
#     @sharings = tmp.values
#   else
#     @sharings = Array.new
#   end

#   erb :sharing_history
# end
# 
# 
# get '/tel' do
#   session[:stage] = "tel"

#   ##hacking to play
#   puts params[:num] 
#   if params[:num] == "1"
#     session[:tester] = "Iru Wang"
#   elsif params[:num] == "2"
#     session[:tester] = "Chiu-Ho Lin"
#   else
#     session[:tester] = "Wen Shaw"
#   end
#   @@names << "Iru Wang"
#   @@names << "Chiu-Ho Lin"
#   @@names << "Wen Shaw"
#   add_new_player
#   ###end hack

#   @current_tester = session[:tester]  
#   erb :tel
# end
# 
# # post '/welcome' do
#   @current_tester = session[:tester]

#   if session[:stage] == "tel"
#     session[:stage] = nil
#     if (@@phone_number[@current_tester] == nil) or 
#        (params[:skip] != "yes")

#       phone_number = params[:phone_number]

#       @@phone_number[@current_tester] = phone_number  
#     end
#   end
#   if @@started_playing[session[:tester]] == nil
#      # set_interval(REFILL, session[:tester])
#      @@started_playing[session[:tester]] = TRUE
#   end
#   @@logged_in[session[:tester]] << Time.now
#   redirect to('/home'), 307
# end
