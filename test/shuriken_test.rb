require 'minitest/autorun'
require 'shuriken'

class ShurikenTest < Minitest::Test
 	def test_capablanca_mgen
		p = Shuriken::PerftCapablancaCaparandom.new
    	assert_equal(1, p.perft_number(0))
    	assert_equal(28, p.perft_number(1))
    	assert_equal(784, p.perft_number(2))
    	#assert_equal(25228, p.perft_number(3))
  	end
  	
 	def test_gothic_mgen
		p = Shuriken::PerftGothicCaparandom.new
    	assert_equal(1, p.perft_number(0))
    	assert_equal(28, p.perft_number(1))
    	assert_equal(784, p.perft_number(2))
    	#assert_equal(25283, p.perft_number(3))
  	end
  	
 	def test_falcon_mgen
		p = Shuriken::PerftFalconCaparandom.new
		p.board.use_fen("5k4/10/10/10/3F6/10/10/5K4 w - - 0 1")
    	assert_equal(1, p.perft_number(0))
    	assert_equal(20, p.perft_number(1))
    	
		p = Shuriken::PerftFalconCaparandom.new
		p.board.use_fen("k9/10/3f6/10/10/10/3K6/10 w - - 0 1")
    	assert_equal(1, p.perft_number(0))
    	assert_equal(6, p.perft_number(1))
    	
		p = Shuriken::PerftFalconCaparandom.new
		p.board.use_fen("10/10/3f3K2/10/10/10/10/k9 w - - 0 1")
    	assert_equal(1, p.perft_number(0))
    	assert_equal(6, p.perft_number(1))
    	
		p = Shuriken::PerftFalconCaparandom.new
		p.board.use_fen("10/10/3f2K3/10/10/10/10/k9 w - - 0 1")
    	assert_equal(1, p.perft_number(0))
    	assert_equal(6, p.perft_number(1))
    	
		p = Shuriken::PerftFalconCaparandom.new
		p.board.use_fen("10/10/2K7/10/5f4/10/10/k9 w - - 0 1")
    	assert_equal(1, p.perft_number(0))
    	assert_equal(6, p.perft_number(1))
    	
		p = Shuriken::PerftFalconCaparandom.new
		p.board.use_fen("10/10/10/10/5f4/10/3K6/k9 w - - 0 1")
    	assert_equal(1, p.perft_number(0))
    	assert_equal(4, p.perft_number(1))
    	
		p = Shuriken::PerftFalconCaparandom.new
		p.board.use_fen("10/10/10/7K2/5f4/10/10/k9 w - - 0 1")
    	assert_equal(1, p.perft_number(0))
    	assert_equal(6, p.perft_number(1))
  	end
  	
 	def test_board_tofen
		b = Shuriken::BoardCaparandom.new("capablanca")
		s = "rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq - 0"
		b.use_fen(s)
		assert_equal(s, b.tofen)
		
		b = Shuriken::BoardCaparandom.new("capablanca")
		s = "rnabqkbcnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNABQKBCNR w KQkq d5 0"
		b.use_fen(s)
		assert_equal(s, b.tofen)
		
		b = Shuriken::BoardCaparandom.new("capablanca")
		s = "1n1bqkbcnr/rp1pp1p1pp/2pa1p1A2/10/3P6/2N2P1N2/PPP1P1PPPP/R2BQK1C1R b KQk - 0"
		b.use_fen(s)
		assert_equal(s, b.tofen)
		
		b = Shuriken::BoardCaparandom.new("gothic")
		s = "rnbqckabnr/pppppppppp/10/10/10/10/PPPPPPPPPP/RNBQCKABNR w KQkq - 0"
		b.use_fen(s)
		assert_equal(s, b.tofen)
		
		b = Shuriken::BoardCaparandom.new("cabarandom")
		s = "crabnqbknr/pppppppppp/10/10/10/10/PPPPPPPPPP/CRABNQBKNR w JBjb - 0"
		b.use_fen(s)
		assert_equal(s, b.tofen)
 	end
 	
 	def test_make_caparandom_pos
		b = Shuriken::BoardCaparandom.new("caparandom")
		s = Shuriken::Fen.make_caparandom_pos
		b.use_fen(s)
		assert(b.legal?)
	end
end
