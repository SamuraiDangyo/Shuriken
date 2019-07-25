##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class EngineCaparandom < Shuriken::Engine
	attr_accessor :board, :random_mode, :gameover, :move_now, :debug, :time, :movestogo, :printinfo

	INF = 1000
	MATERIAL_SCALE = 0.01
	
	def initialize(variant, random_mode: false)
		init_mate_bonus
		@board = Shuriken::BoardCaparandom.new(variant)
		@random_mode = random_mode
		@history = Shuriken::History.new
		@board.startpos(variant)
		@printinfo = true
		@time = 10 # seconds
		@movestogo = 40
		@stop_time = 0
		@stop_search = false
		@nodes = 0
		@move_now = false
		@debug = false
		@gameover = false
	end
	
	def make_move?(move)
		mgen = @board.mgen_generator
		moves = mgen.generate_moves
		moves.each do |board|
			if board.move_str == move
				@history.add(board)
				@board = board
				return true
			end
		end
		puts "illegal move: #{move}"
		false
		#fail "Shuriken Error: Illegal Move: '#{move}'"
	end
	
	def print_score(moves, depth, started)
		return unless @printinfo
		moves = moves.sort_by(&:score).reverse
		best = moves[0]
		n = (100 * (Time.now - started)).to_i
		puts " #{depth}     #{(best.score).to_i}     #{n}     #{@nodes}     #{best.move_str}"
	end
	
	def search_moves_w(cur, depth, total = 0)
		@nodes += 1
		@stop_search = (Time.now > @stop_time || total > 90)
		return 0 if @stop_search
		return MATERIAL_SCALE * cur.material if depth < 1
		mgen = Shuriken::MgenCaparandomWhite.new(cur)
		moves = mgen.generate_moves
		if moves.length == 0 # assume mate
			return 0.1 * @mate_bonus[total] * -INF
		end
		search_moves_b(moves.sample, depth - 1, total + 1)
	end
	
	def search_moves_b(cur, depth, total = 0)
		@nodes += 1
		@stop_search = (Time.now > @stop_time || total > 90)
		return 0 if @stop_search
		return MATERIAL_SCALE * cur.material if depth < 1
		mgen = Shuriken::MgenCaparandomBlack.new(cur)
		moves = mgen.generate_moves
		if moves.length == 0 # assume mate
			return 0.1 * @mate_bonus[total] * INF
		end
		search_moves_w(moves.sample, depth - 1, total + 1)
	end
	
	def search(moves)
		now = Time.now
		time4print = 0.5
		#@stop_time = now + (@time / ((@movestogo < 1 ? 30 : @movestogo) + 2)) # no time losses
		divv = @movestogo < 10 ? 20 : 30
		@stop_time = now + (@time / divv)
		depth = 2
		while true
			moves.each do | board |
				puts "> #{@nodes} / #{board.move_str}" if @debug 
				next if board.nodetype == 2
				depth = 3 + rand(20)
				board.score += board.wtm ? search_moves_w(board, depth, 0) : search_moves_b(board, depth, 0)
				if Time.now > @stop_time || @move_now
					print_score(moves, depth, now)
					return
				end
			end
			if Time.now - now > time4print
				now = Time.now
				print_score(moves, depth, now)
			end
		end
	end
	
	def draw_moves(moves)
		moves.each do | board |
			if @history.is_draw?(board)
				board.nodetype, board.score = 2, 0
			end
		end
	end
	
	def hash_moves(moves)
		moves.each { |board| board.create_hash }
	end
	
	def game_status(mgen, moves)
		if moves.length == 0
			if @board.wtm && mgen.checks_b?(@board.find_white_king)
				return Shuriken::Engine::RESULT_BLACK_WIN
			elsif !@board.wtm && mgen.checks_w?(@board.find_black_king)
				return Shuriken::Engine::RESULT_WHITE_WIN
			end
			return Shuriken::Engine::RESULT_DRAW
		end
		@board.create_hash
		if @history.is_draw?(@board, 3) || @board.material_draw?
			return Shuriken::Engine::RESULT_DRAW
		end
		0
	end
	
	def is_gameover?(mgen, moves)
		@board.create_hash
		if @history.is_draw?(@board, 3)
			puts "1/2-1/2 {Draw by repetition}"
			return true
		end
		if moves.length == 0
			if @board.wtm && mgen.checks_b?(@board.find_white_king)
				puts "0-1 {Black mates}"
			elsif ! @board.wtm && mgen.checks_w?(@board.find_black_king)
				puts "1-0 {White mates}"
			end
			puts "1/2-1/2 {Stalemate}"
			return true
		end
		false
	end

	def bench
		t = Time.now
		@time = 500
		think
		diff = Time.now - t
		puts "= #{@nodes} nodes | #{diff.round(3)} s | #{(@nodes/diff).to_i} nps"
	end
	
	def think
		@nodes = 0
		@move_now = false
		@history.reset
		board = @board
		mgen = @board.mgen_generator
		moves = mgen.generate_moves
		hash_moves(moves)
		draw_moves(moves)
		func = -> { board.wtm ? moves.sort_by(&:score).reverse : moves.sort_by(&:score) }
		@gameover = is_gameover?(mgen, moves)
		return if @gameover
		if @random_mode
			@board = moves.sample
		else
			search(moves)
			moves = func.call
			@board = moves[0]
		end
		print_move_list(moves) if @debug
		@history.add(@board)
		@board.move_str
	end
	
	def print_score_stats(results)
		wscore = results[Shuriken::Engine::RESULT_WHITE_WIN]
		bscore = results[Shuriken::Engine::RESULT_BLACK_WIN]
		draws = results[Shuriken::Engine::RESULT_DRAW]
		total = wscore + bscore + draws
		printf("[ Score: %i - %i - %i [%.2f] %i ]\n", wscore, bscore, draws, (wscore + 0.5 * draws) / total, total)
	end
	
	def stats(rounds = 10)
		rounds = 6
		@nodes = 0
		@move_now = false
		board = @board
		results = [0] * 5
		puts "Running stats ..."
		rounds.times do |n| 
			@board = board
			@history.reset
			lastboard = board
			while true
				lastboard = board
				#@board.print_board
				mgen = @board.mgen_generator
				moves = mgen.generate_moves
				hash_moves(moves)
				draw_moves(moves)
				#@board = moves.length == 0 ? lastboard : @board
				status = game_status(mgen, moves)
				@board = moves.sample
				@history.add(@board)
				if status != 0
					results[status] += 1
					break
				end
			end
			print_score_stats(results) if (n + 1) % 2 == 0 && n + 1 < rounds
		end
		puts "="
		print_score_stats(results)
	end
end # class EngineCaparandom

end # module Shuriken
