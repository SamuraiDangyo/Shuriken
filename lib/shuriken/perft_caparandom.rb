##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class PerftCaparandom
	attr_accessor :board
	
	def initialize(variant, fen = nil)
		@variant = variant
		@board = Shuriken::BoardCaparandom.new(variant)
		if fen == nil
			@board.startpos(variant)
		else
			@board.use_fen(fen)
		end
	end
	
	def perft_number(depth)
		return 1 if depth == 0
		board = @board
		mgen = @board.mgen_generator
		n, moves = 0, mgen.generate_moves
		return moves.length if depth <= 1
		moves.each do |move|
			@board = move
			n += perft_number(depth - 1)
		end
		@board = board
		n
	end
	
	def perft(depth)
		puts "~~~ perft(#{depth} / #{@variant}) ~~~"
		total_time = 0
		total_nodes = 0
		copy = @board
		(depth+1).times do |i|
			start = Time.now
			@board = copy
			n = perft_number(i)
			diff = Time.now - start
			total_time += diff
			total_nodes += n
			nps = (diff == 0 or n == 1) ? n : (n / diff).to_i
			puts "#{i}: #{n} | #{diff.round(3)}s | #{nps} nps"
		end
		total_time = 1 if total_time == 0
		puts "= #{total_nodes} | #{total_time.round(3)}s | #{(total_nodes/total_time).to_i} nps"
	end
	
	def suite(depth)
		puts "~~~ suite(#{depth} / #{@variant}) ~~~"
		total_time = 0
		total_nodes = 0
		copy = @board
		(depth+1).times do |i|
			start = Time.now
			@board = copy
			n = perft_number(i)
			diff = Time.now - start
			total_time += diff
			total_nodes += n
			nps = (diff == 0 or n == 1) ? n : (n / diff).to_i
			error = ["ok", "error"][@nums[i] - n == 0 ? 0 : 1]
			break if i >= @nums.length - 1
			puts "#{i}: #{n} | #{diff.round(3)}s | #{nps} nps | #{error}"
		end
		total_time = 1 if total_time == 0
		puts "= #{total_nodes} | #{total_time.round(3)}s | #{(total_nodes/total_time).to_i} nps"
	end
end # class PerftCaparandom

end # module Shuriken
