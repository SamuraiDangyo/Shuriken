require 'rake/testtask'

Rake::TestTask.new do | t |
	t.libs << 'test'
	t.test_files = FileList["test/shuriken_test.rb"]
  	t.verbose = true 
end

desc( "Run tests" )
task( :default => :test )