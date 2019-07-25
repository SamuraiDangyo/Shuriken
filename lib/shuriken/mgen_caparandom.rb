##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class MgenCaparandom
	ROOK_MOVES = [[1, 0], [0, 1], [-1, 0], [0, -1]].freeze
	BISHOP_MOVES = [[1, 1], [-1, 1], [1, -1], [-1, -1]].freeze
	KING_MOVES = (ROOK_MOVES + BISHOP_MOVES).freeze
	KNIGHT_MOVES = [[1, 2], [-1, 2], [1, -2], [-1, -2], [2, 1], [-2, 1], [2, -1], [-2, -1]].freeze

	MOVE_TYPE_CASTLING = 1
	MOVE_TYPE_PROMO = 2
	MOVE_TYPE_EP = 5

	attr_accessor :pseudo_moves, :only_captures
	
	def initialize(board)
		@board, @moves = board, []
		@x_gen, @y_gen, @from_gen = 0, 0, 0 # move generation
		@x_checks, @y_checks = 0, 0 # checks
		@pseudo_moves = false # 3x speed up
		@only_captures = false # generate only captures
		@promotion_to = @board.variant == "falcon" ? [2, 3, 4, 5, 9] : [2, 3, 4, 5, 7, 8]
		@promotion_to.freeze
	end

	##
	# Utils
	##
	
	def print_move_list
		i = 0
		@moves.each do |board|
			i += 1
			puts "#{i}: #{board.move_str}"
		end
	end
	
	def is_on_board?(x, y)	
		(x >= 0 && x <= 9 && y >= 0 && y <= 7) ? true : false
	end
	
	def good_coord?(i)
		(i >= 0 && i <= 79) ? true : false
	end

	def y_coord(n)
		n / 10
	end
	
	def x_coord(n)
		n % 10 
	end

	##
	# Checks
	##
	
	def pawn_checks_w?(here)
		[-1, 1].each do |dir|
			px, py = @x_checks + dir, @y_checks + 1
			return true if is_on_board?(px, py) && px + py * 10 == here
		end
		false
	end
	
	def pawn_checks_b?(here)
		[-1, 1].each do |dir|
			px, py = @x_checks + dir, @y_checks - 1
			return true if is_on_board?(px, py) && px + py * 10 == here
		end
		false
	end

	def slider_checks_to?(slider, here)
		slider.each do |jmp|
			px, py = @x_checks, @y_checks
			while true do
				px, py = px + jmp[0], py + jmp[1]
				to = px + py * 10
				break if ! is_on_board?(px, py)
				return true if to == here
				break if ! @board.empty?(to)
			end
		end
		false
	end
	
	def jump_checks_to?(jumps, here)
		jumps.each do |jmp|
			px, py = @x_checks + jmp[0], @y_checks + jmp[1]
			to = px + py * 10
			return true if is_on_board?(px, py) && to == here
		end
		false
	end
	
	def any_black_checks_here?(no_checks)
		no_checks.each { |square| return true if checks_b?(square) }
		false
	end
	
	def any_white_checks_here?(no_checks)
		no_checks.each { |square| return true if checks_w?(square) }
		false
	end
	
	def falcon_checks?(here)
		Shuriken::FalconMoves::MOVES.each do |mv|
			px1, py1 = @x_checks + mv[0], @y_checks + mv[1]
			to1 = px1 + 10 * py1
			px2, py2 = px1 + mv[2], py1 + mv[3]
			to2 = px2 + 10 * py2
			px3, py3 = px2 + mv[4], py2 + mv[5]
			to3 = px3 + 10 * py3
			return true if (is_on_board?(px1, py1) && @board.empty?(to1) && is_on_board?(px2, py2) && @board.empty?(to2) \
					&& is_on_board?(px3, py3) && to3 == here)
		end
		false
	end

	def checks_w?(here)
		80.times do |i|
			@x_checks, @y_checks = x_coord(i), y_coord(i)
			case @board.brd[i]
			when 1
				return true if pawn_checks_w?(here)
			when 2
				return true if jump_checks_to?(KNIGHT_MOVES, here)
			when 3
				return true if slider_checks_to?(BISHOP_MOVES, here)
			when 4
				return true if slider_checks_to?(ROOK_MOVES, here)
			when 5
				return true if slider_checks_to?(ROOK_MOVES + BISHOP_MOVES, here)
			when 6
				return true if jump_checks_to?(KING_MOVES, here)
			when 7
				return true if jump_checks_to?(KNIGHT_MOVES, here) || slider_checks_to?(BISHOP_MOVES, here)
			when 8
				return true if jump_checks_to?(KNIGHT_MOVES, here) || slider_checks_to?(ROOK_MOVES, here)
			when 9
				return true if falcon_checks?(here)
			end
		end
		false
	end

	def checks_b?(here)
		80.times do | i |
			@x_checks, @y_checks = x_coord(i), y_coord(i)
			case @board.brd[i]
			when -1
				return true if pawn_checks_b?(here)
			when -2
				return true if jump_checks_to?(KNIGHT_MOVES, here)
			when -3
				return true if slider_checks_to?(BISHOP_MOVES, here)
			when -4
				return true if slider_checks_to?(ROOK_MOVES, here)
			when -5
				return true if slider_checks_to?(ROOK_MOVES + BISHOP_MOVES, here)
			when -6
				return true if jump_checks_to?(KING_MOVES, here)
			when -7
				return true if jump_checks_to?(KNIGHT_MOVES, here) || slider_checks_to?(BISHOP_MOVES, here)
			when -8
				return true if jump_checks_to?(KNIGHT_MOVES, here) || slider_checks_to?(ROOK_MOVES, here)
			when -9
				return true if falcon_checks?(here)
			end
		end
		false
	end
end # class MgenCaparandom

end # module Shuriken
