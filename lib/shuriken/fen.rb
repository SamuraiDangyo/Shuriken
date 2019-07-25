##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

module Fen
	# RR NN BB Q C K A
	def Fen.make_caparandom_pos
		s = "." * 10
		put_piece = -> { i = rand(10); i = rand(10) while s[i] != "."; i }

		king = rand(1..8)
		l_rook = rand(king)
		r_rook = king + 1 + rand([1, 9 - (king + 1)].max)
		s[king] = "k"
		s[l_rook] = "r"
		s[r_rook] = "r"
		
		fail if r_rook == king || l_rook == king
		#puts "> #{king}> #{l_rook}> #{r_rook}"
		
		wb = put_piece.()
		s[wb] = "b"
		
		bb = rand(10)
		while s[bb] != "." || bb % 2 == wb % 2 
			bb = rand(10) 
		end
		s[bb] = "b"

		%|acnnq|.each_char { |p| s[put_piece.()] = p }

		pieces = s
		
		s += "/" + "p" * 10
		s << "/10" * 4
		s << "/" + "P" * 10
		s << "/" + pieces.upcase
		s << " w "
		s << ("A".ord + r_rook).chr
		s << ("A".ord + l_rook).chr
		s << ("a".ord + r_rook).chr
		s << ("a".ord + l_rook).chr
		s << " - 0"
		s
	end
end # module Fen

end # module Shuriken<
