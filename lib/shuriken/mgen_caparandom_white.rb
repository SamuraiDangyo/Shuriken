##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class MgenCaparandomWhite < Shuriken::MgenCaparandom
	def initialize(board)
		super board
	end

	##
	# Utils
	##
	
	def add_new_move(me, to, type_of_move = 0) 
		fail unless good_coord?(to)
		board2 = @board
		copy = @board.copy_me
		copy.from = @from_gen
		copy.to = to
		copy.eat = copy.brd[to]
		fail "Can't eat king" if copy.eat == -6
		#fail if copy.eat == -6
		return if @only_captures && copy.eat >= 0
		copy.wtm = ! copy.wtm
		ep = copy.ep
		copy.ep = -1
		copy.r50 += 1
		copy.promo = type_of_move == MOVE_TYPE_PROMO ? me : 0
		copy.castled = 0
		copy.brd[@from_gen] = 0
		copy.brd[to] = me
		copy.r50 = 0 if copy.eat != 0
		if me == 1
			copy.r50 = 0
			copy.ep = @from_gen + 10 if type_of_move == MOVE_TYPE_EP
			copy.brd[to - 10] = 0 if to == ep
		elsif me == 6
			copy.castle &= 0x4 | 0x8
			if type_of_move == MOVE_TYPE_CASTLING
				if to == 8
					copy.castled = 1
					copy.brd[copy.castle_squares[1]] = 0 if copy.castle_squares[1] != to
					copy.brd[to - 1] = 4
				else
					copy.castled = 2
					copy.brd[copy.castle_squares[1 + 4]] = 0 if copy.castle_squares[1 + 4] != to
					copy.brd[to + 1] = 4
				end
			end
		end
		@board = copy
		if @pseudo_moves
			@moves.push << copy
		elsif !checks_b?(@board.find_white_king)
			copy.handle_castle_rights
			@moves.push << copy
		end
		@board = board2
	end
	
	# have to check promos
	def add_new_pawn_move(to)
		if to >= 70
			@promotion_to.each do | i |
				add_new_move(i, to, MOVE_TYPE_PROMO)
			end
		else
			add_new_move(1, to)
		end
	end
	
	##
	# Generate moves
	##
	
	def generate_pawn_moves_1
		to = @x_gen + (@y_gen + 1) * 10
		add_new_pawn_move(to) if (to < 80 && @board.empty?(to))
	end

	def generate_pawn_moves_2
		to = @from_gen + 2 * 10
		add_new_move(1, to, MOVE_TYPE_EP) if (y_coord(@from_gen) == 1 && @board.empty?(to - 10) && @board.empty?(to))
	end
	
	def generate_pawn_eat_moves
		[-1, 1].each do | dir |
			px, py = @x_gen + dir, @y_gen + 1
			if is_on_board?(px, py)
				to = px + py * 10
				if @board.black?(to)
					add_new_pawn_move(to)
				elsif @board.ep > 0 && to == @board.ep
					add_new_pawn_move(to)
				end
			end
		end
	end
		
	def generate_pawn_moves
		generate_pawn_moves_1
		generate_pawn_moves_2
		generate_pawn_eat_moves
	end
	
	def generate_jump_moves(jumps, me = 2)
		jumps.each do | jmp |
			px, py = @x_gen + jmp[0], @y_gen + jmp[1]
			to = px + py * 10
			add_new_move(me, to) if (is_on_board?(px, py) && @board.walkable_w?(to))
		end
	end
	
	def generate_slider_moves(slider, me = 3)
		slider.each do | jmp |
			px, py = @x_gen, @y_gen
			loop do
				px, py = px + jmp[0], py + jmp[1]
				break if !is_on_board?(px, py)
				to = px + py * 10
				add_new_move(me, to) if @board.walkable_w?(to)
				break if !@board.empty?(to)
			end
		end
	end
	
	def generate_falcon_moves
		isin = []
		Shuriken::FalconMoves::MOVES.each do | mv |
			px1, py1 = @x_gen + mv[0], @y_gen + mv[1]
			to1 = px1 + py1 * 10
			px2, py2 = px1 + mv[2], py1 + mv[3]
			to2 = px2 + py2 * 10
			px3, py3 = px2 + mv[4], py2 + mv[5]
			to3 = px3 + py3 * 10
			if is_on_board?(px1, py1) && @board.empty?(to1) && is_on_board?(px2, py2) && @board.empty?(to2) \
					and is_on_board?(px3, py3) && @board.walkable_w?(to3) && !isin.include?(to3)
				add_new_move(9, to3)
				isin.push << to3
			end
		end
	end
	
	def generate_castle_O_O_moves
		return unless @board.castle & 0x1 == 0x1
		king, rook = @board.castle_squares[0], @board.castle_squares[1]
		return unless (@board.brd[king] == 6 && @board.brd[rook] == 4)
		castle_square = @board.castle_squares[2]
		direction = @board.castle_squares[3]

		no_checks = [castle_square] # calculate no checks squares
		position = king
		loop do
			no_checks.push << position
			return if (position != king && position != rook && @board.brd[position] != 0)
			break if position == castle_square
			position += direction
		end
		return if ![0, 6].include?(@board.brd[7])

		return if any_black_checks_here? no_checks
		add_new_move(6, castle_square, MOVE_TYPE_CASTLING)
	end
	
	# setboard r4k3r/10/10/10/10/10/10/R4K3R w KQkq - 0 1
	def generate_castle_O_O_O_moves
		return unless @board.castle & 0x2 == 0x2
		king, rook = @board.castle_squares[0 + 4], @board.castle_squares[1 + 4]
		return unless (@board.brd[king] == 6 && @board.brd[rook] == 4)
		castle_square = @board.castle_squares[2 + 4]
		direction = @board.castle_squares[3 + 4]
		
		no_checks = [castle_square] # calculate no checks squares
		position = king
		loop do
			no_checks.push << position
			return if (position != king && position != rook && @board.brd[position] != 0)
			break if position == castle_square
			position += direction
		end
		return if ![0, 6].include?(@board.brd[3])
		return if (rook == 0 && @board.brd[1] != 0) # space between rook && castle square
		
		return if any_black_checks_here?(no_checks)
		add_new_move(6, castle_square, MOVE_TYPE_CASTLING)
	end
	
	def generate_moves
		@moves = []
		80.times do | i |
			@x_gen, @y_gen, @from_gen = x_coord(i), y_coord(i), i
			case @board.brd[i]
			when 1
				generate_pawn_moves
			when 2
				generate_jump_moves(KNIGHT_MOVES, 2)
			when 3
				generate_slider_moves(BISHOP_MOVES, 3)
			when 4
				generate_slider_moves(ROOK_MOVES, 4)
			when 5
				generate_slider_moves(BISHOP_MOVES + ROOK_MOVES, 5)
			when 6
				generate_jump_moves(KING_MOVES, 6)
				generate_castle_O_O_moves
				generate_castle_O_O_O_moves
			when 7
				generate_jump_moves(KNIGHT_MOVES, 7)
				generate_slider_moves(BISHOP_MOVES, 7)
			when 8
				generate_jump_moves(KNIGHT_MOVES, 8)
				generate_slider_moves(ROOK_MOVES, 8)
			when 9
				generate_falcon_moves
			end
		end
		@moves#.dup
	end
end # class MgenCaparandomWhite

end # module Shuriken
