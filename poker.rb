require 'securerandom'
require 'pp'

$generationNum = 0
$show_gens = false
$show_gens = false
$bestHand  = []

class Poker
	def initialize
	@cards = ["2C","3C","4C","5C","6C","7C","8C","9C","10C","JC","QC","KC","AC",
		      "2D","3D","4D","5D","6D","7D","8D","9D","10D","JD","QD","KD","AD",
		  	  "2H","3H","4H","5H","6H","7H","8H","9H","10H","JH","QH","KH","AH",
		  	  "2S","3S","4S","5S","6S","7S","8S","9S","10S","JS","QS","KS", "AS"]
	end

 def createHand
 	hand =[]
 	while hand.size() != 5
 	 r= SecureRandom.random_number(52)
 	 if (!hand.find_index(r))
 	 	hand << r
 	 end
 	end
 	hand
 end

 def getCards(hand)
 	temp = []
 	for i in 0...hand.count
 		temp[i] = @cards[hand[i]]
 	end
 	temp
 end

 def checkSuit(card)
 	(card)/13
 end

 def checkRank(card)
 	cardmod = card+1
 	cardmod%13
 end

 def isRoyal(hand)
 	if checkSuit(hand[0]) == checkSuit(hand[1]) && checkSuit(hand[0]) == checkSuit(hand[2]) &&checkSuit(hand[0]) == checkSuit(hand[3]) &&checkSuit(hand[0]) == checkSuit(hand[4])
 		if checkRank(hand[0]) == 9 && checkRank(hand[1]) == 10 && checkRank(hand[2]) == 11 && checkRank(hand[3]) == 12 && checkRank(hand[4]) == 0 
 		   true
 		 else
 		 	false
 		end 	
 	else
 		false
 	end
 end


 def counter(hand)
 	count = Array.new(13,0)
 	for i in 0...hand.size()
 		count[checkRank(hand[i])] +=1;
 	end
 	count.sort()
 end

 def validateHand(hand)
 	if hand.uniq.size() == 5
 		true
 	else
 		false
    end
 end

 def fitCards(hand)
 	fit =0
 	counter = self.counter(hand)
 	for i in 0..hand.size-1
 		if checkRank(hand[i]) == 9 || checkRank(hand[i]) == 10 || 
 		   checkRank(hand[i]) == 11|| checkRank(hand[i]) == 12 
 		   fit += checkRank(hand[i])
 		elsif checkRank(hand[i]) == 0 
 			fit += 13
 		end
 	end
 	fit / counter.last
 end

 def fitnessFunction(hand)
 	temp = hand.sort()
 	if isRoyal(temp)
 		1024
 	else
 		fitCards(hand)
 	end
 end
end


class Genetic

	def initialize
		@set = []
		@poker = Poker.new

		for i in 0..25
			@set[i] =@poker.createHand
		end
	end

	def checkPob
		 @set.map! {|x| x.sort()}
		 similar = @set.uniq
		 if similar.count == 1 || similar.count ==2
		 	true
		 else
		 	false
		 end
	end

	def printSet
		temp = @set.clone
		temp.map! {|x| @poker.getCards(x)}
	end

	def getFitSum
		sum =0
		fits = []
		for i in 0...@set.size()
			sum += @poker.fitnessFunction(@set[i])
			fits[i] = @poker.fitnessFunction(@set[i])
		end
		sum

	end


	def reproduce
		temp = []
		mean = self.getFitSum.to_f
		fits = []
		for i in 0..@set.size-1
			fits[i] = @poker.fitnessFunction(@set[i])/mean
		end
		i=0
		while temp.size !=@set.size
			 r= SecureRandom.random_number(100) /100.0
			 if fits[i] >= r
			 	temp << @set[i]
			 end
			 i = (i+1)% @set.size
		end
		@set = temp
		

	end
	
	def cross
		temp = []
		i=0
		while temp.size != @set.size
			r= SecureRandom.random_number(4)
			temp1 =[]
			temp2 =[]
			arr1 = @set[i]
			arr2 = @set[i*2 % @set.size-1]			
			for j in 0..4
				if j <= r
					temp1[j] = arr1[j]
					temp2[j] = arr2[j]
				else
					temp1[j] = arr2[j]
					temp2[j] = arr1[j]
				end
			end
			if @poker.validateHand(temp1) && @poker.validateHand(temp2)
				temp << temp1
				temp << temp2
			end
			i = (i+1)% (@set.size()/2)
		end
		@set = temp
	end

	def xfactor(card)
		temp = card
		suit = card/13
		temp = temp%13
		r= SecureRandom.random_number(100)
		if r <= 5
			if temp >= 8 
				rand2 = SecureRandom.random_number(4)
				temp = temp + (rand2*13)
			else
				rand3 =SecureRandom.random_number(13)
				temp = rand3 + (suit*13)
			end
		else
			temp = card
		end
		temp
	end

	def mutate

		 for i in 0..@set.size-1
		 	@set[i].map! {|x| xfactor(x)}
		 end
		
	end

	def breed(stack)
		str = ""
		localhand = []
		for i in 0..$generationNum
			finalfits = []
			maxff= 0
			minff = 10000
			mean =0
			
			for j in 0..@set.count-1
				finalfits[j] = @poker.fitnessFunction(@set[j])
				mean += finalfits[j]
				if finalfits[j] >= maxff
					maxff = finalfits[j]
					indx = j
				end
				if finalfits[j] < minff
					minff = finalfits[j]
				end
			end
			mean = mean / @set.size
			str += "..................................Generation:  #{i} ......................................\n"
			str += "Best Hand #{@poker.getCards(@set[indx])}\n"
			str += "Mean Fitness Function: #{mean} \n"
			str += "Highest Fitness Function: #{maxff} \n"
			str += "Lowest Fitness Function: #{minff}\n"
			localhand = @set[indx]
			 if $show_gens
			 	str += "\n #{self.printSet}\n"
			 end
			self.reproduce
			self.cross
			self.mutate
		end
		$bestHand = localhand
		str += "--------------------------------------------------RESULTADO-----------------------------------"
		stack.para(str)
	end
end

def exec(stack)
	@gen = Genetic.new
	@gen.breed(stack)
end



$s = nil

Shoes.app(title: "Genetic Poker", width: 200, height: 200, resizable: false) {
    background white
    
    text = banner "Generation number:"
    text.style size: 12, stroke: black, margin: 10
    @generationNum = edit_line
    @c = check; para "Show generations"
    button "Start" do
    $show_gens = @c.checked?
      $generationNum = @generationNum.text.to_i	
      @w = window(width: 1000) do
        flow{
          $s = stack{}
        }
        exec($s)
        flow{
      	image "./#{$bestHand[0]}.jpg", :height => 200, :width =>100
      	image "./#{$bestHand[1]}.jpg", :height => 200, :width =>100
      	image "./#{$bestHand[2]}.jpg", :height => 200, :width =>100
      	image "./#{$bestHand[3]}.jpg", :height => 200, :width =>100
      	image "./#{$bestHand[4]}.jpg", :height => 200, :width =>100

     	}
      end
      
    
    end
 }
