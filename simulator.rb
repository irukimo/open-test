WIN_RATE = 0.5

INITIAL_BLOOD   = 4
PLAY_ADD_BLOOD  = 1
GUESS_ADD_BLOOD = 1
GUESS_SUBSTRACT_BLOOD = 4

def run_once
  blood = INITIAL_BLOOD
  counter = 0
  while blood > 0
    counter += 1
    blood += PLAY_ADD_BLOOD
    # you lose
    num = rand
    if num > WIN_RATE
      blood -= GUESS_SUBSTRACT_BLOOD
    else # you win
      blood += GUESS_ADD_BLOOD
    end
  end

  return counter
end


sum = 0
num_tries = 1000
(1..num_tries).each do |num|
  sum += run_once
end

puts sum.to_f/num_tries.to_f
