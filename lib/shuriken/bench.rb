##
# Shuriken, a Ruby chess variant engine
# Author: Toni Helminen
# License: GPLv3
##

module Shuriken

require 'benchmark'

module Bench
	def Bench.f1
		n = 0
		1000_000.times { |i| n += (i%80) }
		n
	end
	
	def Bench.f2
		n = 0
		1000_000.times { |i| n += (i%80) }
		n
	end
	
	def Bench.f3
		n, i = 0, 0
		while i < 1000_000 
			n, i = n + (i%80), i + 1
		end
		n
	end
	
	def Bench.f4
		n = 0
		1000_000.times { |i| n += i%42 }
		n
	end
	
	def Bench.f5
		n = 0
		1000_000.times { |i| n += i.modulo 42 }
		n
	end
	
	def Bench.f6
		s, caps = ["abc", "def", "ghi", "jkl"], ""
		100_000.times { caps = s.map { |str| str.upcase } }
		caps
	end
	
	def Bench.f7
		s, caps = ["abc", "def", "ghi", "jkl"], ""
		100_000.times { caps = s.map(&:upcase) }
		caps
	end
	
	def Bench.f8
		s, s2 = "a", "abc"
		20_000.times { s += s2 }
	end
	
	def Bench.f9
		s, s2 = "a", "abc"
		20_000.times { s << s2 }
	end
	
	def Bench.f10
		s, s2 = "a", "abc"
		20_000.times { s = "#{s}#{s2}" }
	end
	
	def Bench.header(msg)
		puts "... #{msg} ..."
	end
	
	def Bench.loops
		header("loops")
		Benchmark.bm(10) do |x|
  			x.report("each") { f1 }
  			x.report("times") { f2 }
  			x.report("while") { f3 }
  			#x.compare!
  		end
	end
	
	def Bench.modulo
		header("modulo")
		Benchmark.bm(10) do |x|
  			x.report("%") { f4 }
  			x.report("modulo") { f5 }
  		end
	end
	
	def Bench.caps
		header("caps")
		Benchmark.bm(10) do |x|
  			x.report(".upcase") { f6 }
  			x.report("&:upcase") { f7 }
  		end
	end
	
	def Bench.strings
		header("strings")
		Benchmark.bm(10) do |x|
  			x.report("+=") { f8 }
  			x.report("<<") { f9 }
  			x.report("\#\{\}") { f10 }
  		end
	end
	
	def Bench.go
		loops
		modulo
		caps
		strings
	end
end # module Bench

end # module Shuriken
