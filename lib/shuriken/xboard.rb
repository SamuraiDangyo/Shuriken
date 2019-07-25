##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class Xboard
	def initialize(variant, random_mode = false)
		@variant = variant
		@random_mode = random_mode
		@engine = Shuriken::EngineCaparandom.new(variant, random_mode)
		@movestogo_orig = 40
		@forcemode = false
		Signal.trap("SIGPIPE", "SYSTEM_DEFAULT") 
		trap("INT", "IGNORE") # no interruptions
	end
	
	def print_xboard
		rv = @random_mode ? " random" : ""
		puts "feature myname=\"#{Shuriken::NAME} #{Shuriken::VERSION}#{rv}\""
		puts "feature variants=\"capablanca,gothic,caparandom,falcon\""
		puts "feature setboard=1"
		puts "feature ping=1"
		puts "feature done=1"
	end
	
	def play
		@engine.think 
	end
	
	def update_movestogo
		if @engine.movestogo == 1
			@engine.movestogo =	@movestogo_orig
		elsif @engine.movestogo > 0
			@engine.movestogo -= 1 
		end
	end
	
	def cmd_variant(variant)
		@variant = variant
		@engine = Shuriken::EngineCaparandom.new(@variant, @random_mode)
	end
	
	def cmd_new
		@engine.history_reset
		@engine = Shuriken::EngineCaparandom.new(@variant, @random_mode)
		@canmakemove = true
	end
	
	def cmd_level(level)
		@engine.movestogo = level.to_i
		@movestogo_orig = @engine.movestogo
	end
	
	def cmd_go
		if @canmakemove
			puts "move #{play}"
			@canmakemove = false
		end
	end
	
	def cmd_move(move)
		update_movestogo # update counter
		if @engine.make_move?(move)
			@canmakemove = true
			if @canmakemove && ! @engine.gameover
				puts "move #{play}"
				@canmakemove = false
			end
		end
	end
	
	def go
		puts "#{Shuriken::NAME} #{Shuriken::VERSION} by #{Shuriken::AUTHOR}"
		@movestogo_orig = 40
		@canmakemove = true
		$stdin.each do |cmd|
			cmd.strip!
			case cmd	
			when "xboard" then
			when "hard" then
			when "easy" then
			when "random" then
			when "nopost" then
			when "post" then
			when "white" then
			when "black" then
				# ignore
			when "remove" then
				@engine.history_remove
			when "undo" then
				@engine.history_undo
			when "?" then
				@engine.move_now = true
			when /^computer/ then
			when /^st/ then
			when /^otim/ then
			when /^accepted/ then
			when /^result/ then
				# ignore
			when /^protover/ then
				print_xboard
			when /^ping\s+(.*)/ then 
				puts "pong #{$1}"
			when /^variant\s+(.*)/ then
				cmd_variant($1)
			when "new" then
				cmd_new
			when "list" then
				@engine.move_list
			when /^level\s+(.+)\s+.*/ then
				cmd_level($1)
			when /^time\s+(.+)/ then 
				@engine.time = 0.01 * $1.to_i
			when /^setboard\s+(.+)/ then
				@engine.board.use_fen($1)
			when "quit" then
				return
			when "p" then
				@engine.board.print_board
			when "force" then
				@forcemode = true
			when "go" then
				cmd_go
			else # assume move
				cmd_move(cmd)
			end
		end
	end
end # class Xboard

end # module Shuriken
