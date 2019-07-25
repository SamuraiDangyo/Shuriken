Gem::Specification.new do |s|
	s.name        = 'shurikenengine'
	s.version     = '0.31'
	s.executables << 'shuriken'
	s.date        = '2019-07-19'
	s.summary     = "a ruby chess variant engine"
	s.description = "Shuriken, a ruby chess variant engine"
	s.authors     = ["Toni Helminen"]
	s.email       = 'kalleankka1@gmail.com'
	s.files       = Dir['lib/*.rb'] + Dir['lib/shuriken/*.rb']# + Dir['lib/shurike*'] + Dir['src/**/*']
	s.homepage    = 'https://github.com/SamuraiDangyo/Shuriken'
	s.license     = 'GPL-3.0'
end
