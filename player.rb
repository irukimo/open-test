class Player
  
  attr_accessor :blood, :name, :progress

  def initialize name, initial_blood, question_count
    @blood = initial_blood
    @name = name
    @@question_count = question_count
    @progress = rand(@@question_count)
  end

  def next_question_index
    @progress += 1
    @progress = 0 if @progress >= @@question_count
    return @progress
  end
end