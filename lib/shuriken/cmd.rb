##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class Cmd
	attr_accessor :engine, :random_mode

	def initialize
		@variant = "caparandom" # default
		@random_mode = false
		@tokens = Tokens.new(ARGV)
		@fen = nil#"rnbqckabnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNBQCKABNR w KQkq - 0 1"
	end
	
	def name
		puts "#{Shuriken::NAME} v#{Shuriken::VERSION} by #{Shuriken::AUTHOR}"
	end
	
	def run_suite(depth = 4)
		case @variant
			when "gothic"
				Shuriken::PerftGothicCaparandom.new
			when "falcon"
				Shuriken::PerftFalconCaparandom.new
			else
				Shuriken::PerftCapablancaCaparandom.new
		end.suite([0, depth].max)
	end
	
	def randommode
		@random_mode = true
	end
	
	def mbench
		depth = 4
		val = @tokens.peek(1)
		if val != nil && val.match(/\d+/)
			@tokens.forward
			depth = @tokens.cur.to_i
		end
		run_suite(depth)
	end
	
	def perft
		depth = 3
		val = @tokens.peek(1)
		if val != nil && val.match(/\d+/)
			@tokens.forward
			depth = @tokens.cur.to_i
		end
		p = PerftCaparandom.new(@variant, @fen)
		p.perft(depth)
	end
	
	def bench
		e = Shuriken::EngineCaparandom.new(@variant, random_mode: @random_mode)
		e.bench
	end
	
	def stats
		n = 100
		val = @tokens.peek(1)
		if val != nil && val.match(/\d+/)
			@tokens.forward
			n = val.to_i
		end
		e = Shuriken::EngineCaparandom.new("falcon", random_mode: @random_mode)
		e.board.use_fen(@fen) if @fen != nil
		e.stats(n)
	end
	
	def tactics
		Shuriken::TacticsCaparandom.run
	end
	
	def fen
		@tokens.go_next
		@fen = @tokens.cur
	end
	
	def variant
		@tokens.go_next
		fail "Bad Input" unless @tokens.ok?
		@variant = @tokens.cur
	end
	
	def list
		board = Shuriken::BoardCaparandom.new(@variant)
		board.use_fen(@fen)
		mgen = board.mgen_generator
		moves = mgen.generate_moves
		i = 0
		moves.each do |b|
			puts "> #{i}: #{b.move_str}"
			i += 1
		end
	end
	
	def test
		# ...
	end
	
	def rubybench
		Shuriken::Bench.go
	end

	def xboard
		xboard = Shuriken::Xboard.new(@variant, @random_mode)
		xboard.go
	end
	
	def profile
		require 'ruby-prof'
		result = RubyProf.profile do
			e = Shuriken::EngineCaparandom.new("gothic", random_mode: @random_mode)
			e.bench
		end
		printer = RubyProf::FlatPrinter.new(result)
		printer.print(STDOUT)
	end
	
	def help
		puts "Usage: ruby shuriken.rb [OPTION]... [PARAMS]..."
		puts "-help: This Help"
		puts "-xboard: Enter Xboard Mode"
		puts "-tactics: Run Tactics"
		puts "-name: Print Name Tactics"
		puts "-rubybench: Benchmark Ruby"
		puts "-bench: Benchmark Shuriken Engine"
		puts "-mbench: Benchmark Shuriken Movegen"
		puts "-profile: Profile Shuriken"
		puts "-variant [NAME]: Set Variant (gothic / caparandom / falcon / capablanca)"
		puts "-randommode: Activate Random Mode"
		puts "-fen [FEN]: Set Fen"
		puts "-stats [NUM]: Statistical Analysis"
		puts "-list: List Moves"
		puts "-perft [NUM]: Run Perft"
	end

	def args
		help && return if ARGV.length < 1
		while @tokens.ok?
			case @tokens.cur
			when "-xboard" then # enter xboard mode
				xboard and return
			when "-mbench" then
				mbench
			when "-rubybench" then
				rubybench
			when "-bench" then
				bench
			when "-stats" then
				stats
			when "-variant" then
				variant
			when "-randommode" then
				randommode
			when "-tactics" then
				tactics
			when "-test" then
				test
			when "-name" then
				name
			when "-fen" then
				fen
			when "-profile" then
				profile
			when "-list" then
				list
			when "-help" then
				help
			else
				puts "Shuriken Error: Unknown Command: '#{@tokens.cur}'"
				return
			end
			@tokens.forward
		end
	end
end # class Cmd

end # module Shuriken
