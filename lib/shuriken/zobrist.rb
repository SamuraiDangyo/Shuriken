##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

module Zobrist
	HASH = []

	def Zobrist.init
		return if HASH.length > 0
		10_000.times do |i|
			HASH.push(rand(1024) | (rand(1024) << 10) \
					| (rand(1024) << 20) | (rand(1024) << 30) | (rand(1024) << 40))
		end
	end
	
	def Zobrist.get(n)
		HASH[n]
	end
end # module Zobrist

end # module Shuriken
