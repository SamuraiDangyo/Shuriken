##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

module Utils
	VARIANTS = ["capablanca", "caparandom", "gothic", "falcon"]
	
	def Utils.good_variant(variant)
		fail "Shuriken Error: Illegal Variant '#{variant}'" unless VARIANTS.include? variant
	end
	
	def Utils.error(msg)
		fail "Shuriken Error: #{msg}"
	end
	
	def Utils.log(x)
		File.open("shuriken-log.txt", 'a+') { |file| file.write "#{x}\n" }
	end
end # module Utils

end # module Shuriken
