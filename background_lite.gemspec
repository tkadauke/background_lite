Gem::Specification.new do |s| 
  s.platform  =   Gem::Platform::RUBY
  s.name      =   "background_lite"
  s.version   =   "0.4"
  s.date      =   Date.today.strftime('%Y-%m-%d')
  s.author    =   "Thomas Kadauke"
  s.email     =   "thomas.kadauke@googlemail.com"
  s.homepage  =   "https://github.com/tkadauke/background_lite"
  s.summary   =   "Run any method in the background"
  s.files     =   Dir.glob("lib/**/*") + Dir.glob("*.rb")

  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  
  s.bindir = 'bin'
  s.executables = Dir['bin/*'].collect { |file| File.basename(file) }
  
  s.require_path = "lib"
end
