##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

class Tokens
	def initialize(tokens)
		@tokens = tokens
		@token_i = 0
	end
	
	def peek(n)
		return nil if @token_i + n < 0 || @token_i + n >= @tokens.length
		@tokens[@token_i + n]
	end
	
	def ok?
		return @token_i < @tokens.length ? true : false
	end
	
	def go_next
		v = nil
		if @token_i < @tokens.length
			v = @tokens[@token_i]
			@token_i += 1 
		end
		return v
	end
	
	def forward
		@token_i += 1 
	end
	
	def cur
		@tokens[@token_i]
	end
end # class Tokens

end # module Shuriken
