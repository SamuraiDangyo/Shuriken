##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class Engine
	RESULT_DRAW = 1
	RESULT_BLACK_WIN = 2
	RESULT_WHITE_WIN = 4
	
	def init_mate_bonus
		@mate_bonus = [1] * 100
		(0..20).each { |i| @mate_bonus[i] += 20 - i }
		@mate_bonus[0] = 50
		@mate_bonus[1] = 40
		@mate_bonus[2] = 30
		@mate_bonus[3] = 25
	end
		
	def history_reset
		@history.reset
	end
		
	def history_remove
		@board = @history.remove
	end
	
	def history_undo
		@board = @history.undo
	end
				
	def print_move_list(moves)
		i = 0
		moves.each do |board|
			i += 1
			puts "#{i} / #{board.move_str} / #{board.score}"
		end
	end
	
	def move_list
		mgen = @board.mgen_generator
		moves, i = mgen.generate_moves, 0
		moves.each do |board|
			i += 1
			puts "#{i} / #{board.move_str} / #{board.score}"
		end
	end
end # class Engine

end # module Shuriken
