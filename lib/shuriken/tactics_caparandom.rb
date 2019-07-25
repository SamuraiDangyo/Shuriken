##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

module TacticsCaparandom
	ANTITACTICS = [
		["r1a1qkbc1r/ppp2ppppp/2np1b1n2/4p5/10/1P6PP/PAPPPPPP1C/RN1BQKB1NR w KQkq - 2 6", "b2e5"],
		["r1bqckabnr/pppppppppp/2n7/10/10/3P6/PPP1PPPPPP/RNBQCKABNR w KQkq - 1 2", "c1i7"],
		["r1bqckabnr/pppppppppp/2n7/10/10/5P4/PPPPP1PPPP/RNBQCKABNR w KQkq - 1 2", "g1a7"],
		["rnabqkb1nr/pppppppppp/10/10/10/P9/APPPPPPPcP/RN1BQKBCNR w KQkq - 0 3", "a2f7"]
	]
		
	TACTICS = [
		
		["1K7k/5r4/2p1p3p1/2P1P3P1/10/10/7rqn/1b4b3 b - - 63 167", "h2h8"], # mate in 1
		["1r2nkbc1r/pppppppppp/10/2A4P2/8N1/10/PPPPPPPPPP/RN1BQKBC1R w KQk - 0 1", "c5d7"], # mate in 1
		["abr1rqnc2/ppp1pppp2/2p7/10/10/7BB1/4PPPPPP/R4K2k1 w Q - 0 1", "O-O-O"], # mate in 1
		["abr1rqnc2/ppp1pppp2/2p7/10/10/1BB7/PPPPPPP3/1k3K3R w K - 0 1", "O-O"], # mate in 1
		["rnab1kbc1r/pppppppppp/10/3n6/5q4/3P6/PPP1PPPPPP/RA1BQKBCNR b KQkq - 0 1", "d5e3"], # mate in 1
		["1n1b1kb2r/pppppppppp/5r4/3c6/10/3P6/PPP1PPPPPP/RA1BQKBCNR b KQk - 0 1", "d5e3"], # mate in 1
		["r1abqkbcnr/pppnpppppp/10/5Q4/3N6/10/PPPPPPPPPP/RNAB1KBC1R w KQkq - 0 1", "d4e6"], # mate in 1
		["q1r1k5/pp1ppppppp/10/10/10/10/2R7/2Q2K4 w - - 0 1", "c2c8"], # mate in 2
		["r1abq1kcnr/pppnpppppp/3p6/7N2/3A1Q4/10/PPPPPPPPPP/RN1B1KBC1R w KQ - 0 1", "h5i7"], # mate in 2
		["r1q2k2r1/ppp1pppppp/10/10/3R6/10/3R6/3Q1K4 w q - 0 1", "d4d8"], # mate in 3
		["rnab1kbcnr/p1pppppppp/1p8/10/9q/7P2/PPPPPPP1PP/RNABQKBCNR w KQkq - 0 1", "g1j4"] # win material
	]
	
	def TacticsCaparandom.run
		TacticsCaparandom.antitactics
		TacticsCaparandom.tactics
	end
	
	def TacticsCaparandom.antitactics
		puts "~~~ antitactics ~~~"
		score, total = 0, 0
		ANTITACTICS.each do |tactic|
			engine = Shuriken::EngineCaparandom.new("caparandom")
			engine.printinfo = false
			engine.board.use_fen(tactic[0])
			#engine.time = 25
			result = engine.think
			total += 1
			score += 1 if tactic[1] != result
			puts "#{total}. move #{result} | " + (tactic[1] != result ? "ok" : "error")
		end
		puts "= #{score} / #{total}"
	end
	
	def TacticsCaparandom.tactics
		puts "~~~ tactics ~~~"
		score, total = 0, 0
		TACTICS.each do |tactic|
			engine = Shuriken::EngineCaparandom.new("caparandom")
			engine.printinfo = false
			engine.debug = false
			engine.board.use_fen(tactic[0])
			engine.time = 100
			result = engine.think
			total += 1
			score += 1 if tactic[1] == result
			puts "#{total}. move #{result} | " + (tactic[1] == result ? "ok" : "error")
			#			return
		end
		puts "= #{score} / #{total}"
	end
end # module TacticsCaparandom

end # module Shuriken
