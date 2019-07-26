Gem::Specification.new do |s|
	s.name        = 'shurikenengine'
	s.version     = '0.32'
	s.executables << 'shuriken'
	s.date        = '2019-07-26'
	s.summary     = "a Ruby chess variant engine"
	s.description = "Shuriken, a Ruby chess variant engine"
	s.authors     = ["Toni Helminen"]
	s.email       = 'kalleankka1@gmail.com'
	s.files       = Dir['lib/*.rb'] + Dir['lib/shuriken/*.rb']# + Dir['lib/shurike*'] + Dir['src/**/*']
	s.homepage    = 'https://github.com/SamuraiDangyo/Shuriken'
	s.license     = 'GPL-3.0'
end
