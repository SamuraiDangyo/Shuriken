##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class PerftFalconCaparandom < Shuriken::PerftCaparandom
	NUMS = {
		0 => 1
	}

	def initialize
		super("falcon")
		@nums = NUMS
	end
end # class PerftFalconCaparandom

end # module Shuriken
