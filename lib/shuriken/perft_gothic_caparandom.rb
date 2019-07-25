##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class PerftGothicCaparandom < Shuriken::PerftCaparandom
	NUMS = { # from sjeng
		0 => 1,
		1 => 28,
		2 => 784,
		3 => 25283,
		4 => 808984,
		5 => 28946187,
		6 => 1025229212
	}

	def initialize
		super("gothic")
		@nums = NUMS
	end
end # class PerftGothicCaparandom

end # module Shuriken
