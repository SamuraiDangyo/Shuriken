##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class BoardCaparandom < Shuriken::Board
	GOTHIC_POS = "rnbqckabnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNBQCKABNR w KQkq - 0 1"
	CAPA_POS = "rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0 1"
	FALCON_POS = "rnbfqkfbnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNBFQKFBNR w KQkq - 0 1"
	
	PIECES = {
		".": 0,
		"P": 1, # Pawn
		"p": -1,
		"N": 2, # Knight
		"n": -2,
		"B": 3, # Bishop
		"b": -3,
		"R": 4, # Rook
		"r": -4,
		"Q": 5, # Queen
		"q": -5,
		"K": 6, # King
		"k": -6,
		"A": 7, # Arcbishop
		"a": -7,
		"C": 8, # Chancellor
		"c": -8,
		"F": 9, # Falcon
		"f": -9
	}.freeze
	
	attr_accessor :brd, :variant, :nodetype, :hash, :ep, :wtm, :eat, :from, :to, :castle, :castle_squares, :r50, :score, :promo, :castled, :index
	
	def initialize(variant)
		@variant = variant
		initme
	end

	def initme
		@brd = [0] * 80
		@castle, @ep, @wtm, @from, @to, @r50, @eat = 0, -1, true, 0, 0, 0, 0
		@score, @promo, @castled = 0, 0, 0
		# white O-O   : [ king_pos, rook_pos, castle_square, direction ]
		# white O-O-O : [ king_pos, rook_pos, castle_square, direction ]
		@castle_squares = [-1] * 2 * 4
		@index = 0
		@hash = 0
		@nodetype = 0 # 2 draw 1 win -1 loss
	end
	
	def mgen_generator
		@wtm ? Shuriken::MgenCaparandomWhite.new(self) : Shuriken::MgenCaparandomBlack.new(self)
	end
	
	def create_hash
		@hash = 0
		80.times do | i |
			@hash ^= Shuriken::Zobrist.get(20 * i + 8 + @brd[i])
		end
		@hash ^= Shuriken::Zobrist.get(20 * 80 + (@wtm ? 1 : 0))
		@hash ^= Shuriken::Zobrist.get(20 * 81 + (@ep == -1 ? 1 : 0))
		@hash ^= Shuriken::Zobrist.get(20 * 82 + @castle)
	end
	
	# TODO write castling stuff
	def legal?
		pieces = [0] * 20
		@brd.each { |p| pieces[p + 9] += 1 }
		return false if pieces[-6 + 9] == 0 || pieces[6 + 9] == 0
		true
	end
		
	def move_str
		return "O-O" if (@castled == 1 && @variant == "caparandom")
		return "O-O-O" if (@castled == 2 && @variant == "caparandom")
		fromx, fromy = x_coord(@from), y_coord(@from)
		tox, toy = x_coord(@to), y_coord(@to)
		s = ("a".ord + fromx).chr
		s << (fromy + 1).to_s
		s << ("a".ord + tox).chr
		s << (toy + 1).to_s
		ps = @variant == "falcon" ? "nbrqkkkf" : "nbrqkac"
		if @promo > 1
			s << ps[@promo - 2]
		elsif @promo < -1
			s << ps[-@promo - 2]
		end
		s
	end
	
	def make_move(me, from, to)
		fail unless (good_coord?(from) && good_coord?(to))
		@eat = @brd[to]
		@ep = -1
		@r50 += 1
		@brd[to] = me
		@brd[from] = 0
		@r50 = 0 if @eat
		if @wtm
			if me == 1
				@r50 = 0
				@ep = from + 10 if (y_coord(from) == 1 && y_coord(to) == 3)
			elsif me == 6
				@castle &= 0x4 | 0x8
			end
		else
			if me == -1
				@r50 = 0
				@ep = from - 10 if (y_coord(from) == 8 - 2 && y_coord(to) == 8 - 4)
			elsif me == -6
				@castle &= 0x1 | 0x2
			end
		end
		handle_castle_rights
	end
	
	def find_white_king
		#80.times do |i|
		#	return i if @brd[i] == 6
		#end
		#fail
		@brd.index { | x | x == 6 }
	end
	
	def find_black_king
		#80.times do |i|
		#	return i if @brd[i] == -6
		#end
		#fail
		@brd.index { | x | x == -6 }
	end
	
	def find_piece_all(piece)
		@brd.index { | x | x == piece }
	end
	
	# scans ->
	def find_piece(start_square, end_square, me, diff = 1)
		i = start_square
		loop do
			return i if @brd[i] == me
			fail "Shuriken Error: Couldn't Find: '#{me}'" if i == end_square
			i += diff
		end
	end
	
	# scans ->
	def just_kings?
		80.times do |i|
			return false if (@brd[i] != 6 && @brd[i] != -6)
		end
		true
	end
	
	def material_draw?
		80.times do |i|
			return false if (@brd[i] != 6 && @brd[i] != -6 && @brd[i] != 0)
		end
		true
	end
	
	def handle_castle_rights
		if @castle & 0x1 == 0x1
			@castle &= (0x2 | 0x4 | 0x8) if @brd[@castle_squares[1]] != 4
		end
		if @castle & 0x2 == 0x2
			@castle &= (0x1 | 0x4 | 0x8) if @brd[@castle_squares[1 + 4]] != 4
		end
		if @castle & 0x4 == 0x4
			@castle &= (0x1 | 0x2 | 0x8) if @brd[70 + @castle_squares[1]] != -4
		end
		if @castle & 0x8 == 0x8
			@castle &= (0x1 | 0x2 | 0x4) if @brd[70 + @castle_squares[1 + 4]] != -4
		end
	end
	
	def make_castle_squares
		if @castle & 0x1 == 0x1
			king = find_piece(0, 10 - 1, 6, 1)
			rook_r = find_piece(king, 10 - 1, 4, 1)
			castle_square = 10 - 2 
			@castle_squares[0] = king
			@castle_squares[1] = rook_r
			@castle_squares[2] = castle_square
			@castle_squares[3] = king < castle_square ? 1 : -1
		end
		if @castle & 0x2 == 0x2
			king = find_piece(0, 10 - 1, 6, 1)
			rook_l = find_piece(king, 0, 4, -1)
			castle_square = 2 
			@castle_squares[4] = king
			@castle_squares[5] = rook_l
			@castle_squares[6] = castle_square
			@castle_squares[7] = king < castle_square ? 1 : -1
		end
		if @castle & 0x4 == 0x4
			king = find_piece(10 * 8 - 10, 10 * 8 - 1, -6, 1)
			rook_r = find_piece(king, 10 * 8 - 1, -4, 1)
			castle_square = 10 * 8 - 2
			pos = 10 * 8 - 10
			@castle_squares[0] = king - pos
			@castle_squares[1] = rook_r - pos
			@castle_squares[2] = castle_square - pos
			@castle_squares[3] = king < castle_square ? 1 : -1
		end
		if @castle & 0x8 == 0x8
			king = find_piece(10 * 8 - 10, 10 * 8 - 1, -6, 1)
			rook_l = find_piece(king, 10 * 8 - 10, -4, -1)
			castle_square = 10 * 8 - 10 + 2
			pos = 10 * 8 - 10
			@castle_squares[4] = king - pos
			@castle_squares[5] = rook_l - pos
			@castle_squares[6] = castle_square - pos
			@castle_squares[7] = king < castle_square ? 1 : -1
		end
	end

	def copy_me()
		copy = Shuriken::BoardCaparandom.new(@variant)
		copy.brd = @brd.dup
		copy.castle_squares = @castle_squares.dup
		copy.castle = @castle
		copy.ep = @ep
		copy.wtm = @wtm
		copy.from = @from
		copy.to = @to
		copy
	end

	def startpos(spos)
		pos = case spos
			when "gothic"
				GOTHIC_POS
			when "capablanca"
				CAPA_POS
			when "falcon"
				FALCON_POS
			else
				CAPA_POS
		end
		use_fen(pos)
	end

	def use_fen(pos)
		initme
		fen(pos)
		make_castle_squares
	end

	def y_coord(n)
		n / 10
	end
	
	def x_coord(n)
		n % 10 
	end
	
	def last_rank?(square)
		y_coord(square) == 7 ? true : false
	end
	
	def first_rank?(x)
		y_coord(x) == 0 ? true : false
	end
	
	def empty?(i)
		@brd[i] == 0 ? true : false
	end
	
	def walkable_w?(square)
		@brd[square] < 1 ? true : false
	end
	
	def walkable_b?(square)
		@brd[square] > -1 ? true : false
	end
	
	def black?(square)
		@brd[square] < 0 ? true : false
	end
	
	def white?(square)
		@brd[square] > 0 ? true : false
	end
	
	def is_on_board?(x, y)	
		(x >= 0 && x < 10 && y >= 0 && y < 8) ? true : false
	end
	
	def good_coord?(i)	
		(i >= 0 && i < 80) ? true : false
	end
	
	def mirror_board
		half = ((10 * 8) / 2 - 1).to_i
		(0..half).each do | i |
			x, y = x_coord(i), y_coord(i)
			flip_y = x + (8 - 1 - y) * 10
			p1 = @brd[i]
			p2 = @brd[flip_y]
			@brd[i] = p2
			@brd[flip_y] = p1
		end
	end
	
	def flip_coord(coord)
		(8 - 1 - y_coord(coord)) * 10 + x_coord(coord)
	end
	
	def fen_board(s)
		i = 0
		s.gsub(/\d+/) { | m | "_" * m.to_i }
			.gsub(/\//) { | m | "" }
			.each_char do | c |
				PIECES.each do | pie, num |
					if c == pie.to_s
						@brd[i] = num
						break
					end
				end
				i += 1
			end
	end
	
	def fen_wtm(s)
		@wtm = s == "w" ? true : false
	end
	
	def fen_KQkq(s)
		found = false
		s.each_char do | c |
			{0x1 => "K", 0x2 => "Q", 0x4 => "k", 0x8 => "q"}.each do | a, b |
				if c == b
					@castle |= a 
					found = true
				end
			end
		end
		return if found
		# caparandom castling
		# setboard 3rkcnrbb/pppn1ppppp/3p6/4p5/7P1P/6CB2/PPPPPPPP1B/RNAQK2R2 w HAh - 1 8
		wking, bking = find_piece_all(6) - 70, find_piece_all(-6)
		s.each_char do | c |
			if ("A".."J").include? c
				num = c.ord - "A".ord
				@castle |= num > wking ? 0x1 : 0x2
			elsif ("a".."j").include? c
				num = c.ord - "a".ord
				@castle |= num > bking ? 0x4 : 0x8
			end
		end
	end
	
	def fen_ep(s)
		return if (s == "-" or s.length < 2)
		@ep = (s[0].ord - "a".ord) + 10 * s[1].to_i
	end
	
	def fen_r50(s)
		@r50 = s.to_i
	end
	
	def fen(str)
		initme
		s = str.strip.split(" ")
		fen_board(s[0]) if s.length >= 0
		fen_wtm(s[1]) if s.length >= 1
		fen_KQkq(s[2]) if s.length >= 2
		fen_ep(s[3]) if s.length >= 3
		fen_r50(s[4]) if s.length >= 4
		mirror_board
	end
	
	def str_castle
		s = ""
		{"K" => 0x1, "Q" => 0x2, "k" => 0x4, "q" => 0x8}.each do |a, b|
			s += a if @castle.to_i & b == b
		end
		s.empty? ? "-" : s
	end

	def eval
		Shuriken::EvalCaparandom.eval(self)
	end

	def material
		Shuriken::EvalCaparandom.material(self)
	end
		
	def print_board
		s =""
		flip_it = false
		80.times do | i |
			x, y = x_coord(i), y_coord(i)
			p = @brd[x + (8 - y - 1) * 10]
			if flip_it
				p = -@brd[x + y * 10]
			end
			ch = "."
			PIECES.each do |pie, num|
				if num.to_s == p.to_s
					ch = pie.to_s
				end
			end
			s << ch
   			if (i + 1) % 10 == 0
				s << " " + ((8 - i / 10).to_i).to_s + "\n"
   			end
		end
		10.times { |i| s << ("a".ord + i).chr }
		s << "\n[ wtm: #{@wtm} ]\n"
		s << "[ castle: #{str_castle} ]\n"
		s << "[ ep: #{@ep} ]\n\n"
		puts s
	end
end # class BoardCaparandom

end # module Shuriken
