##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

module FalconMoves
	MOVES = []
	
	def FalconMoves.init
		return if MOVES.length > 0
		[
			[[1,  0], [1,  1]],
			[[1,  0], [1,  -1]],
			[[-1, 0], [-1, 1]],
			[[-1, 0], [-1, -1]],
			[[0,  1], [1,  1]],
			[[0,  1], [-1, 1]],
			[[0, -1], [-1, -1]],
			[[0, -1], [1, -1]]
		].each do | o |
			s, d = o[0], o[1]
			# ssd,dss,sds,dsd,dds,sdd
			MOVES.push(s + s + d)
			MOVES.push(d + d + s)
			MOVES.push(d + s + s)
			MOVES.push(s + d + d)
			MOVES.push(s + d + s)
			MOVES.push(d + s + d)
		end
		MOVES.freeze
		if false
			MOVES.each { | q | puts ">> #{q}" }
		end
	end
end # module FalconMoves

end # module Shuriken
