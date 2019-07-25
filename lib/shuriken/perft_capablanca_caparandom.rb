##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class PerftCapablancaCaparandom < Shuriken::PerftCaparandom
	NUMS = { # from sjeng
		0 => 1,
		1 => 28,
		2 => 784,
		3 => 25228,
		4 => 805128,
		5 => 28741319,
		6 => 1015802437
	}

	def initialize
		super("capablanca")
		@nums = NUMS
	end
end # class PerftCapablancaCaparandom

end # module Shuriken
