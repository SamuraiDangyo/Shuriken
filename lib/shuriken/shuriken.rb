##
#
# Shuriken, a Ruby chess variant engine
# Copyright (C) 2019 Toni Helminen ( kalleankka1@gmail.com )
#
# Shuriken is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Shuriken is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##

require_relative "./engine"
require_relative "./zobrist"
require_relative "./history"
require_relative "./cmd"
require_relative "./xboard"
require_relative "./utils"
require_relative "./bench"
require_relative "./board"
require_relative "./falcon_moves"
require_relative "./tokens"
require_relative "./fen"

require_relative "./board_caparandom"
require_relative "./eval_caparandom"
require_relative "./mgen_caparandom"
require_relative "./mgen_caparandom_white"
require_relative "./mgen_caparandom_black"
require_relative "./perft_caparandom"
require_relative "./perft_falcon_caparandom"
require_relative "./perft_gothic_caparandom"
require_relative "./perft_capablanca_caparandom"
require_relative "./engine_caparandom"
require_relative "./tactics_caparandom"

$stdout.sync = true
$stderr.sync = true
Thread.abort_on_exception = true
$stderr.reopen("shuriken-error.txt", "a+")

module Shuriken
	NAME = "Shuriken"
	VERSION = "0.32"
	AUTHOR = "Toni Helminen"

	def Shuriken.init
		Shuriken::EvalCaparandom.init
		Shuriken::Zobrist.init
		Shuriken::FalconMoves.init
	end
	
	# Start Shuriken
	#
	# Example:
	#   >> ruby shuriken.rb -xboard
	#   => xboard mode
	def Shuriken.go
		cmd = Shuriken::Cmd.new
		cmd.args
	end
end # module Shuriken

Shuriken.init # init just once

if __FILE__ == $0
	Shuriken.go
end
