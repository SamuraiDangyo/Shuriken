##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class Board
	def brd2str
		s, empty, counter = "", 0, 0
		80.times do |j|
			i = 10 * (7 - j / 10) + ( j % 10 )
			p = @brd[i]
			if p != 0
				if empty > 0
					s += empty.to_s 
					empty = 0
				end
				s += "fcakqrbnp.PNBRQKACF"[p + 9]
			else
				empty += 1
			end
			counter += 1
			if counter % 10 == 0
				s += empty.to_s if empty > 0
				s += "/" if counter < 80
				empty = 0
			end
		end
		s
	end
	
	def wtm2str
		@wtm ? "w" : "b"
	end
	
	def castle2str
		return "-" if @castle == 0
		s = ""
		if @variant == "cabarandom"
			a = "ABCDEFGHIJ"
			s += a[@castle_squares[1]] if @castle & 0x1 == 0x1
			s += a[@castle_squares[5]] if @castle & 0x2 == 0x2
			s += a[@castle_squares[1]].downcase if @castle & 0x4 == 0x4
			s += a[@castle_squares[5]].downcase if @castle & 0x8 == 0x8
		else
			s += @castle & 0x1 == 0x1 ? "K" : ""
			s += @castle & 0x2 == 0x2 ? "Q" : ""
			s += @castle & 0x4 == 0x4 ? "k" : ""
			s += @castle & 0x8 == 0x8 ? "q" : ""
		end
		s
	end
	
	def ep2str
		return "-" if @ep == -1
		"abcdefghijkl"[ @ep % 10 ] + (@ep / 10).to_s
	end
	
	def r502str
		@r50.to_s
	end
	
	def tofen
		"#{brd2str} #{wtm2str} #{castle2str} #{ep2str} #{r502str}"
	end
end # class Board

end # module Shuriken
